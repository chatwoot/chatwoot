module MiniMagick
  class Tool
    ##
    # @see http://www.imagemagick.org/script/stream.php
    #
    class Stream < MiniMagick::Tool

      def initialize(*args)
        super("stream", *args)
      end

    end
  end
end
