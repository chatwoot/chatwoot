module MiniMagick
  class Tool
    ##
    # @see http://www.imagemagick.org/script/montage.php
    #
    class Montage < MiniMagick::Tool

      def initialize(*args)
        super("montage", *args)
      end

    end
  end
end
