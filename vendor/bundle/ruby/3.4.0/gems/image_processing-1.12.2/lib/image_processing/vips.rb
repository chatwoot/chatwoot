require "vips"
require "image_processing"

fail "image_processing/vips requires libvips 8.6+" unless Vips.at_least_libvips?(8, 6)

module ImageProcessing
  module Vips
    extend Chainable

    # Returns whether the given image file is processable.
    def self.valid_image?(file)
      ::Vips::Image.new_from_file(file.path, access: :sequential).avg
      true
    rescue ::Vips::Error
      false
    end

    class Processor < ImageProcessing::Processor
      accumulator :image, ::Vips::Image

      # Default sharpening mask that provides a fast and mild sharpen.
      SHARPEN_MASK = ::Vips::Image.new_from_array [[-1, -1, -1],
                                                   [-1, 32, -1],
                                                   [-1, -1, -1]], 24


      # Loads the image on disk into a Vips::Image object. Accepts additional
      # loader-specific options (e.g. interlacing). Afterwards auto-rotates the
      # image to be upright.
      def self.load_image(path_or_image, loader: nil, autorot: true, **options)
        if path_or_image.is_a?(::Vips::Image)
          image = path_or_image
        else
          path = path_or_image

          if loader
            image = ::Vips::Image.public_send(:"#{loader}load", path, **options)
          else
            options = Utils.select_valid_loader_options(path, options)
            image = ::Vips::Image.new_from_file(path, **options)
          end
        end

        image = image.autorot if autorot && !options.key?(:autorotate)
        image
      end

      # See #thumbnail.
      def self.supports_resize_on_load?
        true
      end

      # Writes the Vips::Image object to disk. This starts the processing
      # pipeline defined in the Vips::Image object. Accepts additional
      # saver-specific options (e.g. quality).
      def self.save_image(image, path, saver: nil, quality: nil, **options)
        options[:Q] = quality if quality

        if saver
          image.public_send(:"#{saver}save", path, **options)
        else
          options = Utils.select_valid_saver_options(path, options)
          image.write_to_file(path, **options)
        end
      end

      # Resizes the image to not be larger than the specified dimensions.
      def resize_to_limit(width, height, **options)
        width, height = default_dimensions(width, height)
        thumbnail(width, height, size: :down, **options)
      end

      # Resizes the image to fit within the specified dimensions.
      def resize_to_fit(width, height, **options)
        width, height = default_dimensions(width, height)
        thumbnail(width, height, **options)
      end

      # Resizes the image to fill the specified dimensions, applying any
      # necessary cropping.
      def resize_to_fill(width, height, **options)
        thumbnail(width, height, crop: :centre, **options)
      end

      # Resizes the image to fit within the specified dimensions and fills
      # the remaining area with the specified background color.
      def resize_and_pad(width, height, gravity: "centre", extend: nil, background: nil, alpha: nil, **options)
        image = thumbnail(width, height, **options)
        image = image.add_alpha if alpha && !image.has_alpha?
        image.gravity(gravity, width, height, extend: extend, background: background)
      end

      # Rotates the image by an arbitrary angle.
      def rotate(degrees, **options)
        image.similarity(angle: degrees, **options)
      end

      # Overlays the specified image over the current one. Supports specifying
      # composite mode, direction or offset of the overlay image.
      def composite(overlay, _mode = nil, mode: "over", gravity: "north-west", offset: nil, **options)
        # if the mode argument is given, call the original Vips::Image#composite
        if _mode
          overlay = [overlay] unless overlay.is_a?(Array)
          overlay = overlay.map { |object| convert_to_image(object, "overlay") }

          return image.composite(overlay, _mode, **options)
        end

        overlay = convert_to_image(overlay, "overlay")
        # add alpha channel so that #gravity can use a transparent background
        overlay = overlay.add_alpha unless overlay.has_alpha?

        # apply offset with correct gravity and make remainder transparent
        if offset
          opposite_gravity = gravity.to_s.gsub(/\w+/, "north"=>"south", "south"=>"north", "east"=>"west", "west"=>"east")
          overlay = overlay.gravity(opposite_gravity, overlay.width + offset.first, overlay.height + offset.last)
        end

        # create image-sized transparent background and apply specified gravity
        overlay = overlay.gravity(gravity, image.width, image.height)

        # apply the composition
        image.composite(overlay, mode, **options)
      end

      # make metadata setter methods chainable
      def set(*args)       image.tap { |img| img.set(*args) }       end
      def set_type(*args)  image.tap { |img| img.set_type(*args) }  end
      def set_value(*args) image.tap { |img| img.set_value(*args) } end
      def remove(*args)    image.tap { |img| img.remove(*args) }    end

      private

      # Resizes the image according to the specified parameters, and sharpens
      # the resulting thumbnail.
      def thumbnail(width, height, sharpen: SHARPEN_MASK, **options)
        if self.image.is_a?(String) # path
          # resize on load
          image = ::Vips::Image.thumbnail(self.image, width, height: height, **options)
        else
          # we're already calling Image#autorot when loading the image
          no_rotate = ::Vips.at_least_libvips?(8, 8) ? { no_rotate: true } : { auto_rotate: false }
          options   = no_rotate.merge(options)

          image = self.image.thumbnail_image(width, height: height, **options)
        end

        image = image.conv(sharpen, precision: :integer) if sharpen
        image
      end

      # Hack to allow omitting one dimension.
      def default_dimensions(width, height)
        raise Error, "either width or height must be specified" unless width || height

        [width || ::Vips::MAX_COORD, height || ::Vips::MAX_COORD]
      end

      # Converts the image on disk in various forms into a Vips::Image object.
      def convert_to_image(object, name)
        return object if object.is_a?(::Vips::Image)

        if object.is_a?(String)
          path = object
        elsif object.respond_to?(:to_path)
          path = object.to_path
        elsif object.respond_to?(:path)
          path = object.path
        else
          raise ArgumentError, "#{name} must be a Vips::Image, String, Pathname, or respond to #path"
        end

        ::Vips::Image.new_from_file(path)
      end

      module Utils
        module_function

        # libvips uses various loaders depending on the input format.
        def select_valid_loader_options(source_path, options)
          loader = ::Vips.vips_foreign_find_load(source_path)
          loader ? select_valid_options(loader, options) : options
        end

        # Filters out unknown options for saving images.
        def select_valid_saver_options(destination_path, options)
          saver = ::Vips.vips_foreign_find_save(destination_path)
          saver ? select_valid_options(saver, options) : options
        end

        # libvips uses various loaders and savers depending on the input and
        # output image format. Each of these loaders and savers accept slightly
        # different options, so to allow the user to be able to specify options
        # for a specific loader/saver and have it ignored for other
        # loaders/savers, we do some introspection and filter out options that
        # don't exist for a particular loader or saver.
        def select_valid_options(operation_name, options)
          introspect        = ::Vips::Introspect.get(operation_name)
          operation_options = introspect.optional_input.keys.map(&:to_sym)

          options.select { |name, value| operation_options.include?(name) }
        end
      end
    end
  end
end
