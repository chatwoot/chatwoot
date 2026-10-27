# Reads the files out of an Outlook TNEF (winmail.dat) stream. Pure Ruby on purpose: TNEF parsers
# written in C have had remotely triggerable memory bugs, and the stream comes straight from an email.
#
# Only the attachment attributes are read. Every declared length is checked against the bytes that
# are left and the checksum of each attribute that is used is verified, so malformed input raises
# TnefReader::Error instead of reading out of bounds, and so does a stream with more than
# MAX_ATTACHMENTS attachment records. A file is named from its attachment title, decoded with the
# code page the stream declares; older Outlook versions write the title as an 8.3 short name and the
# long name lives in a MAPI block that is not read.
class TnefReader
  class Error < StandardError; end

  Entry = Struct.new(:name, :data)

  SIGNATURE = 0x223E9F78
  HEADER_SIZE = 6 # signature (4) + key (2)
  ATTRIBUTE_HEADER_SIZE = 9 # level (1) + id (4) + length (4)
  CHECKSUM_SIZE = 2
  MESSAGE_LEVEL = 1
  ATTACHMENT_LEVEL = 2
  MAX_ATTACHMENTS = 100
  ATT_OEM_CODEPAGE = 0x00069007
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
    each_attribute { |level, id, body| add_attribute(entries, level, id, body) }
    entries.filter_map { |entry| build_entry(entry) }
  end

  private

  def tnef_stream?
    @data.bytesize >= HEADER_SIZE && @data.unpack1('V') == SIGNATURE
  end

  def add_attribute(entries, level, id, body)
    if level == MESSAGE_LEVEL
      @codepage = body.unpack1('V') if id == ATT_OEM_CODEPAGE && body.bytesize >= 4
    else
      add_attachment_attribute(entries, id, body)
    end
  end

  def add_attachment_attribute(entries, id, body)
    case id
    when ATT_ATTACH_RENDDATA then entries << new_entry(entries.size + 1)
    when ATT_ATTACH_TITLE then entries.last&.store(:name, body)
    when ATT_ATTACH_DATA then entries.last&.store(:data, body)
    end
  end

  def new_entry(index)
    raise Error, "more than #{MAX_ATTACHMENTS} attachments" if index > MAX_ATTACHMENTS

    { index: index }
  end

  def each_attribute
    offset = HEADER_SIZE
    while offset < @data.bytesize
      raise Error, 'stream ends inside an attribute header' if offset + ATTRIBUTE_HEADER_SIZE > @data.bytesize

      level, id, length = @data.unpack('CVV', offset: offset)
      body_offset = offset + ATTRIBUTE_HEADER_SIZE
      raise Error, 'attribute is longer than the stream' if length > @data.bytesize - body_offset - CHECKSUM_SIZE

      yield level, id, attribute_body(body_offset, length) if [MESSAGE_LEVEL, ATTACHMENT_LEVEL].include?(level)
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

  # The title is a null-terminated string written by the sender in the stream's OEM code page.
  def file_name(raw, index)
    title = raw.to_s.split("\0", 2).first.to_s.dup.force_encoding(title_encoding)
    name = title.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: '_').strip
    name.empty? ? "attachment-#{index}" : name
  end

  def title_encoding
    @codepage ? Encoding.find("CP#{@codepage}") : Encoding::UTF_8
  rescue ArgumentError
    Encoding::UTF_8
  end
end
