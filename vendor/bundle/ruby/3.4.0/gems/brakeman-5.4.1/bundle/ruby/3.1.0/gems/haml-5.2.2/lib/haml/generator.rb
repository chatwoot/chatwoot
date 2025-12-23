# frozen_string_literal: true

module Haml
  # Ruby code generator, which is a limited version of Temple::Generator.
  # Limit methods since Haml doesn't need most of them.
  class Generator
    include Temple::Mixins::CompiledDispatcher
    include Temple::Mixins::Options

    define_options freeze_static: RUBY_VERSION >= '2.1'

    def call(exp)
      compile(exp)
    end

    def on_multi(*exp)
      exp.map { |e| compile(e) }.join('; ')
    end

    def on_static(text)
      concat(options[:freeze_static] ? "#{Util.inspect_obj(text)}.freeze" : Util.inspect_obj(text))
    end

    def on_dynamic(code)
      concat(code)
    end

    def on_code(exp)
      exp
    end

    def on_newline
      "\n"
    end

    private

    def concat(str)
      "_hamlout.buffer << (#{str});"
    end
  end
end
