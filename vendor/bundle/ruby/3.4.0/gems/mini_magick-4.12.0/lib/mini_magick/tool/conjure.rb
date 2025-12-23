module MiniMagick
  class Tool
    ##
    # @see http://www.imagemagick.org/script/conjure.php
    #
    class Conjure < MiniMagick::Tool

      def initialize(*args)
        super("conjure", *args)
      end

    end
  end
end
