module MiniMagick
  class Tool
    ##
    # @see http://www.imagemagick.org/script/composite.php
    #
    class Composite < MiniMagick::Tool

      def initialize(*args)
        super("composite", *args)
      end

    end
  end
end
