#!/usr/bin/env ruby

if ARGV[0] != "import" && ARGV[0] != "export"
  fail "need import or export arg"
end

puts "#{ARGV[0]}ing files..."

# sets the args for the cp command
source = "$HOME"
destination = "HOME"

# swap the args if it's export
if ARGV[0] == "export"
  source, destination = destination, source
end

`find HOME -type f`.split(/\s+/).each do |file|
  canonical_name = file.sub(/^HOME\//, "")
  puts "  checking: #{canonical_name}"

  if File.exists? "#{destination}/#{canonical_name}"
    diff = `diff #{source}/#{canonical_name} #{destination}/#{canonical_name}`
    if diff != ""
      puts "    updating"
      `cp #{source}/#{canonical_name} #{destination}/#{canonical_name}`
    end
  else
      `cp #{source}/#{canonical_name} #{destination}/#{canonical_name}`
  end
end
