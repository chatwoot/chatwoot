# frozen_string_literal: true

require 'temple'
require 'haml/escapable'
require 'haml/generator'

module Haml
  class TempleEngine < Temple::Engine
    define_options(
      attr_wrapper:         "'",
      autoclose:            %w(area base basefont br col command embed frame
                               hr img input isindex keygen link menuitem meta
                               param source track wbr),
      encoding:             nil,
      escape_attrs:         true,
      escape_html:          false,
      escape_filter_interpolations: nil,
      filename:             '(haml)',
      format:               :html5,
      hyphenate_data_attrs: true,
      line:                 1,
      mime_type:            'text/html',
      preserve:             %w(textarea pre code),
      remove_whitespace:    false,
      suppress_eval:        false,
      cdata:                false,
      parser_class:         ::Haml::Parser,
      compiler_class:       ::Haml::Compiler,
      trace:                false,
      filters:              {},
    )

    use :Parser,   -> { options[:parser_class] }
    use :Compiler, -> { options[:compiler_class] }
    use Escapable
    filter :ControlFlow
    filter :MultiFlattener
    filter :StaticMerger
    use Generator

    def compile(template)
      initialize_encoding(template, options[:encoding])
      @precompiled = call(template)
    end

    # The source code that is evaluated to produce the Haml document.
    #
    # This is automatically converted to the correct encoding
    # (see {file:REFERENCE.md#encodings the `:encoding` option}).
    #
    # @return [String]
    def precompiled
      encoding = Encoding.find(@encoding || '')
      return @precompiled.dup.force_encoding(encoding) if encoding == Encoding::ASCII_8BIT
      return @precompiled.encode(encoding)
    end

    def precompiled_with_return_value
      "#{precompiled};#{precompiled_method_return_value}".dup
    end

    # The source code that is evaluated to produce the Haml document.
    #
    # This is automatically converted to the correct encoding
    # (see {file:REFERENCE.md#encodings the `:encoding` option}).
    #
    # @return [String]
    def precompiled_with_ambles(local_names, after_preamble: '', before_postamble: '')
      preamble = <<END.tr("\n", ';')
begin
extend Haml::Helpers
_hamlout = @haml_buffer = Haml::Buffer.new(haml_buffer, #{Options.new(options).for_buffer.inspect})
_erbout = _hamlout.buffer
#{after_preamble}
END
      postamble = <<END.tr("\n", ';')
#{before_postamble}
#{precompiled_method_return_value}
ensure
@haml_buffer = @haml_buffer.upper if @haml_buffer
end
END
      "#{preamble}#{locals_code(local_names)}#{precompiled}#{postamble}".dup
    end

    private

    def initialize_encoding(template, given_value)
      if given_value
        @encoding = given_value
      else
        @encoding = Encoding.default_internal || template.encoding
      end
    end

    # Returns the string used as the return value of the precompiled method.
    # This method exists so it can be monkeypatched to return modified values.
    def precompiled_method_return_value
      "_erbout"
    end

    def locals_code(names)
      names = names.keys if Hash === names

      names.map do |name|
        # Can't use || because someone might explicitly pass in false with a symbol
        sym_local = "_haml_locals[#{inspect_obj(name.to_sym)}]"
        str_local = "_haml_locals[#{inspect_obj(name.to_s)}]"
        "#{name} = #{sym_local}.nil? ? #{str_local} : #{sym_local};"
      end.join
    end

    def inspect_obj(obj)
      case obj
      when String
        %Q!"#{obj.gsub(/[\x00-\x7F]+/) {|s| s.inspect[1...-1]}}"!
      when Symbol
        ":#{inspect_obj(obj.to_s)}"
      else
        obj.inspect
      end
    end
  end
end
