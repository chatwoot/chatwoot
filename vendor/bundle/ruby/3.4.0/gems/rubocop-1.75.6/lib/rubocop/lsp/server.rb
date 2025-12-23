# frozen_string_literal: true

require 'language_server-protocol'
require_relative 'logger'
require_relative 'routes'
require_relative 'runtime'

#
# This code is based on https://github.com/standardrb/standard.
#
# Copyright (c) 2023 Test Double, Inc.
#
# The MIT License (MIT)
#
# https://github.com/standardrb/standard/blob/main/LICENSE.txt
#
module RuboCop
  module LSP
    # Language Server Protocol of RuboCop.
    # @api private
    class Server
      def initialize(config_store)
        $PROGRAM_NAME = "rubocop --lsp #{ConfigFinder.project_root}"

        @reader = LanguageServer::Protocol::Transport::Io::Reader.new($stdin)
        @writer = LanguageServer::Protocol::Transport::Io::Writer.new($stdout)
        @runtime = RuboCop::LSP::Runtime.new(config_store)
        @routes = Routes.new(self)
      end

      def start
        @reader.read do |request|
          if !request.key?(:method)
            @routes.handle_method_missing(request)
          elsif (route = @routes.for(request[:method]))
            route.call(request)
          else
            @routes.handle_unsupported_method(request)
          end
        rescue StandardError => e
          Logger.log("Error #{e.class} #{e.message[0..100]}")
          Logger.log(e.backtrace.inspect)
        end
      end

      def write(response)
        @writer.write(response)
      end

      def format(path, text, command:)
        @runtime.format(path, text, command: command)
      end

      def offenses(path, text)
        @runtime.offenses(path, text)
      end

      def configure(options)
        @runtime.safe_autocorrect = options[:safe_autocorrect]
        @runtime.lint_mode = options[:lint_mode]
        @runtime.layout_mode = options[:layout_mode]
      end

      def stop(&block)
        at_exit(&block) if block
        exit
      end
    end
  end
end
