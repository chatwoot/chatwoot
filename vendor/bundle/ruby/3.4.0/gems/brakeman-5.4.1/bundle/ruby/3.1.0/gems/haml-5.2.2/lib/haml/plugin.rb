# frozen_string_literal: true

module Haml

  # This module makes Haml work with Rails using the template handler API.
  class Plugin
    class << self
      attr_accessor :annotate_rendered_view_with_filenames
    end
    self.annotate_rendered_view_with_filenames = false

    def handles_encoding?; true; end

    def compile(template, source)
      options = Haml::Template.options.dup
      if template.respond_to?(:type)
        options[:mime_type] = template.type
      elsif template.respond_to? :mime_type
        options[:mime_type] = template.mime_type
      end
      options[:filename] = template.identifier

      preamble = '@output_buffer = output_buffer ||= ActionView::OutputBuffer.new if defined?(ActionView::OutputBuffer);'
      postamble = ''

      if self.class.annotate_rendered_view_with_filenames
        # short_identifier is only available in Rails 6+. On older versions, 'inspect' gives similar results.
        ident = template.respond_to?(:short_identifier) ? template.short_identifier : template.inspect
        preamble += "haml_concat '<!-- BEGIN #{ident} -->'.html_safe;"
        postamble += "haml_concat '<!-- END #{ident} -->'.html_safe;"
      end

      Haml::Engine.new(source, options).compiler.precompiled_with_ambles(
        [],
        after_preamble: preamble,
        before_postamble: postamble
      )
    end

    def self.call(template, source = nil)
      source ||= template.source

      new.compile(template, source)
    end

    def cache_fragment(block, name = {}, options = nil)
      @view.fragment_for(block, name, options) do
        eval("_hamlout.buffer", block.binding)
      end
    end
  end
end

ActionView::Template.register_template_handler(:haml, Haml::Plugin)
