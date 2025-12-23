#!/usr/bin/ruby

require "vips"

image = Vips::Image.black 1, 100000
image.set_progress true

def progress_to_s(name, progress)
  puts "#{name}:"
  puts "    progress.run = #{progress[:run]}"
  puts "    progress.eta = #{progress[:eta]}"
  puts "    progress.tpels = #{progress[:tpels]}"
  puts "    progress.npels = #{progress[:npels]}"
  puts "    progress.percent = #{progress[:percent]}"
end

image.signal_connect :preeval do |progress|
  progress_to_s("preeval", progress)
end

image.signal_connect :eval do |progress|
  progress_to_s("eval", progress)
  image.set_kill(true) if progress[:percent] > 50
end

image.signal_connect :posteval do |progress|
  progress_to_s("posteval", progress)
end

image.avg
