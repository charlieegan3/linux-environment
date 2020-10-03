#!/usr/bin/env ruby

require "json"

def list(path)
  files = JSON.parse(`rclone lsjson "dropbox:#{path}"`)
  [].tap do |entries|
    files.each do |file|
      entries << file["Path"]
    end
  end
end

def copy(path)
  output = "."
  unless path.split("/").last.include?(".")
    output = path.split("/").last.gsub(/\s+/, "_").downcase
    system("mkdir '#{output}'")
  end
  system("rclone copy -P 'dropbox:#{path}' '#{output}'")
end

def print_entries(entries)
  entries.each_with_index do |e, i|
    puts "#{i.to_s.rjust(3)} #{e}"
  end
end

current_path = ARGV[0] || "/"
ARGV.clear

loop do
  puts "Current: #{current_path}"

  entries = list(current_path)
  print_entries(entries)

  print "> "
  command = gets.chomp.strip

  if command.match(/^\d/)
    index = Integer(command)
    unless current_path.end_with? "/"
      current_path += "/"
    end
    current_path += entries[index]
  elsif command == ".."
    current_path = current_path.split("/")[0..-2].join("/")
  elsif command == ""
    copy(current_path)
    puts "#{current_path} saved"
  elsif command == "exit"
    exit
  else
    puts "wot?"
  end
end
