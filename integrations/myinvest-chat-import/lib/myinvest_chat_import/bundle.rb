# frozen_string_literal: true

module MyinvestChatImport
  class Bundle
    TENANTS = %w[saas new_academy legacy_academy].freeze
    FILE_NAMES = {
      'contacts' => 'contacts.ndjson',
      'conversations' => 'conversations.ndjson',
      'messages' => 'messages.ndjson'
    }.freeze
    MANIFEST_KEYS = %w[schema_version source_namespace export_id tenant_key created_at knowledge_import files].freeze
    FILE_KEYS = %w[path sha256 count].freeze
    CONTACT_KEYS = %w[external_id name email phone_number created_at updated_at].freeze
    CONVERSATION_KEYS = %w[external_id contact_external_id status created_at updated_at].freeze
    MESSAGE_KEYS = %w[external_id conversation_external_id direction content created_at updated_at attachments metadata].freeze
    ATTACHMENT_KEYS = %w[external_id path sha256 byte_size filename content_type].freeze
    MAX_ID_LENGTH = 512
    MAX_MESSAGE_LENGTH = 150_000
    MAX_ATTACHMENTS_PER_MESSAGE = 100
    MAX_ATTACHMENT_BYTES = 1_073_741_824
    MAX_RECORDS_PER_FILE = 10_000_000
    FORBIDDEN_METADATA_KEY = /(?:^|_)(?:route|routing|tenant|account|inbox|agent|bot|handoff|assignee|status|direction)(?:_|$)/i

    attr_reader :bundle_sha256, :contacts, :conversations, :export_id, :messages, :schema_version, :source_namespace, :tenant_key

    def self.load(path)
      new(path).tap(&:load!)
    end

    def initialize(path)
      @root = safe_root(path)
    end

    def total_records
      contacts.length + conversations.length + messages.length
    end

    def load!
      manifest_path = safe_file('manifest.json')
      manifest_bytes = read_utf8(manifest_path, max_bytes: 1_048_576)
      manifest = parse_object(manifest_bytes, 'invalid_manifest_json')
      validate_exact_keys!(manifest, MANIFEST_KEYS, 'manifest_schema_mismatch')
      validate_manifest!(manifest)

      @bundle_sha256 = Digest::SHA256.hexdigest(manifest_bytes.b)
      @schema_version = manifest.fetch('schema_version')
      @source_namespace = stable_id!(manifest.fetch('source_namespace'))
      @export_id = stable_id!(manifest.fetch('export_id'))
      @tenant_key = manifest.fetch('tenant_key')
      @contacts = load_records(manifest, 'contacts') { |record| validate_contact!(record) }
      @conversations = load_records(manifest, 'conversations') { |record| validate_conversation!(record) }
      @messages = load_records(manifest, 'messages') { |record| validate_message!(record) }
      validate_references!
      self
    end

    def attachment_path(descriptor)
      raise UnsupportedAttachmentError unless schema_version == 2

      safe_attachment_file(descriptor.fetch('path'))
    end

    private

    def safe_root(path)
      expanded = File.expand_path(path.to_s)
      raise UnsafePathError unless File.directory?(expanded) && !File.symlink?(expanded)

      File.realpath(expanded)
    rescue Errno::ENOENT, Errno::EACCES
      raise UnsafePathError
    end

    def safe_file(relative_path)
      raise UnsafePathError unless relative_path.is_a?(String) && File.basename(relative_path) == relative_path

      path = File.join(@root, relative_path)
      stat = File.lstat(path)
      real = File.realpath(path)
      raise UnsafePathError unless stat.file? && !stat.symlink? && File.dirname(real) == @root

      real
    rescue Errno::ENOENT, Errno::EACCES
      raise UnsafePathError
    end

    def read_utf8(path, max_bytes: nil)
      raise ValidationError, 'file_too_large' if max_bytes && File.size(path) > max_bytes

      bytes = File.binread(path)
      text = bytes.dup.force_encoding(Encoding::UTF_8)
      raise InvalidEncodingError unless text.valid_encoding?
      raise ValidationError, 'nul_byte_not_allowed' if text.include?("\0")

      text
    end

    def parse_object(json, error_code)
      parsed = JSON.parse(json)
      raise ValidationError, error_code unless parsed.is_a?(Hash)

      parsed
    rescue JSON::ParserError
      raise ValidationError, error_code
    end

    def validate_exact_keys!(record, allowed, error_code, optional: [])
      required = allowed - optional
      raise ValidationError, error_code unless (required - record.keys).empty? && (record.keys - allowed).empty?
    end

    def validate_manifest!(manifest)
      raise ValidationError, 'unsupported_schema_version' unless [1, 2].include?(manifest.fetch('schema_version'))
      stable_id!(manifest.fetch('source_namespace'))
      stable_id!(manifest.fetch('export_id'))
      raise ValidationError, 'unsupported_tenant' unless TENANTS.include?(manifest.fetch('tenant_key'))
      timestamp!(manifest.fetch('created_at'))
      raise KnowledgeSeparationError unless manifest.fetch('knowledge_import') == false
      raise ValidationError, 'files_schema_mismatch' unless manifest.fetch('files').is_a?(Hash) && manifest.fetch('files').keys.sort == FILE_NAMES.keys.sort

      manifest.fetch('files').each do |name, descriptor|
        raise ValidationError, 'file_descriptor_invalid' unless descriptor.is_a?(Hash)

        validate_exact_keys!(descriptor, FILE_KEYS, 'file_descriptor_invalid')
        raise UnsafePathError unless descriptor.fetch('path') == FILE_NAMES.fetch(name)
        raise ValidationError, 'invalid_file_sha256' unless descriptor.fetch('sha256').is_a?(String) && descriptor.fetch('sha256').match?(/\A[0-9a-f]{64}\z/)
        count = descriptor.fetch('count')
        raise ValidationError, 'invalid_file_count' unless count.is_a?(Integer) && count.between?(0, MAX_RECORDS_PER_FILE)
      end
    end

    def load_records(manifest, name)
      descriptor = manifest.fetch('files').fetch(name)
      bytes = read_utf8(safe_file(descriptor.fetch('path')))
      unless secure_equal?(Digest::SHA256.hexdigest(bytes.b), descriptor.fetch('sha256'))
        raise ValidationError, 'file_digest_mismatch'
      end

      records = bytes.lines(chomp: true).map do |line|
        raise ValidationError, 'blank_ndjson_line' if line.empty?

        record = parse_object(line, 'invalid_ndjson')
        yield record
        record.freeze
      end
      raise ValidationError, 'file_count_mismatch' unless records.length == descriptor.fetch('count')

      records.freeze
    end

    def validate_contact!(record)
      validate_exact_keys!(record, CONTACT_KEYS, 'contact_schema_mismatch', optional: %w[email phone_number])
      stable_id!(record.fetch('external_id'))
      string!(record.fetch('name'), 'invalid_contact_name', max: 255)
      optional_string!(record['email'], 'invalid_contact_email', max: 320)
      optional_string!(record['phone_number'], 'invalid_contact_phone', max: 32)
      raise ValidationError, 'invalid_contact_email' if record['email'] && !record['email'].match?(/\A[^\s@]+@[^\s@]+\.[^\s@]+\z/)
      raise ValidationError, 'invalid_contact_phone' if record['phone_number'] && !record['phone_number'].match?(/\A\+[1-9]\d{1,14}\z/)
      timestamp_pair!(record)
    end

    def validate_conversation!(record)
      validate_exact_keys!(record, CONVERSATION_KEYS, 'conversation_schema_mismatch')
      stable_id!(record.fetch('external_id'))
      stable_id!(record.fetch('contact_external_id'))
      raise ValidationError, 'conversation_must_be_resolved' unless record.fetch('status') == 'resolved'
      timestamp_pair!(record)
    end

    def validate_message!(record)
      validate_exact_keys!(record, MESSAGE_KEYS, 'message_schema_mismatch', optional: ['metadata'])
      stable_id!(record.fetch('external_id'))
      stable_id!(record.fetch('conversation_external_id'))
      raise ValidationError, 'invalid_message_direction' unless %w[incoming outgoing note].include?(record.fetch('direction'))
      string!(record.fetch('content'), 'invalid_message_content', max: MAX_MESSAGE_LENGTH)
      raise ValidationError, 'attachments_must_be_array' unless record.fetch('attachments').is_a?(Array)
      attachments = record.fetch('attachments')
      raise ValidationError, 'too_many_attachments' if attachments.length > MAX_ATTACHMENTS_PER_MESSAGE
      raise UnsupportedAttachmentError if schema_version == 1 && attachments.any?
      attachments.each { |attachment| validate_attachment!(attachment) } if schema_version == 2
      validate_metadata!(record.fetch('metadata', {}))
      timestamp_pair!(record)
    end

    def validate_attachment!(attachment)
      raise ValidationError, 'attachment_schema_mismatch' unless attachment.is_a?(Hash)

      validate_exact_keys!(attachment, ATTACHMENT_KEYS, 'attachment_schema_mismatch')
      stable_id!(attachment.fetch('external_id'))
      path = attachment.fetch('path')
      digest = attachment.fetch('sha256')
      raise UnsafePathError unless path.is_a?(String) && path.match?(%r{\Aattachments/[0-9a-f]{64}\z})
      raise ValidationError, 'invalid_attachment_sha256' unless digest.is_a?(String) && digest.match?(/\A[0-9a-f]{64}\z/)
      raise ValidationError, 'attachment_path_digest_mismatch' unless File.basename(path) == digest

      byte_size = attachment.fetch('byte_size')
      raise ValidationError, 'invalid_attachment_size' unless byte_size.is_a?(Integer) && byte_size.between?(0, MAX_ATTACHMENT_BYTES)
      filename = attachment.fetch('filename')
      string!(filename, 'invalid_attachment_filename', max: 255)
      raise ValidationError, 'invalid_attachment_filename' if filename.empty? || filename != File.basename(filename) || filename.match?(/[\\\/\r\n]/)
      content_type = attachment.fetch('content_type')
      string!(content_type, 'invalid_attachment_content_type', max: 255)
      raise ValidationError, 'invalid_attachment_content_type' unless content_type.match?(%r{\A[a-z0-9][a-z0-9.+-]*/[a-z0-9][a-z0-9.+-]*\z}i)

      absolute_path = safe_attachment_file(path)
      raise ValidationError, 'attachment_size_mismatch' unless File.size(absolute_path) == byte_size
      raise ValidationError, 'attachment_digest_mismatch' unless secure_equal?(Digest::SHA256.file(absolute_path).hexdigest, digest)
    end

    def safe_attachment_file(relative_path)
      path = File.join(@root, relative_path)
      stat = File.lstat(path)
      real = File.realpath(path)
      attachment_directory = File.join(@root, 'attachments')
      directory_stat = File.lstat(attachment_directory)
      attachment_root = File.realpath(attachment_directory)
      raise UnsafePathError unless directory_stat.directory? && !directory_stat.symlink? && File.dirname(attachment_root) == @root
      raise UnsafePathError unless stat.file? && !stat.symlink? && File.dirname(real) == attachment_root

      real
    rescue Errno::ENOENT, Errno::EACCES
      raise UnsafePathError
    end

    def validate_metadata!(metadata)
      raise ValidationError, 'invalid_provenance_metadata' unless metadata.is_a?(Hash)

      walk_metadata(metadata)
      JSON.generate(metadata)
    rescue JSON::GeneratorError
      raise ValidationError, 'invalid_provenance_metadata'
    end

    def walk_metadata(value)
      case value
      when Hash
        value.each do |key, child|
          raise ValidationError, 'routing_metadata_not_allowed' unless key.is_a?(String) && !key.match?(FORBIDDEN_METADATA_KEY)

          walk_metadata(child)
        end
      when Array
        value.each { |child| walk_metadata(child) }
      when String
        string!(value, 'invalid_provenance_metadata', max: 10_000)
      when Integer, Float, TrueClass, FalseClass, NilClass
        nil
      else
        raise ValidationError, 'invalid_provenance_metadata'
      end
    end

    def validate_references!
      contacts_by_id = unique_by_external_id!(contacts, 'duplicate_contact_id')
      conversations_by_id = unique_by_external_id!(conversations, 'duplicate_conversation_id')
      unique_by_external_id!(messages, 'duplicate_message_id')
      conversations.each do |conversation|
        raise ValidationError, 'unknown_contact_reference' unless contacts_by_id.key?(conversation.fetch('contact_external_id'))
      end
      messages.each do |message|
        raise ValidationError, 'unknown_conversation_reference' unless conversations_by_id.key?(message.fetch('conversation_external_id'))
      end
    end

    def unique_by_external_id!(records, error_code)
      records.each_with_object({}) do |record, index|
        external_id = record.fetch('external_id')
        raise ValidationError, error_code if index.key?(external_id)

        index[external_id] = record
      end
    end

    def stable_id!(value)
      string!(value, 'invalid_external_id', max: MAX_ID_LENGTH)
      raise ValidationError, 'invalid_external_id' if value.empty?

      value
    end

    def optional_string!(value, code, max:)
      return if value.nil?

      string!(value, code, max: max)
    end

    def string!(value, code, max:)
      raise ValidationError, code unless value.is_a?(String) && value.valid_encoding? && !value.include?("\0") && value.length <= max
    end

    def timestamp_pair!(record)
      created_at = timestamp!(record.fetch('created_at'))
      updated_at = timestamp!(record.fetch('updated_at'))
      raise ValidationError, 'timestamp_order_invalid' if updated_at < created_at
    end

    def timestamp!(value)
      raise ValidationError, 'invalid_timestamp' unless value.is_a?(String)

      parsed = Time.iso8601(value)
      raise ValidationError, 'timestamp_requires_timezone' unless value.match?(/(?:Z|[+-]\d{2}:\d{2})\z/)

      parsed
    rescue ArgumentError
      raise ValidationError, 'invalid_timestamp'
    end

    def secure_equal?(left, right)
      return false unless left.bytesize == right.bytesize

      left.bytes.zip(right.bytes).reduce(0) { |difference, (a, b)| difference | (a ^ b) }.zero?
    end
  end
end
