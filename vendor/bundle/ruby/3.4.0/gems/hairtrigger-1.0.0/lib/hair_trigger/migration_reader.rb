require 'ruby_parser'
require 'ruby2ruby'

module HairTrigger
  module MigrationReader
    class << self
      def get_triggers(source, options)
        triggers = []
        if source.is_a?(String)
          # schema.rb contents... because it's auto-generated and we know
          # exactly what it will look like, we can safely use a regex
          source.scan(/^  create_trigger\(.*?\n  end\n\n/m).each do |match|
            trigger = instance_eval("generate_" + match.strip)
            triggers << trigger if options[:include_manual_triggers] || trigger.options[:generated]
          end
        else
          contents = File.read(source.filename)
          return [] unless contents =~ /(create|drop)_trigger/
          sexps = RubyParser.for_current_ruby.parse(contents)
          # find the migration class
          sexps = [sexps] unless sexps[0] == :block
          sexps = sexps.detect{ |s| s.is_a?(Sexp) && s[0] == :class && s[1] == source.name.to_sym }
          # find the block of the up method
          sexps = sexps.last if sexps.last.is_a?(Sexp) && sexps.last[0] == :block
          sexps = sexps.detect{ |s| s.is_a?(Sexp) && (s[0] == :defs && s[1] && s[1][0] == :self && s[2] == :up || s[0] == :defn && s[1] == :up) }
          return [] unless sexps # no `up` method... unsupported `change` perhaps?
          sexps.each do |sexp|
            next unless (method = extract_method_call(sexp)) && [:create_trigger, :drop_trigger].include?(method)
            trigger = instance_eval("generate_" + generator.process(sexp))
            triggers << trigger if options[:include_manual_triggers] || trigger.options[:generated]
          end
        end
        triggers
      rescue
        $stderr.puts "Error reading triggers in #{source.filename rescue "schema.rb"}: #{$!}"
        []
      end

      private
      def extract_method_call(exp)
        return nil unless exp.is_a?(Array)
        if exp[0] == :iter
          exp = exp[1] while exp[1].is_a?(Array) && exp[1][0] == :call
        end
        if exp[0] == :call
          exp[2]
        end
      end

      def generate_create_trigger(*arguments)
        arguments.unshift({}) if arguments.empty?
        arguments.unshift(nil) if arguments.first.is_a?(Hash)
        arguments.push({}) if arguments.size == 1
        arguments[1][:compatibility] ||= HairTrigger::Builder.base_compatibility
        ::HairTrigger::Builder.new(*arguments)
      end

      def generate_drop_trigger(*arguments)
        options = arguments[2] || {}
        ::HairTrigger::Builder.new(arguments[0], options.update({:table => arguments[1], :drop => true}))
      end

      def generator
        @generator ||= Ruby2Ruby.new
      end
    end
  end
end
