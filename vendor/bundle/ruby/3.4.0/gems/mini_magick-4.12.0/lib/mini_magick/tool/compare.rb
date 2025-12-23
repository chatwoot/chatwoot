module MiniMagick
  class Tool
    ##
    # @see http://www.imagemagick.org/script/compare.php
    #
    class Compare < MiniMagick::Tool

      def initialize(*args)
        super("compare", *args)
      end

    end
  end
end
