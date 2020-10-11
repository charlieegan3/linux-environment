#!/usr/bin/env ruby

require "json"

unless JSON.parse(`hcloud server list -o json`).nil?
  fail "unexpected instance running"
end
