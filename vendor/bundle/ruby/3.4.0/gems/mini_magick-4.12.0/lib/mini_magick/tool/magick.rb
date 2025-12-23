module MiniMagick
  class Tool
    ##
    # @see http://www.imagemagick.org/script/command-line-processing.php
    #
    class Magick < MiniMagick::Tool

      def initialize(*args)
        super("magick", *args)
      end

    end
  end
end
