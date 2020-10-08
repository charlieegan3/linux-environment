#!/usr/bin/env ruby

require "json"
require "socket"

ip = Socket.ip_address_list.
  reject(&:ipv6?).
  reject(&:ipv4_loopback?).
  reject(&:ipv4_private?).
  map {|e|e.ip_address}.
  first

puts "Current IP: #{ip}"

JSON.parse(`hcloud server list -o json`).each do |s|
  if s["public_net"]["ipv4"]["ip"] == ip
    puts "Matched instance: #{s["name"]}"
    system("hcloud server delete #{s["id"]}")
  end
end

puts "bye bye"
