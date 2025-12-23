# frozen_string_literal: true

require 'pathname'

module Aws
  module S3
    # @api private
    class FileUploader

      ONE_HUNDRED_MEGABYTES = 100 * 1024 * 1024

      # @param [Hash] options
      # @option options [Client] :client
      # @option options [Integer] :multipart_threshold (104857600)
      def initialize(options = {})
        @options = options
        @client = options[:client] || Client.new
        @multipart_threshold = options[:multipart_threshold] ||
                               ONE_HUNDRED_MEGABYTES
      end

      # @return [Client]
      attr_reader :client

      # @return [Integer] Files larger than or equal to this in bytes are uploaded
      #   using a {MultipartFileUploader}.
      attr_reader :multipart_threshold

      # @param [String, Pathname, File, Tempfile] source The file to upload.
      # @option options [required, String] :bucket The bucket to upload to.
      # @option options [required, String] :key The key for the object.
      # @option options [Proc] :progress_callback
      #   A Proc that will be called when each chunk of the upload is sent.
      #   It will be invoked with [bytes_read], [total_sizes]
      # @option options [Integer] :thread_count
      #   The thread count to use for multipart uploads. Ignored for
      #   objects smaller than the multipart threshold.
      # @return [void]
      def upload(source, options = {})
        Aws::Plugins::UserAgent.feature('s3-transfer') do
          if File.size(source) >= multipart_threshold
            MultipartFileUploader.new(@options).upload(source, options)
          else
            # remove multipart parameters not supported by put_object
            options.delete(:thread_count)
            put_object(source, options)
          end
        end
      end

      private

      def open_file(source)
        if String === source || Pathname === source
          File.open(source, 'rb') { |file| yield(file) }
        else
          yield(source)
        end
      end

      def put_object(source, options)
        if (callback = options.delete(:progress_callback))
          options[:on_chunk_sent] = single_part_progress(callback)
        end
        open_file(source) do |file|
          @client.put_object(options.merge(body: file))
        end
      end

      def single_part_progress(progress_callback)
        proc do |_chunk, bytes_read, total_size|
          progress_callback.call([bytes_read], [total_size])
        end
      end
    end
  end
end
