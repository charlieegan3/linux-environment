#!/usr/bin/env ruby

puts "reviewing files..."
`find HOME -type f`.split(/\s+/).each do |file|
  canonical_name = file.sub(/^HOME\//, "")
  puts "  checking: #{canonical_name}"

  diff = `diff $HOME/#{canonical_name} HOME/#{canonical_name}`
  if diff != ""
    puts "    updating"
    `cp $HOME/#{canonical_name} HOME/#{canonical_name}`
  end
end

# TODO: find a means of syncing new files in vim config
