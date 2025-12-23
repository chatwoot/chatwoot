# frozen_string_literal: true

require 'open3'

# Public: Builds on top of Ruby I/O open3 providing a friendlier experience.
module ViteRuby::IO
  class << self
    # Internal: A modified version of capture3 that can continuosly print stdout.
    # NOTE: Streaming output provides a better UX when running bin/vite build.
    def capture(*cmd, with_output: $stdout.method(:puts), stdin_data: '', **opts)
      return Open3.capture3(*cmd, **opts) unless with_output

      Open3.popen3(*cmd, **opts) { |stdin, stdout, stderr, wait_threads|
        stdin << stdin_data
        stdin.close
        out = Thread.new { read_lines(stdout, &with_output) }
        err = Thread.new { stderr.read }
        [out.value, err.value.to_s, wait_threads.value]
      }
    end

    # Internal: Reads and yield every line in the stream. Returns the full content.
    def read_lines(io)
      buffer = +''
      while line = io.gets
        buffer << line
        yield line
      end
      buffer
    end
  end
end
