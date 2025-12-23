module MiniMagick
  class Tool
    ##
    # @see http://www.imagemagick.org/script/mogrify.php
    #
    class Mogrify < MiniMagick::Tool

      def initialize(*args)
        super("mogrify", *args)
      end

    end
  end
end
