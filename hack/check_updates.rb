#!/usr/bin/env ruby

require "yaml"

packages = YAML.load(File.read("tasks/packages.yaml"))[0]
  .dig("dnf", "name")
  .map { |p|
    components = p.split("-")
    [components[0..-2].join("-"), components[-1]]
  }

`dnf check-update`.split("\n").map(&:chomp).each do |package|
  packages.each do |p, v|
    if package.split(".").first == p
      new = package.split(/\s+/)[1].split("-").first.split(":").last

      puts "    - #{p}-#{new}"
    end
  end
end

