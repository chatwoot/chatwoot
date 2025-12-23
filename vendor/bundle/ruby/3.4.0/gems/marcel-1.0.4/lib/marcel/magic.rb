# frozen_string_literal: true

# Code in this file adapted from the mimemagic gem, released under the MIT License.
# Copyright (c) 2011 Daniel Mendler. Available at https://github.com/mimemagicrb/mimemagic.

require 'marcel/tables'

require 'stringio'

module Marcel
  # Mime type detection
  class Magic
    attr_reader :type, :mediatype, :subtype

    # Mime type by type string
    def initialize(type)
      @type = type
      @mediatype, @subtype = type.split('/', 2)
    end

    # Add custom mime type. Arguments:
    # * <i>type</i>: Mime type
    # * <i>options</i>: Options hash
    #
    # Option keys:
    # * <i>:extensions</i>: String list or single string of file extensions
    # * <i>:parents</i>: String list or single string of parent mime types
    # * <i>:magic</i>: Mime magic specification
    # * <i>:comment</i>: Comment string
    def self.add(type, options)
      extensions = [options[:extensions]].flatten.compact
      TYPE_EXTS[type] = extensions
      parents = [options[:parents]].flatten.compact
      TYPE_PARENTS[type] = parents unless parents.empty?
      extensions.each {|ext| EXTENSIONS[ext] = type }
      MAGIC.unshift [type, options[:magic]] if options[:magic]
    end

    # Removes a mime type from the dictionary.  You might want to do this if
    # you're seeing impossible conflicts (for instance, application/x-gmc-link).
    # * <i>type</i>: The mime type to remove.  All associated extensions and magic are removed too.
    def self.remove(type)
      EXTENSIONS.delete_if {|ext, t| t == type }
      MAGIC.delete_if {|t, m| t == type }
      TYPE_EXTS.delete(type)
      TYPE_PARENTS.delete(type)
    end

    # Returns true if type is a text format
    def text?; mediatype == 'text' || child_of?('text/plain'); end

    # Mediatype shortcuts
    def image?; mediatype == 'image'; end
    def audio?; mediatype == 'audio'; end
    def video?; mediatype == 'video'; end

    # Returns true if type is child of parent type
    def child_of?(parent)
      self.class.child?(type, parent)
    end

    # Get string list of file extensions
    def extensions
      TYPE_EXTS[type] || []
    end

    # Get mime comment
    def comment
      nil # deprecated
    end

    # Lookup mime type by file extension
    def self.by_extension(ext)
      ext = ext.to_s.downcase
      mime = ext[0..0] == '.' ? EXTENSIONS[ext[1..-1]] : EXTENSIONS[ext]
      mime && new(mime)
    end

    # Lookup mime type by filename
    def self.by_path(path)
      by_extension(File.extname(path))
    end

    # Lookup mime type by magic content analysis.
    # This is a slow operation.
    def self.by_magic(io)
      mime = magic_match(io, :find)
      mime && new(mime[0])
    end

    # Lookup all mime types by magic content analysis.
    # This is a slower operation.
    def self.all_by_magic(io)
      magic_match(io, :select).map { |mime| new(mime[0]) }
    end

    # Return type as string
    def to_s
      type
    end

    # Allow comparison with string
    def eql?(other)
      type == other.to_s
    end

    def hash
      type.hash
    end

    alias == eql?

    def self.child?(child, parent)
      child == parent || TYPE_PARENTS[child]&.any? {|p| child?(p, parent) }
    end

    def self.magic_match(io, method)
      return magic_match(StringIO.new(io.to_s), method) unless io.respond_to?(:read)

      io.binmode if io.respond_to?(:binmode)
      io.set_encoding(Encoding::BINARY) if io.respond_to?(:set_encoding)
      buffer = "".encode(Encoding::BINARY)

      MAGIC.send(method) { |type, matches| magic_match_io(io, matches, buffer) }
    end

    def self.magic_match_io(io, matches, buffer)
      matches.any? do |offset, value, children|
        match =
          if value
            if Range === offset
              io.read(offset.begin, buffer)
              x = io.read(offset.end - offset.begin + value.bytesize, buffer)
              x && x.include?(value)
            else
              io.read(offset, buffer)
              io.read(value.bytesize, buffer) == value
            end
          end

        io.rewind
        match && (!children || magic_match_io(io, children, buffer))
      end
    end

    private_class_method :magic_match, :magic_match_io
  end
end
