require "mini_magick"
require "image_processing"

module ImageProcessing
  module MiniMagick
    extend Chainable

    # Returns whether the given image file is processable.
    def self.valid_image?(file)
      ::MiniMagick::Tool::Convert.new do |convert|
        convert << file.path
        convert << "null:"
      end
      true
    rescue ::MiniMagick::Error
      false
    end

    class Processor < ImageProcessing::Processor
      accumulator :magick, ::MiniMagick::Tool

      # Default sharpening parameters used on generated thumbnails.
      SHARPEN_PARAMETERS = { radius: 0, sigma: 1 }

      # Initializes the image on disk into a MiniMagick::Tool object. Accepts
      # additional options related to loading the image (e.g. geometry).
      # Additionally auto-orients the image to be upright.
      def self.load_image(path_or_magick, loader: nil, page: nil, geometry: nil, auto_orient: true, **options)
        if path_or_magick.is_a?(::MiniMagick::Tool)
          magick = path_or_magick
        else
          source_path = path_or_magick
          magick = ::MiniMagick::Tool::Convert.new

          Utils.apply_options(magick, **options)

          input  = source_path
          input  = "#{loader}:#{input}" if loader
          input += "[#{page}]" if page
          input += "[#{geometry}]" if geometry

          magick << input
        end

        magick.auto_orient if auto_orient
        magick
      end

      # Calls the built ImageMagick command to perform processing and save
      # the result to disk. Accepts additional options related to saving the
      # image (e.g. quality).
      def self.save_image(magick, destination_path, allow_splitting: false, **options)
        Utils.apply_options(magick, **options)

        magick << destination_path
        magick.call

        Utils.disallow_split_layers!(destination_path) unless allow_splitting
      end

      # Resizes the image to not be larger than the specified dimensions.
      def resize_to_limit(width, height, **options)
        thumbnail("#{width}x#{height}>", **options)
      end

      # Resizes the image to fit within the specified dimensions.
      def resize_to_fit(width, height, **options)
        thumbnail("#{width}x#{height}", **options)
      end

      # Resizes the image to fill the specified dimensions, applying any
      # necessary cropping.
      def resize_to_fill(width, height, gravity: "Center", **options)
        thumbnail("#{width}x#{height}^", **options)
        magick.gravity gravity
        magick.background color(:transparent)
        magick.extent "#{width}x#{height}"
      end

      # Resizes the image to fit within the specified dimensions and fills
      # the remaining area with the specified background color.
      def resize_and_pad(width, height, background: :transparent, gravity: "Center", **options)
        thumbnail("#{width}x#{height}", **options)
        magick.background color(background)
        magick.gravity gravity
        magick.extent "#{width}x#{height}"
      end

      # Crops the image with the specified crop points.
      def crop(*args)
        case args.count
        when 1 then magick.crop(*args)
        when 4 then magick.crop("#{args[2]}x#{args[3]}+#{args[0]}+#{args[1]}")
        else fail ArgumentError, "wrong number of arguments (expected 1 or 4, got #{args.count})"
        end
      end

      # Rotates the image by an arbitrary angle. For angles that are not
      # multiple of 90 degrees an optional background color can be specified to
      # fill in the gaps.
      def rotate(degrees, background: nil)
        magick.background color(background) if background
        magick.rotate(degrees)
      end

      # Overlays the specified image over the current one. Supports specifying
      # an additional mask, composite mode, direction or offset of the overlay
      # image.
      def composite(overlay = :none, mask: nil, mode: nil, gravity: nil, offset: nil, args: nil, **options, &block)
        return magick.composite if overlay == :none

        if options.key?(:compose)
          warn "[IMAGE_PROCESSING] The :compose parameter in #composite has been renamed to :mode, the :compose alias will be removed in ImageProcessing 2."
          mode = options[:compose]
        end

        if options.key?(:geometry)
          warn "[IMAGE_PROCESSING] The :geometry parameter in #composite has been deprecated and will be removed in ImageProcessing 2. Use :offset instead, e.g. `geometry: \"+10+15\"` should be replaced with `offset: [10, 15]`."
          geometry = options[:geometry]
        end
        geometry = "%+d%+d" % offset if offset

        overlay_path = convert_to_path(overlay, "overlay")
        mask_path    = convert_to_path(mask, "mask") if mask

        magick << overlay_path
        magick << mask_path if mask_path

        magick.compose(mode) if mode
        define(compose: { args: args }) if args

        magick.gravity(gravity) if gravity
        magick.geometry(geometry) if geometry

        yield magick if block_given?

        magick.composite
      end

      # Defines settings from the provided hash.
      def define(options)
        return magick.define(options) if options.is_a?(String)
        Utils.apply_define(magick, options)
      end

      # Specifies resource limits from the provided hash.
      def limits(options)
        options.each { |type, value| magick.args.unshift("-limit", type.to_s, value.to_s) }
        magick
      end

      # Appends a raw ImageMagick command-line argument to the command.
      def append(*args)
        magick.merge! args
      end

      private

      # Converts the given color value into an identifier ImageMagick understands.
      # This supports specifying RGB(A) values with arrays, which mainly exists
      # for compatibility with the libvips implementation.
      def color(value)
        return "rgba(255,255,255,0.0)" if value.to_s == "transparent"
        return "rgb(#{value.join(",")})" if value.is_a?(Array) && value.count == 3
        return "rgba(#{value.join(",")})" if value.is_a?(Array) && value.count == 4
        return value if value.is_a?(String)

        raise ArgumentError, "unrecognized color format: #{value.inspect} (must be one of: string, 3-element RGB array, 4-element RGBA array)"
      end

      # Resizes the image using the specified geometry, and sharpens the
      # resulting thumbnail.
      def thumbnail(geometry, sharpen: nil)
        magick.resize(geometry)

        if sharpen
          sharpen = SHARPEN_PARAMETERS.merge(sharpen)
          magick.sharpen("#{sharpen[:radius]}x#{sharpen[:sigma]}")
        end

        magick
      end

      # Converts the image on disk in various forms into a path.
      def convert_to_path(file, name)
        if file.is_a?(String)
          file
        elsif file.respond_to?(:to_path)
          file.to_path
        elsif file.respond_to?(:path)
          file.path
        else
          raise ArgumentError, "#{name} must be a String, Pathname, or respond to #path"
        end
      end

      module Utils
        module_function

        # When a multi-layer format is being converted into a single-layer
        # format, ImageMagick will create multiple images, one for each layer.
        # We want to warn the user that this is probably not what they wanted.
        def disallow_split_layers!(destination_path)
          layers = Dir[destination_path.sub(/(\.\w+)?$/, '-*\0')]

          if layers.any?
            layers.each { |path| File.delete(path) }
            raise Error, "Source format is multi-layer, but destination format is single-layer. If you care only about the first layer, add `.loader(page: 0)` to your pipeline. If you want to process each layer, see https://github.com/janko/image_processing/wiki/Splitting-a-PDF-into-multiple-images or use `.saver(allow_splitting: true)`."
          end
        end

        # Applies options from the provided hash.
        def apply_options(magick, define: {}, **options)
          options.each do |option, value|
            case value
            when true, nil then magick.send(option)
            when false     then magick.send(option).+
            else                magick.send(option, *value)
            end
          end

          apply_define(magick, define)
        end

        # Applies settings from the provided (nested) hash.
        def apply_define(magick, options)
          options.each do |namespace, settings|
            namespace = namespace.to_s.tr("_", "-")

            settings.each do |key, value|
              key = key.to_s.tr("_", "-")

              magick.define "#{namespace}:#{key}=#{value}"
            end
          end

          magick
        end
      end
    end
  end
end
