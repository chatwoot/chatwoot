# frozen_string_literal: true

module RubyLLM
  module Providers
    class OpenAI
      # Handles formatting of media content (images, audio) for OpenAI APIs
      module Media
        module_function

        def format_content(content)
          return content.to_json if content.is_a?(Hash) || content.is_a?(Array)
          return content unless content.is_a?(Content)

          parts = []
          parts << format_text(content.text) if content.text

          content.attachments.each do |attachment|
            case attachment.type
            when :image
              parts << format_image(attachment)
            when :pdf
              parts << format_pdf(attachment)
            when :audio
              parts << format_audio(attachment)
            when :text
              parts << format_text_file(attachment)
            else
              raise UnsupportedAttachmentError, attachment.type
            end
          end

          parts
        end

        def format_image(image)
          {
            type: 'image_url',
            image_url: {
              url: image.url? ? image.source : image.for_llm
            }
          }
        end

        def format_pdf(pdf)
          {
            type: 'file',
            file: {
              filename: pdf.filename,
              file_data: pdf.for_llm
            }
          }
        end

        def format_text_file(text_file)
          {
            type: 'text',
            text: text_file.for_llm
          }
        end

        def format_audio(audio)
          {
            type: 'input_audio',
            input_audio: {
              data: audio.encoded,
              format: audio.format
            }
          }
        end

        def format_text(text)
          {
            type: 'text',
            text: text
          }
        end
      end
    end
  end
end
