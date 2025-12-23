module MiniMagick
  class Tool
    ##
    # @see http://www.imagemagick.org/script/animate.php
    #
    class Animate < MiniMagick::Tool

      def initialize(*args)
        super("animate", *args)
      end

    end
  end
end
