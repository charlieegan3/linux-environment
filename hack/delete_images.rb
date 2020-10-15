#!/usr/bin/env ruby

require "json"

images = JSON.parse(`hcloud image list -t snapshot -o json`).
  shuffle.
  sort_by { |i| i["created"] }.
  select { |i| i["description"].start_with? "le-" }.
  reverse

if images.size == 0
  fail "no images"
elsif images.size == 1
  puts "keeping single image"
  puts images.map { |i| i["description"] }
else
  keep = images[0]
  delete = images[1..-1]

  puts "Delete?"
  puts delete.map { |i| i["description"] }

  print "> "
  if gets.chomp == "y"
    delete.each do |i|
      system("hcloud image delete #{i["id"]}")
    end
  end
end
