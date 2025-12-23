# frozen_string_literal: true
module Mail
  module Matchers
    def any_attachment
      AnyAttachmentMatcher.new
    end

    def an_attachment_with_filename(filename)
      AttachmentFilenameMatcher.new(filename)
    end

    def an_attachment_with_mime_type(filename)
      AttachmentMimeTypeMatcher.new(filename)
    end

    class AnyAttachmentMatcher
      def ===(other)
        other.attachment?
      end
    end

    class AttachmentFilenameMatcher
      attr_reader :filename
      def initialize(filename)
        @filename = filename
      end

      def ===(other)
        other.attachment? && other.filename == filename
      end
    end

    class AttachmentMimeTypeMatcher
      attr_reader :mime_type
      def initialize(mime_type)
        @mime_type = mime_type
      end

      def ===(other)
        other.attachment? && other.mime_type == mime_type
      end
    end
  end
end
