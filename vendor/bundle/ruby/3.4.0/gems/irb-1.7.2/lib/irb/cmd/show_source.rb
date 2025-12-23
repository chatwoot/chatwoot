# frozen_string_literal: true

require_relative "nop"
require_relative "../color"
require_relative "../ruby-lex"

module IRB
  # :stopdoc:

  module ExtendCommand
    class ShowSource < Nop
      category "Context"
      description "Show the source code of a given method or constant."

      class << self
        def transform_args(args)
          # Return a string literal as is for backward compatibility
          if args.empty? || string_literal?(args)
            args
          else # Otherwise, consider the input as a String for convenience
            args.strip.dump
          end
        end

        def find_source(str, irb_context)
          case str
          when /\A[A-Z]\w*(::[A-Z]\w*)*\z/ # Const::Name
            eval(str, irb_context.workspace.binding) # trigger autoload
            base = irb_context.workspace.binding.receiver.yield_self { |r| r.is_a?(Module) ? r : Object }
            file, line = base.const_source_location(str)
          when /\A(?<owner>[A-Z]\w*(::[A-Z]\w*)*)#(?<method>[^ :.]+)\z/ # Class#method
            owner = eval(Regexp.last_match[:owner], irb_context.workspace.binding)
            method = Regexp.last_match[:method]
            if owner.respond_to?(:instance_method)
              methods = owner.instance_methods + owner.private_instance_methods
              file, line = owner.instance_method(method).source_location if methods.include?(method.to_sym)
            end
          when /\A((?<receiver>.+)(\.|::))?(?<method>[^ :.]+)\z/ # method, receiver.method, receiver::method
            receiver = eval(Regexp.last_match[:receiver] || 'self', irb_context.workspace.binding)
            method = Regexp.last_match[:method]
            file, line = receiver.method(method).source_location if receiver.respond_to?(method, true)
          end
          if file && line
            Source.new(file: file, first_line: line, last_line: find_end(file, line, irb_context))
          end
        end

        private

        def find_end(file, first_line, irb_context)
          return first_line unless File.exist?(file)
          lex = RubyLex.new(irb_context)
          lines = File.read(file).lines[(first_line - 1)..-1]
          tokens = RubyLex.ripper_lex_without_warning(lines.join)
          prev_tokens = []

          # chunk with line number
          tokens.chunk { |tok| tok.pos[0] }.each do |lnum, chunk|
            code = lines[0..lnum].join
            prev_tokens.concat chunk
            continue = lex.should_continue?(prev_tokens)
            syntax = lex.check_code_syntax(code)
            if !continue && syntax == :valid
              return first_line + lnum
            end
          end
          first_line
        end
      end

      def execute(str = nil)
        unless str.is_a?(String)
          puts "Error: Expected a string but got #{str.inspect}"
          return
        end

        source = self.class.find_source(str, @irb_context)
        if source && File.exist?(source.file)
          show_source(source)
        else
          puts "Error: Couldn't locate a definition for #{str}"
        end
        nil
      end

      private

      # @param [IRB::ExtendCommand::ShowSource::Source] source
      def show_source(source)
        puts
        puts "#{bold("From")}: #{source.file}:#{source.first_line}"
        puts
        code = IRB::Color.colorize_code(File.read(source.file))
        puts code.lines[(source.first_line - 1)...source.last_line].join
        puts
      end

      def bold(str)
        Color.colorize(str, [:BOLD])
      end

      Source = Struct.new(
        :file,       # @param [String] - file name
        :first_line, # @param [String] - first line
        :last_line,  # @param [String] - last line
        keyword_init: true,
      )
      private_constant :Source
    end
  end

  # :startdoc:
end
