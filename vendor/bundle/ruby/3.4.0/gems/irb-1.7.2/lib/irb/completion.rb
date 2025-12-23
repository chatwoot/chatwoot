# frozen_string_literal: false
#
#   irb/completion.rb -
#   	by Keiju ISHITSUKA(keiju@ishitsuka.com)
#       From Original Idea of shugo@ruby-lang.org
#

require_relative 'ruby-lex'

module IRB
  module InputCompletor # :nodoc:
    using Module.new {
      refine ::Binding do
        def eval_methods
          ::Kernel.instance_method(:methods).bind(eval("self")).call
        end

        def eval_private_methods
          ::Kernel.instance_method(:private_methods).bind(eval("self")).call
        end

        def eval_instance_variables
          ::Kernel.instance_method(:instance_variables).bind(eval("self")).call
        end

        def eval_global_variables
          ::Kernel.instance_method(:global_variables).bind(eval("self")).call
        end

        def eval_class_constants
          ::Module.instance_method(:constants).bind(eval("self.class")).call
        end
      end
    }

    # Set of reserved words used by Ruby, you should not use these for
    # constants or variables
    ReservedWords = %w[
      __ENCODING__ __LINE__ __FILE__
      BEGIN END
      alias and
      begin break
      case class
      def defined? do
      else elsif end ensure
      false for
      if in
      module
      next nil not
      or
      redo rescue retry return
      self super
      then true
      undef unless until
      when while
      yield
    ]

    BASIC_WORD_BREAK_CHARACTERS = " \t\n`><=;|&{("

    GEM_PATHS =
      if defined?(Gem::Specification)
        Gem::Specification.latest_specs(true).map { |s|
          s.require_paths.map { |p|
            if File.absolute_path?(p)
              p
            else
              File.join(s.full_gem_path, p)
            end
          }
        }.flatten
      else
        []
      end.freeze

    def self.retrieve_gem_and_system_load_path
      candidates = (GEM_PATHS | $LOAD_PATH)
      candidates.map do |p|
        if p.respond_to?(:to_path)
          p.to_path
        else
          String(p) rescue nil
        end
      end.compact.sort
    end

    def self.retrieve_files_to_require_from_load_path
      @@files_from_load_path ||=
        (
          shortest = []
          rest = retrieve_gem_and_system_load_path.each_with_object([]) { |path, result|
            begin
              names = Dir.glob("**/*.{rb,#{RbConfig::CONFIG['DLEXT']}}", base: path)
            rescue Errno::ENOENT
              nil
            end
            next if names.empty?
            names.map! { |n| n.sub(/\.(rb|#{RbConfig::CONFIG['DLEXT']})\z/, '') }.sort!
            shortest << names.shift
            result.concat(names)
          }
          shortest.sort! | rest
        )
    end

    def self.retrieve_files_to_require_relative_from_current_dir
      @@files_from_current_dir ||= Dir.glob("**/*.{rb,#{RbConfig::CONFIG['DLEXT']}}", base: '.').map { |path|
        path.sub(/\.(rb|#{RbConfig::CONFIG['DLEXT']})\z/, '')
      }
    end

    CompletionRequireProc = lambda { |target, preposing = nil, postposing = nil|
      if target =~ /\A(['"])([^'"]+)\Z/
        quote = $1
        actual_target = $2
      else
        return nil # It's not String literal
      end
      tokens = RubyLex.ripper_lex_without_warning(preposing.gsub(/\s*\z/, ''))
      tok = nil
      tokens.reverse_each do |t|
        unless [:on_lparen, :on_sp, :on_ignored_sp, :on_nl, :on_ignored_nl, :on_comment].include?(t.event)
          tok = t
          break
        end
      end
      result = []
      if tok && tok.event == :on_ident && tok.state == Ripper::EXPR_CMDARG
        case tok.tok
        when 'require'
          result = retrieve_files_to_require_from_load_path.select { |path|
            path.start_with?(actual_target)
          }.map { |path|
            quote + path
          }
        when 'require_relative'
          result = retrieve_files_to_require_relative_from_current_dir.select { |path|
            path.start_with?(actual_target)
          }.map { |path|
            quote + path
          }
        end
      end
      result
    }

    CompletionProc = lambda { |target, preposing = nil, postposing = nil|
      if preposing && postposing
        result = CompletionRequireProc.(target, preposing, postposing)
        unless result
          result = retrieve_completion_data(target).compact.map{ |i| i.encode(Encoding.default_external) }
        end
        result
      else
        retrieve_completion_data(target).compact.map{ |i| i.encode(Encoding.default_external) }
      end
    }

    def self.retrieve_completion_data(input, bind: IRB.conf[:MAIN_CONTEXT].workspace.binding, doc_namespace: false)
      case input
      # this regexp only matches the closing character because of irb's Reline.completer_quote_characters setting
      # details are described in: https://github.com/ruby/irb/pull/523
      when /^(.*["'`])\.([^.]*)$/
        # String
        receiver = $1
        message = $2

        if doc_namespace
          "String.#{message}"
        else
          candidates = String.instance_methods.collect{|m| m.to_s}
          select_message(receiver, message, candidates)
        end

      # this regexp only matches the closing character because of irb's Reline.completer_quote_characters setting
      # details are described in: https://github.com/ruby/irb/pull/523
      when /^(.*\/)\.([^.]*)$/
        # Regexp
        receiver = $1
        message = $2

        if doc_namespace
          "Regexp.#{message}"
        else
          candidates = Regexp.instance_methods.collect{|m| m.to_s}
          select_message(receiver, message, candidates)
        end

      when /^([^\]]*\])\.([^.]*)$/
        # Array
        receiver = $1
        message = $2

        if doc_namespace
          "Array.#{message}"
        else
          candidates = Array.instance_methods.collect{|m| m.to_s}
          select_message(receiver, message, candidates)
        end

      when /^([^\}]*\})\.([^.]*)$/
        # Proc or Hash
        receiver = $1
        message = $2

        if doc_namespace
          ["Proc.#{message}", "Hash.#{message}"]
        else
          proc_candidates = Proc.instance_methods.collect{|m| m.to_s}
          hash_candidates = Hash.instance_methods.collect{|m| m.to_s}
          select_message(receiver, message, proc_candidates | hash_candidates)
        end

      when /^(:[^:.]+)$/
        # Symbol
        if doc_namespace
          nil
        else
          sym = $1
          candidates = Symbol.all_symbols.collect do |s|
            s.inspect
          rescue EncodingError
            # ignore
          end
          candidates.grep(/^#{Regexp.quote(sym)}/)
        end
      when /^::([A-Z][^:\.\(\)]*)$/
        # Absolute Constant or class methods
        receiver = $1

        candidates = Object.constants.collect{|m| m.to_s}

        if doc_namespace
          candidates.find { |i| i == receiver }
        else
          candidates.grep(/^#{Regexp.quote(receiver)}/).collect{|e| "::" + e}
        end

      when /^([A-Z].*)::([^:.]*)$/
        # Constant or class methods
        receiver = $1
        message = $2

        if doc_namespace
          "#{receiver}::#{message}"
        else
          begin
            candidates = eval("#{receiver}.constants.collect{|m| m.to_s}", bind)
            candidates |= eval("#{receiver}.methods.collect{|m| m.to_s}", bind)
          rescue Exception
            candidates = []
          end

          select_message(receiver, message, candidates.sort, "::")
        end

      when /^(:[^:.]+)(\.|::)([^.]*)$/
        # Symbol
        receiver = $1
        sep = $2
        message = $3

        if doc_namespace
          "Symbol.#{message}"
        else
          candidates = Symbol.instance_methods.collect{|m| m.to_s}
          select_message(receiver, message, candidates, sep)
        end

      when /^(?<num>-?(?:0[dbo])?[0-9_]+(?:\.[0-9_]+)?(?:(?:[eE][+-]?[0-9]+)?i?|r)?)(?<sep>\.|::)(?<mes>[^.]*)$/
        # Numeric
        receiver = $~[:num]
        sep = $~[:sep]
        message = $~[:mes]

        begin
          instance = eval(receiver, bind)

          if doc_namespace
            "#{instance.class.name}.#{message}"
          else
            candidates = instance.methods.collect{|m| m.to_s}
            select_message(receiver, message, candidates, sep)
          end
        rescue Exception
          if doc_namespace
            nil
          else
            []
          end
        end

      when /^(-?0x[0-9a-fA-F_]+)(\.|::)([^.]*)$/
        # Numeric(0xFFFF)
        receiver = $1
        sep = $2
        message = $3

        begin
          instance = eval(receiver, bind)
          if doc_namespace
            "#{instance.class.name}.#{message}"
          else
            candidates = instance.methods.collect{|m| m.to_s}
            select_message(receiver, message, candidates, sep)
          end
        rescue Exception
          if doc_namespace
            nil
          else
            []
          end
        end

      when /^(\$[^.]*)$/
        # global var
        gvar = $1
        all_gvars = global_variables.collect{|m| m.to_s}

        if doc_namespace
          all_gvars.find{ |i| i == gvar }
        else
          all_gvars.grep(Regexp.new(Regexp.quote(gvar)))
        end

      when /^([^.:"].*)(\.|::)([^.]*)$/
        # variable.func or func.func
        receiver = $1
        sep = $2
        message = $3

        gv = bind.eval_global_variables.collect{|m| m.to_s}.push("true", "false", "nil")
        lv = bind.local_variables.collect{|m| m.to_s}
        iv = bind.eval_instance_variables.collect{|m| m.to_s}
        cv = bind.eval_class_constants.collect{|m| m.to_s}

        if (gv | lv | iv | cv).include?(receiver) or /^[A-Z]/ =~ receiver && /\./ !~ receiver
          # foo.func and foo is var. OR
          # foo::func and foo is var. OR
          # foo::Const and foo is var. OR
          # Foo::Bar.func
          begin
            candidates = []
            rec = eval(receiver, bind)
            if sep == "::" and rec.kind_of?(Module)
              candidates = rec.constants.collect{|m| m.to_s}
            end
            candidates |= rec.methods.collect{|m| m.to_s}
          rescue Exception
            candidates = []
          end
        else
          # func1.func2
          candidates = []
        end

        if doc_namespace
          rec_class = rec.is_a?(Module) ? rec : rec.class
          "#{rec_class.name}#{sep}#{candidates.find{ |i| i == message }}"
        else
          select_message(receiver, message, candidates, sep)
        end

      when /^\.([^.]*)$/
        # unknown(maybe String)

        receiver = ""
        message = $1

        candidates = String.instance_methods(true).collect{|m| m.to_s}

        if doc_namespace
          "String.#{candidates.find{ |i| i == message }}"
        else
          select_message(receiver, message, candidates.sort)
        end

      else
        if doc_namespace
          vars = (bind.local_variables | bind.eval_instance_variables).collect{|m| m.to_s}
          perfect_match_var = vars.find{|m| m.to_s == input}
          if perfect_match_var
            eval("#{perfect_match_var}.class.name", bind)
          else
            candidates = (bind.eval_methods | bind.eval_private_methods | bind.local_variables | bind.eval_instance_variables | bind.eval_class_constants).collect{|m| m.to_s}
            candidates |= ReservedWords
            candidates.find{ |i| i == input }
          end
        else
          candidates = (bind.eval_methods | bind.eval_private_methods | bind.local_variables | bind.eval_instance_variables | bind.eval_class_constants).collect{|m| m.to_s}
          candidates |= ReservedWords
          candidates.grep(/^#{Regexp.quote(input)}/).sort
        end
      end
    end

    PerfectMatchedProc = ->(matched, bind: IRB.conf[:MAIN_CONTEXT].workspace.binding) {
      begin
        require 'rdoc'
      rescue LoadError
        return
      end

      RDocRIDriver ||= RDoc::RI::Driver.new

      if matched =~ /\A(?:::)?RubyVM/ and not ENV['RUBY_YES_I_AM_NOT_A_NORMAL_USER']
        IRB.__send__(:easter_egg)
        return
      end

      namespace = retrieve_completion_data(matched, bind: bind, doc_namespace: true)
      return unless namespace

      if namespace.is_a?(Array)
        out = RDoc::Markup::Document.new
        namespace.each do |m|
          begin
            RDocRIDriver.add_method(out, m)
          rescue RDoc::RI::Driver::NotFoundError
          end
        end
        RDocRIDriver.display(out)
      else
        begin
          RDocRIDriver.display_names([namespace])
        rescue RDoc::RI::Driver::NotFoundError
        end
      end
    }

    # Set of available operators in Ruby
    Operators = %w[% & * ** + - / < << <= <=> == === =~ > >= >> [] []= ^ ! != !~]

    def self.select_message(receiver, message, candidates, sep = ".")
      candidates.grep(/^#{Regexp.quote(message)}/).collect do |e|
        case e
        when /^[a-zA-Z_]/
          receiver + sep + e
        when /^[0-9]/
        when *Operators
          #receiver + " " + e
        end
      end
    end
  end
end
