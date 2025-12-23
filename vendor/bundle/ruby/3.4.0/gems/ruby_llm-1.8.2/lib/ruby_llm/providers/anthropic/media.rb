# frozen_string_literal: true

module RubyLLM
  module Providers
    class Anthropic
      # Handles formatting of media content (images, PDFs, audio) for Anthropic
      module Media
        module_function

        def format_content(content)
          return [format_text(content.to_json)] if content.is_a?(Hash) || content.is_a?(Array)
          return [format_text(content)] unless content.is_a?(Content)

          parts = []
          parts << format_text(content.text) if content.text

          content.attachments.each do |attachment|
            case attachment.type
            when :image
              parts << format_image(attachment)
            when :pdf
              parts << format_pdf(attachment)
            when :text
              parts << format_text_file(attachment)
            else
              raise UnsupportedAttachmentError, attachment.mime_type
            end
          end

          parts
        end

        def format_text(text)
          {
            type: 'text',
            text: text
          }
        end

        def format_image(image)
          if image.url?
            {
              type: 'image',
              source: {
                type: 'url',
                url: image.source
              }
            }
          else
            {
              type: 'image',
              source: {
                type: 'base64',
                media_type: image.mime_type,
                data: image.encoded
              }
            }
          end
        end

        def format_pdf(pdf)
          if pdf.url?
            {
              type: 'document',
              source: {
                type: 'url',
                url: pdf.source
              }
            }
          else
            {
              type: 'document',
              source: {
                type: 'base64',
                media_type: pdf.mime_type,
                data: pdf.encoded
              }
            }
          end
        end

        def format_text_file(text_file)
          {
            type: 'text',
            text: text_file.for_llm
          }
        end
      end
    end
  end
end
