#!/usr/bin/ruby

require "vips"

# load and stream into memory
image = Vips::Image.new_from_file(ARGV[0], access: :sequential).copy_memory

starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)

lines = image
(0..1).step 0.01 do |i|
  lines = lines.draw_line 255, lines.width * i, 0, 0, lines.height * (1 - i)
end

ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
puts "non-destructive took #{ending - starting}s"

starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)

lines = image
lines = lines.mutate do |x|
  (0..1).step 0.01 do |i|
    x.draw_line! 255, x.width * i, 0, 0, x.height * (1 - i)
  end
end

ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
puts "mutate took #{ending - starting}s"

lines.write_to_file ARGV[1]
