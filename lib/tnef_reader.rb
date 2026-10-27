# Reads the files out of an Outlook TNEF (winmail.dat) stream. Pure Ruby on purpose: TNEF parsers
# written in C have had remotely triggerable memory bugs, and the stream comes straight from an email.
#
# Only the attachment attributes are read. Every declared length is checked against the bytes that
# are left and the checksum of each attribute that is used is verified, so malformed input raises
# TnefReader::Error instead of reading out of bounds. A file is named from its attachment title,
# which older Outlook versions write as an 8.3 short name; the long name lives in a MAPI block that
# is not read.
class TnefReader
  class Error < StandardError; end

  Entry = Struct.new(:name, :data)

  SIGNATURE = 0x223E9F78
  HEADER_SIZE = 6 # signature (4) + key (2)
  ATTRIBUTE_HEADER_SIZE = 9 # level (1) + id (4) + length (4)
  CHECKSUM_SIZE = 2
  ATTACHMENT_LEVEL = 2
  ATT_ATTACH_RENDDATA = 0x00069002 # starts a new attachment
  ATT_ATTACH_TITLE = 0x00018010
  ATT_ATTACH_DATA = 0x0006800F

  def self.files(data)
    new(data).files
  end

  def initialize(data)
    @data = data.to_s.b
  end

  def files
    raise Error, 'not a TNEF stream' unless tnef_stream?

    entries = []
    each_attachment_attribute { |id, body| add_attribute(entries, id, body) }
    entries.filter_map { |entry| build_entry(entry) }
  end

  private

  def tnef_stream?
    @data.bytesize >= HEADER_SIZE && @data.unpack1('V') == SIGNATURE
  end

  def add_attribute(entries, id, body)
    case id
    when ATT_ATTACH_RENDDATA then entries << { index: entries.size + 1 }
    when ATT_ATTACH_TITLE then entries.last&.store(:name, body)
    when ATT_ATTACH_DATA then entries.last&.store(:data, body)
    end
  end

  def each_attachment_attribute
    offset = HEADER_SIZE
    while offset < @data.bytesize
      raise Error, 'stream ends inside an attribute header' if offset + ATTRIBUTE_HEADER_SIZE > @data.bytesize

      level, id, length = @data.unpack('CVV', offset: offset)
      body_offset = offset + ATTRIBUTE_HEADER_SIZE
      raise Error, 'attribute is longer than the stream' if length > @data.bytesize - body_offset - CHECKSUM_SIZE

      yield id, attribute_body(body_offset, length) if level == ATTACHMENT_LEVEL
      offset = body_offset + length + CHECKSUM_SIZE
    end
  end

  def attribute_body(offset, length)
    body = @data.byteslice(offset, length)
    raise Error, 'attribute checksum does not match' unless body.sum == @data.unpack1('v', offset: offset + length)

    body
  end

  def build_entry(entry)
    return if entry[:data].nil?

    Entry.new(file_name(entry[:name], entry[:index]), entry[:data])
  end

  # The title is a null-terminated string written by the sender.
  def file_name(raw, index)
    name = raw.to_s.split("\0", 2).first.to_s.dup.force_encoding(Encoding::UTF_8).scrub('_').strip
    name.empty? ? "attachment-#{index}" : name
  end
end
