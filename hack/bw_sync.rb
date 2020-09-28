#!/usr/bin/env ruby

# the name of the item in bw where the data is stored
BW_ITEM = "linux-environment-secrets"
BW_FOLDER = "config"
SECRET_MANIFEST_FILE = "secret_manifest.yaml"
SECRET_MANIFEST_FILE_REMOTE = "secret_manifest.remote.yaml"

require "open3"
require "yaml"
require "json"
require "pry"
require "base64"
require "pathname"

def run_cmd(*cmd)
  stdout, stderr, status = Open3.capture3(*cmd)
  status.success? && stdout rescue nil
end

def prompt(*args)
  print(*args)
  gets.chomp
end


# check that the bw cli is installed on the machine
unless run_cmd("hash", "bw")
  fail "bw cli is not installed"
end

# get the locked status from the cli
status_output = run_cmd(*%w(bw status))
unless status_output
  fail "failed to get status"
end
status = JSON.parse(status_output.split("\n").last)["status"]

# get the session, test if env var session if logged in, if yes, use that in
# calls, if not, then get a new session manually
session = ENV["BW_SESSION"]
if status != "unlocked"
  output = `bw unlock`
  session = output.scan(/\-\-session (.*)/).flatten.last
end


# find folder id, if missing, create it
all_folders = JSON.parse(run_cmd(*%w(bw list folders)))
folder = all_folders.find { |i| i["name"] == BW_FOLDER }
if folder.nil?
  folder_data = { name: BW_FOLDER }
  encoded_data = Base64.encode64(JSON.pretty_generate(folder_data)).split("\n").join
  folder = JSON.parse(run_cmd(*%w(bw create folder), encoded_data))
end
folder_id = folder["id"]

# find the item id
all_items = JSON.parse(run_cmd(*%w(bw list items --folderid), folder_id))
item = all_items.find { |i| i["name"] == BW_ITEM }
# create a new item if missing
if item.nil?
  item_data = {
    "object": "item",
    "folderId": folder_id,
    "type": 2, # secure note
    "name": BW_ITEM,
    "notes": "",
    "secureNote": { "type": 0 }
  }
  encoded_data = Base64.encode64(JSON.pretty_generate(item_data)).split("\n").join
  item = JSON.parse(run_cmd(*%w(bw create item), encoded_data))
end
item_id = item["id"]

# make sure a local secret_manifest file exists
unless File.exists? SECRET_MANIFEST_FILE
  fail "SECRET_MANIFEST_FILE missing, could not create" unless run_cmd("touch", SECRET_MANIFEST_FILE)
end

# skip down sync if there are no remote attachments
unless (item["attachments"] || []).empty?
  # filenames have dates and are sortable
  most_recent = item["attachments"].sort_by { |e| e["fileName"].to_s }.last
  if most_recent.nil?
    fail "missing recent attachment to download"
  end

  # get the contents of the most recent secrets manifest
  unless run_cmd("bw", "get", "attachment", most_recent["id"], "--itemid", item_id, "--output", SECRET_MANIFEST_FILE_REMOTE)
    fail "could not get attachment"
  end

  # prompt that the new downloaded secret manifest is different and offer update
  if File.read(SECRET_MANIFEST_FILE) != File.read(SECRET_MANIFEST_FILE_REMOTE)
    puts "#{SECRET_MANIFEST_FILE} does not match contents in #{SECRET_MANIFEST_FILE_REMOTE}"
    puts "Enter 'o' to overwrite from #{SECRET_MANIFEST_FILE_REMOTE}, 'Enter' to continue"
    loop do
      response = prompt("o/Enter: ")
      if response == "o"
        File.write(SECRET_MANIFEST_FILE, File.read(SECRET_MANIFEST_FILE_REMOTE))
        break
      elsif response == ""
        break
      else # must enter o or empty string
        puts "invalid response"
      end
    end
  end

  # remove all but the five most recent attachments
  if item["attachments"].size > 5
    # filenames have dates and are sortable
    to_remove = item["attachments"].sort_by { |e| e["fileName"].to_s }[0..-6]

    puts "The following attachments are old"
    puts to_remove.map { |a| a["fileName"] }.join(", ")
    puts "Enter 'd' to delete, 'Enter' to continue"
    loop do
      response = prompt("d/Enter: ")
      if response == "d"
        to_remove.each do |attachment|
          unless run_cmd("bw", "delete", "attachment", attachment["id"], "--itemid", item_id)
            fail "could not delete attachment"
          end
        end
        break
      elsif response == ""
        break
      else # must enter o or empty string
        puts "invalid response"
      end
    end
  end
end

# load the secrets from the manifest
secrets = YAML.load(File.read(SECRET_MANIFEST_FILE))

# make sure it's an array to loop over
unless secrets.is_a? Array
  secrets = []
end

# make sure that the manifest matches the state on the system
secrets.each do |s|
  full_path = File.expand_path(s["path"])

  # if the file does not exist, and the content is set, create a new file
  if !File.exists?(full_path) && s["content"].to_s.length > 0
    # make sure that the folder for the file exists
    dir_path = full_path.split("/")[0..-2].join("/")
    dir_exists = File.directory?(dir_path)

    if !dir_exists
      # only create dirs for secrets that have it set, default to not creating
      # for missing dirs
      if s["create_dir"]
        Dir.mkdir dir_path
      else
        # skip when the create_dir attr is not set, the default behaviour
        next
      end
    end

    File.write(full_path, s["content"])
  end

  # if the has different content, offer option to overwrite
  if File.exists?(full_path) && File.read(full_path) != s["content"]
    puts "#{s["path"]} does not match contents in #{SECRET_MANIFEST_FILE}"
    puts "--- #{SECRET_MANIFEST_FILE} ---\n#{s["content"]}\n---"
    puts "--- #{full_path} ---\n#{File.read(full_path)}\n---"
    puts "Enter 'o' to overwrite from #{SECRET_MANIFEST_FILE}, 'Enter' to continue"
    loop do
      response = prompt("o/Enter: ")
      if response == "o"
        File.write(full_path, s["content"])
        break
      elsif response == ""
        break
      else # must enter o or empty string
        puts "invalid response"
      end
    end
  end
end


# load any differences in the local config files into the secrets list
secrets.each do |s|
  full_path = File.expand_path(s["path"])

  # if the has different content, offer option to overwrite
  if File.exists?(full_path) && File.read(full_path) != s["content"]
    puts "#{s["path"]} does not match contents in #{SECRET_MANIFEST_FILE}"
    puts "--- #{SECRET_MANIFEST_FILE} ---\n#{s["content"]}\n---"
    puts "--- #{full_path} ---\n#{File.read(full_path)}\n---"
    puts "Enter 'o' to overwrite from #{full_path}, 'Enter' to continue"
    loop do
      response = prompt("o/Enter: ")
      if response == "o"
        s["content"] = File.read(full_path)
        break
      elsif response == ""
        break
      else # must enter o or empty string
        puts "invalid response"
      end
    end
  end
end

# write the reloaded secret data to the secrets file
# use yq to get nicer yaml formatting
encoded_data = Base64.encode64(JSON.pretty_generate(secrets)).split("\n").join
unless run_cmd("echo #{encoded_data} | base64 -d | yq r --prettyPrint - > #{SECRET_MANIFEST_FILE}")
  fail "can't generate new local #{SECRET_MANIFEST_FILE}"
end

# only upload if the files are different
if File.read(SECRET_MANIFEST_FILE) != File.read(SECRET_MANIFEST_FILE_REMOTE)
  # upload the new config as a new attachment
  version_filename = Time.new.strftime("#{SECRET_MANIFEST_FILE.sub(".yaml", "")}.%Y-%m-%d_%H-%M-%S.yaml")
  fail "cant create versioned data" unless run_cmd("cp", SECRET_MANIFEST_FILE, version_filename)
  unless run_cmd("bw", "create", "attachment", "--file", version_filename, "--itemid", item_id)
    fail "could not create new attachment"
  end
  fail "cant delete versioned data" unless run_cmd("rm", version_filename)
end
