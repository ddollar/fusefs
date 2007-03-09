#!/usr/bin/env ruby

require 'drb'
require 'fusefs'

unless (1..2).include? ARGV.size
 puts "Usage: #$0 <directory> <uri>"
 exit(1)
end

dir = ARGV.shift
uri = ARGV.shift || 'druby://0.0.0.0:7777'

DRb.start_service(nil, nil)
root = DRbObject.new_with_uri(uri)

FuseFS.set_root(root)
FuseFS.mount_under(dir)
FuseFS.run
