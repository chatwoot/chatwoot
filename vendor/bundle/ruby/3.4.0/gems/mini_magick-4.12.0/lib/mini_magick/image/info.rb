require "json"

module MiniMagick
  class Image
    # @private
    class Info
      ASCII_ENCODED_EXIF_KEYS = %w[ExifVersion FlashPixVersion]

      def initialize(path)
        @path = path
        @info = {}
      end

      def [](value, *args)
        case value
        when "format", "width", "height", "dimensions", "size", "human_size"
          cheap_info(value)
        when "colorspace"
          colorspace
        when "mime_type"
          mime_type
        when "resolution"
          resolution(*args)
        when "signature"
          signature
        when /^EXIF\:/i
          raw_exif(value)
        when "exif"
          exif
        when "details"
          details
        when "data"
          data
        else
          raw(value)
        end
      end

      def clear
        @info.clear
      end

      def cheap_info(value)
        @info.fetch(value) do
          format, width, height, size = parse_warnings(self["%m %w %h %b"]).split(" ")

          path = @path
          path = path.match(/\[\d+\]$/).pre_match if path =~ /\[\d+\]$/

          @info.update(
            "format"     => format,
            "width"      => Integer(width),
            "height"     => Integer(height),
            "dimensions" => [Integer(width), Integer(height)],
            "size"       => File.size(path),
            "human_size" => size,
          )

          @info.fetch(value)
        end
      rescue ArgumentError, TypeError
        raise MiniMagick::Invalid, "image data can't be read"
      end

      def parse_warnings(raw_info)
        return raw_info unless raw_info.split("\n").size > 1

        raw_info.split("\n").each do |line|
          # must match "%m %w %h %b"
          return line if line.match?(/^[A-Z]+ \d+ \d+ \d+(|\.\d+)([KMGTPEZY]{0,1})B$/)
        end
        raise TypeError
      end

      def colorspace
        @info["colorspace"] ||= self["%r"]
      end

      def mime_type
        "image/#{self["format"].downcase}"
      end

      def resolution(unit = nil)
        output = identify do |b|
          b.units unit if unit
          b.format "%x %y"
        end
        output.split(" ").map(&:to_i)
      end

      def raw_exif(value)
        self["%[#{value}]"]
      end

      def exif
        @info["exif"] ||= (
          hash = {}
          output = self["%[EXIF:*]"]

          output.each_line do |line|
            line = line.chomp("\n")

            case MiniMagick.cli
            when :imagemagick, :imagemagick7
              if match = line.match(/^exif:/)
                key, value = match.post_match.split("=", 2)
                value = decode_comma_separated_ascii_characters(value) if ASCII_ENCODED_EXIF_KEYS.include?(key)
                hash[key] = value
              else
                hash[hash.keys.last] << "\n#{line}"
              end
            when :graphicsmagick
              next if line == "unknown"
              key, value = line.split("=", 2)
              value.gsub!("\\012", "\n") # convert "\012" characters to newlines
              hash[key] = value
            end
          end

          hash
        )
      end

      def raw(value)
        @info["raw:#{value}"] ||= identify { |b| b.format(value) }
      end

      def signature
        @info["signature"] ||= self["%#"]
      end

      def details
        warn "[MiniMagick] MiniMagick::Image#details has been deprecated, as it was causing too many parsing errors. You should use MiniMagick::Image#data instead, which differs in a way that the keys are in camelcase." if MiniMagick.imagemagick? || MiniMagick.imagemagick7?

        @info["details"] ||= (
          details_string = identify(&:verbose)
          key_stack = []
          details_string.lines.to_a[1..-1].each_with_object({}) do |line, details_hash|
            next if !line.valid_encoding? || line.strip.length.zero?

            level = line[/^\s*/].length / 2 - 1
            if level >= 0
              key_stack.pop until key_stack.size <= level
            else
              # Some metadata, such as SVG clipping paths, will be saved without
              # indentation, resulting in a level of -1
              last_key = details_hash.keys.last
              details_hash[last_key] = '' if details_hash[last_key].empty?
              details_hash[last_key] << line
              next
            end

            key, _, value = line.partition(/:[\s]/).map(&:strip)
            hash = key_stack.inject(details_hash) { |_hash, _key| _hash.fetch(_key) }
            if value.empty?
              hash[key] = {}
              key_stack.push key
            else
              hash[key] = value
            end
          end
        )
      end

      def data
        raise Error, "MiniMagick::Image#data isn't supported on GraphicsMagick. Use MiniMagick::Image#details instead." if MiniMagick.graphicsmagick?

        @info["data"] ||= (
          json = MiniMagick::Tool::Convert.new do |convert|
            convert << path
            convert << "json:"
          end

          data = JSON.parse(json)
          data = data.fetch(0) if data.is_a?(Array)
          data.fetch("image")
        )
      end

      def identify
        MiniMagick::Tool::Identify.new do |builder|
          yield builder if block_given?
          builder << path
        end
      end

      private

      def decode_comma_separated_ascii_characters(encoded_value)
        return encoded_value unless encoded_value.include?(',')
        encoded_value.scan(/\d+/).map(&:to_i).map(&:chr).join
      end

      def path
        value = @path
        value += "[0]" unless value =~ /\[\d+\]$/
        value
      end

    end
  end
end
