#!/usr/bin/env ruby

print "import or export: "
direction = gets.chomp

# sets the args for the cp command
source = "$HOME"
destination = "HOME"

if direction.match(/^e/)
  source, destination = destination, source
end

puts "reviewing files..."
`find HOME -type f`.split(/\s+/).each do |file|
  canonical_name = file.sub(/^HOME\//, "")
  puts "  checking: #{canonical_name}"

  diff = `diff $HOME/#{canonical_name} HOME/#{canonical_name}`
  if diff != ""
    puts "    updating"
    `cp #{source}/#{canonical_name} #{destination}/#{canonical_name}`
  end
end
