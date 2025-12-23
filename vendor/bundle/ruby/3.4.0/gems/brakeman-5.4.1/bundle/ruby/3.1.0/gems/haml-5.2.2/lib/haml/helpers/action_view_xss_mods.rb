# frozen_string_literal: true

module ActionView
  module Helpers
    module CaptureHelper
      def with_output_buffer_with_haml_xss(*args, &block)
        res = with_output_buffer_without_haml_xss(*args, &block)
        case res
        when Array; res.map {|s| Haml::Util.html_safe(s)}
        when String; Haml::Util.html_safe(res)
        else; res
        end
      end
      alias_method :with_output_buffer_without_haml_xss, :with_output_buffer
      alias_method :with_output_buffer, :with_output_buffer_with_haml_xss
    end

    module FormTagHelper
      def form_tag_with_haml_xss(*args, &block)
        res = form_tag_without_haml_xss(*args, &block)
        res = Haml::Util.html_safe(res) unless block_given?
        res
      end
      alias_method :form_tag_without_haml_xss, :form_tag
      alias_method :form_tag, :form_tag_with_haml_xss
    end

    module FormHelper
      def form_for_with_haml_xss(*args, &block)
        res = form_for_without_haml_xss(*args, &block)
        return Haml::Util.html_safe(res) if res.is_a?(String)
        return res
      end
      alias_method :form_for_without_haml_xss, :form_for
      alias_method :form_for, :form_for_with_haml_xss
    end

    module TextHelper
      def concat_with_haml_xss(string)
        if is_haml?
          haml_buffer.buffer.concat(haml_xss_html_escape(string))
        else
          concat_without_haml_xss(string)
        end
      end
      alias_method :concat_without_haml_xss, :concat
      alias_method :concat, :concat_with_haml_xss

      def safe_concat_with_haml_xss(string)
        if is_haml?
          haml_buffer.buffer.concat(string)
        else
          safe_concat_without_haml_xss(string)
        end
      end
      alias_method :safe_concat_without_haml_xss, :safe_concat
      alias_method :safe_concat, :safe_concat_with_haml_xss
    end
  end
end
