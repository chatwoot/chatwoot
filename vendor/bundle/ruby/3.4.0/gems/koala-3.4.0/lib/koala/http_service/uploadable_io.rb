require "tempfile"

module Koala
  module HTTPService
    class UploadableIO
      attr_reader :io_or_path, :content_type, :filename

      def initialize(io_or_path_or_mixed, content_type = nil, filename = nil)
        # see if we got the right inputs
        parse_init_mixed_param io_or_path_or_mixed, content_type

        # filename is used in the Ads API
        # if it's provided, take precedence over the detected filename
        # otherwise, fall back to a dummy name
        @filename = filename || @filename || "koala-io-file.dum"

        raise KoalaError.new("Invalid arguments to initialize an UploadableIO") unless @io_or_path
        raise KoalaError.new("Unable to determine MIME type for UploadableIO") if !@content_type
      end

      def to_upload_io
        UploadIO.new(@io_or_path, @content_type, @filename)
      end

      def to_file
        @io_or_path.is_a?(String) ? File.open(@io_or_path) : @io_or_path
      end

      def self.binary_content?(content)
        content.is_a?(UploadableIO) || DETECTION_STRATEGIES.detect {|method| send(method, content)}
      end

      private
      DETECTION_STRATEGIES = [
        :sinatra_param?,
        :rails_3_param?,
        :file_param?
      ]

      PARSE_STRATEGIES = [
        :parse_rails_3_param,
        :parse_sinatra_param,
        :parse_file_object,
        :parse_string_path,
        :parse_io
      ]

      def parse_init_mixed_param(mixed, content_type = nil)
        PARSE_STRATEGIES.each do |method|
          send(method, mixed, content_type)
          return if @io_or_path && @content_type
        end
      end

      # Expects a parameter of type ActionDispatch::Http::UploadedFile
      def self.rails_3_param?(uploaded_file)
        uploaded_file.respond_to?(:content_type) and uploaded_file.respond_to?(:tempfile) and uploaded_file.tempfile.respond_to?(:path)
      end

      def parse_rails_3_param(uploaded_file, content_type = nil)
        if UploadableIO.rails_3_param?(uploaded_file)
          @io_or_path = uploaded_file.tempfile.path
          @content_type = content_type || uploaded_file.content_type
          @filename = uploaded_file.original_filename
        end
      end

      # Expects a Sinatra hash of file info
      def self.sinatra_param?(file_hash)
        file_hash.kind_of?(Hash) and file_hash.has_key?(:type) and file_hash.has_key?(:tempfile)
      end

      def parse_sinatra_param(file_hash, content_type = nil)
        if UploadableIO.sinatra_param?(file_hash)
          @io_or_path = file_hash[:tempfile]
          @content_type = content_type || file_hash[:type] || detect_mime_type(tempfile)
          @filename = file_hash[:filename]
        end
      end

      # takes a file object
      def self.file_param?(file)
        file.kind_of?(File) || file.kind_of?(Tempfile)
      end

      def parse_file_object(file, content_type = nil)
        if UploadableIO.file_param?(file)
          @io_or_path = file
          @content_type = content_type || detect_mime_type(file.path)
          @filename = File.basename(file.path)
        end
      end

      def parse_string_path(path, content_type = nil)
        if path.kind_of?(String)
          @io_or_path = path
          @content_type = content_type || detect_mime_type(path)
          @filename = File.basename(path)
        end
      end

      def parse_io(io, content_type = nil)
        if io.respond_to?(:read)
          @io_or_path = io
          @content_type = content_type
        end
      end

      MIME_TYPE_STRATEGIES = [
        :use_mime_module,
        :use_simple_detection
      ]

      def detect_mime_type(filename)
        if filename
          MIME_TYPE_STRATEGIES.each do |method|
            result = send(method, filename)
            return result if result
          end
        end
        nil # if we can't find anything
      end

      def use_mime_module(filename)
        # if the user has installed mime/types, we can use that
        # if not, rescue and return nil
        begin
          type = MIME::Types.type_for(filename).first
          type ? type.to_s : nil
        rescue
          nil
        end
      end

      def use_simple_detection(filename)
        # very rudimentary extension analysis for images
        # first, get the downcased extension, or an empty string if it doesn't exist
        extension = ((filename.match(/\.([a-zA-Z0-9]+)$/) || [])[1] || "").downcase
        case extension
          when ""
            nil
          # images
          when "jpg", "jpeg"
            "image/jpeg"
          when "png"
            "image/png"
          when "gif"
            "image/gif"

          # video
          when "3g2"
          	"video/3gpp2"
          when "3gp", "3gpp"
          	"video/3gpp"
          when "asf"
          	"video/x-ms-asf"
          when "avi"
          	"video/x-msvideo"
          when "flv"
          	"video/x-flv"
          when "m4v"
          	"video/x-m4v"
          when "mkv"
          	"video/x-matroska"
          when "mod"
          	"video/mod"
          when "mov", "qt"
          	"video/quicktime"
          when "mp4", "mpeg4"
          	"video/mp4"
          when "mpe", "mpeg", "mpg", "tod", "vob"
          	"video/mpeg"
          when "nsv"
          	"application/x-winamp"
          when "ogm", "ogv"
          	"video/ogg"
          when "wmv"
          	"video/x-ms-wmv"
        end
      end
    end
  end
end
