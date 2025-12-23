# frozen_string_literal: true

require "digest/sha1"

module TestProf
  module AnyFixture
    class Dump
      module Digest
        module_function

        def call(*paths)
          files = (AnyFixture.config.default_dump_watch_paths + paths).each_with_object([]) do |path_or_glob, acc|
            if File.file?(path_or_glob)
              acc << path_or_glob
            else
              acc = acc.concat Dir[path_or_glob]
            end
            acc
          end

          return if files.empty?

          file_ids = files.sort.map { |f| "#{File.basename(f)}/#{::Digest::SHA1.file(f).hexdigest}" }
          ::Digest::SHA1.hexdigest(file_ids.join("/"))
        end
      end
    end
  end
end
