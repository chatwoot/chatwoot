module MiniMagick
  class Tool
    ##
    # @see http://www.imagemagick.org/script/display.php
    #
    class Display < MiniMagick::Tool

      def initialize(*args)
        super("display", *args)
      end

    end
  end
end
