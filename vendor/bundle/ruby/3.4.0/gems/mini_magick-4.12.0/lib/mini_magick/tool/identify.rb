module MiniMagick
  class Tool
    ##
    # @see http://www.imagemagick.org/script/identify.php
    #
    class Identify < MiniMagick::Tool

      def initialize(*args)
        super("identify", *args)
      end

    end
  end
end
