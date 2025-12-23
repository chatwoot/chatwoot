# frozen_string_literal: true

require 'thread'
require 'set'
require 'tempfile'
require 'stringio'

module Aws
  module S3
    # @api private
    class MultipartStreamUploader
      # api private
      PART_SIZE = 5 * 1024 * 1024 # 5MB

      # api private
      THREAD_COUNT = 10

      # api private
      TEMPFILE_PREIX = 'aws-sdk-s3-upload_stream'.freeze

      # @api private
      CREATE_OPTIONS =
        Set.new(Client.api.operation(:create_multipart_upload).input.shape.member_names)

      # @api private
      UPLOAD_PART_OPTIONS =
        Set.new(Client.api.operation(:upload_part).input.shape.member_names)

      # @api private
      COMPLETE_UPLOAD_OPTIONS =
        Set.new(Client.api.operation(:complete_multipart_upload).input.shape.member_names)

      # @option options [Client] :client
      def initialize(options = {})
        @client = options[:client] || Client.new
        @tempfile = options[:tempfile]
        @part_size = options[:part_size] || PART_SIZE
        @thread_count = options[:thread_count] || THREAD_COUNT
      end

      # @return [Client]
      attr_reader :client

      # @option options [required,String] :bucket
      # @option options [required,String] :key
      # @return [Seahorse::Client::Response] - the CompleteMultipartUploadResponse
      def upload(options = {}, &block)
        Aws::Plugins::UserAgent.feature('s3-transfer') do
          upload_id = initiate_upload(options)
          parts = upload_parts(upload_id, options, &block)
          complete_upload(upload_id, parts, options)
        end
      end

      private

      def initiate_upload(options)
        @client.create_multipart_upload(create_opts(options)).upload_id
      end

      def complete_upload(upload_id, parts, options)
        @client.complete_multipart_upload(
          **complete_opts(options).merge(
            upload_id: upload_id,
            multipart_upload: { parts: parts }
          )
        )
      end

      def upload_parts(upload_id, options, &block)
        completed = Queue.new
        thread_errors = []
        errors = begin
          IO.pipe do |read_pipe, write_pipe|
            threads = upload_in_threads(
              read_pipe, completed,
              upload_part_opts(options).merge(upload_id: upload_id),
              thread_errors)
            begin
              block.call(write_pipe)
            ensure
              # Ensure the pipe is closed to avoid https://github.com/jruby/jruby/issues/6111
              write_pipe.close
            end
            threads.map(&:value).compact
          end
        rescue => e
          thread_errors + [e]
        end

        if errors.empty?
          Array.new(completed.size) { completed.pop }.sort_by { |part| part[:part_number] }
        else
          abort_upload(upload_id, options, errors)
        end
      end

      def abort_upload(upload_id, options, errors)
        @client.abort_multipart_upload(
          bucket: options[:bucket],
          key: options[:key],
          upload_id: upload_id
        )
        msg = "multipart upload failed: #{errors.map(&:message).join("; ")}"
        raise MultipartUploadError.new(msg, errors)
      rescue MultipartUploadError => error
        raise error
      rescue => error
        msg = "failed to abort multipart upload: #{error.message}"
        raise MultipartUploadError.new(msg, errors + [error])
      end

      def create_opts(options)
        CREATE_OPTIONS.inject({}) do |hash, key|
          hash[key] = options[key] if options.key?(key)
          hash
        end
      end

      def upload_part_opts(options)
        UPLOAD_PART_OPTIONS.inject({}) do |hash, key|
          hash[key] = options[key] if options.key?(key)
          hash
        end
      end

      def complete_opts(options)
        COMPLETE_UPLOAD_OPTIONS.inject({}) do |hash, key|
          hash[key] = options[key] if options.key?(key)
          hash
        end
      end

      def read_to_part_body(read_pipe)
        return if read_pipe.closed?
        temp_io = @tempfile ? Tempfile.new(TEMPFILE_PREIX) : StringIO.new(String.new)
        temp_io.binmode
        bytes_copied = IO.copy_stream(read_pipe, temp_io, @part_size)
        temp_io.rewind
        if bytes_copied == 0
          if Tempfile === temp_io
            temp_io.close
            temp_io.unlink
          end
          nil
        else
          temp_io
        end
      end

      def upload_in_threads(read_pipe, completed, options, thread_errors)
        mutex = Mutex.new
        part_number = 0
        @thread_count.times.map do
          thread = Thread.new do
            begin
              loop do
                body, thread_part_number = mutex.synchronize do
                  [read_to_part_body(read_pipe), part_number += 1]
                end
                break unless (body || thread_part_number == 1)
                begin
                  part = options.merge(
                    body: body,
                    part_number: thread_part_number,
                  )
                  resp = @client.upload_part(part)
                  completed_part = {etag: resp.etag, part_number: part[:part_number]}

                  # get the requested checksum from the response
                  if part[:checksum_algorithm]
                    k = "checksum_#{part[:checksum_algorithm].downcase}".to_sym
                    completed_part[k] = resp[k]
                  end
                  completed.push(completed_part)
                ensure
                  if Tempfile === body
                    body.close
                    body.unlink
                  elsif StringIO === body
                    body.string.clear
                  end
                end
              end
              nil
            rescue => error
              # keep other threads from uploading other parts
              mutex.synchronize do
                thread_errors.push(error)
                read_pipe.close_read unless read_pipe.closed?
              end
              error
            end
          end
          thread.abort_on_exception = true
          thread
        end
      end
    end
  end
end
