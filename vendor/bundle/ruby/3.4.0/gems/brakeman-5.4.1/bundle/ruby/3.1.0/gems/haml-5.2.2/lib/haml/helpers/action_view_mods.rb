# frozen_string_literal: true

module Haml
  module Helpers
    module ActionViewMods
      def render(*args, &block)
        options = args.first

        # If render :layout is used with a block, it concats rather than returning
        # a string so we need it to keep thinking it's Haml until it hits the
        # sub-render.
        if is_haml? && !(options.is_a?(Hash) && options[:layout] && block_given?)
          return non_haml { super }
        end
        super
      end

      def output_buffer
        return haml_buffer.buffer if is_haml?
        super
      end

      def output_buffer=(new_buffer)
        if is_haml?
          if Haml::Util.rails_xss_safe? && new_buffer.is_a?(ActiveSupport::SafeBuffer)
            new_buffer = String.new(new_buffer)
          end
          haml_buffer.buffer = new_buffer
        else
          super
        end
      end
    end
    ActionView::Base.send(:prepend, ActionViewMods)
  end
end

module ActionView
  module Helpers
    module CaptureHelper
      def capture_with_haml(*args, &block)
        if Haml::Helpers.block_is_haml?(block)
          #double assignment is to avoid warnings
          _hamlout = _hamlout = eval('_hamlout', block.binding) # Necessary since capture_haml checks _hamlout

          capture_haml(*args, &block)
        else
          capture_without_haml(*args, &block)
        end
      end
      alias_method :capture_without_haml, :capture
      alias_method :capture, :capture_with_haml
    end

    module TagHelper
      DEFAULT_PRESERVE_OPTIONS = %w(textarea pre code).freeze

      def content_tag_with_haml(name, *args, &block)
        return content_tag_without_haml(name, *args, &block) unless is_haml?

        preserve = haml_buffer.options.fetch(:preserve, DEFAULT_PRESERVE_OPTIONS).include?(name.to_s)

        if block_given? && block_is_haml?(block) && preserve
          return content_tag_without_haml(name, *args) do
            haml_buffer.fix_textareas!(Haml::Helpers.preserve(&block)).html_safe
          end
        end

        content = content_tag_without_haml(name, *args, &block)
        if preserve && content
          content = haml_buffer.fix_textareas!(Haml::Helpers.preserve(content)).html_safe
        end
        content
      end

      alias_method :content_tag_without_haml, :content_tag
      alias_method :content_tag, :content_tag_with_haml
    end

    module HamlSupport
      include Haml::Helpers

      def haml_buffer
        @template_object.send :haml_buffer
      end

      def is_haml?
        @template_object.send :is_haml?
      end
    end

    module Tags
      class TextArea
        include HamlSupport
      end
    end

    class InstanceTag
      include HamlSupport

      def content_tag(*args, &block)
        html_tag = content_tag_with_haml(*args, &block)
        return html_tag unless respond_to?(:error_wrapping)
        return error_wrapping(html_tag) if method(:error_wrapping).arity == 1
        return html_tag unless object.respond_to?(:errors) && object.errors.respond_to?(:on)
        return error_wrapping(html_tag, object.errors.on(@method_name))
      end
    end

    module FormTagHelper
      def form_tag_with_haml(url_for_options = {}, options = {}, *parameters_for_url, &proc)
        if is_haml?
          wrap_block = block_given? && block_is_haml?(proc)
          if wrap_block
            oldproc = proc
            proc = haml_bind_proc do |*args|
              concat "\n"
              with_tabs(1) {oldproc.call(*args)}
            end
          end
          res = form_tag_without_haml(url_for_options, options, *parameters_for_url, &proc) << "\n"
          res << "\n" if wrap_block
          res
        else
          form_tag_without_haml(url_for_options, options, *parameters_for_url, &proc)
        end
      end
      alias_method :form_tag_without_haml, :form_tag
      alias_method :form_tag, :form_tag_with_haml
    end
  end
end
