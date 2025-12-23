module MiniMagick
  class Tool
    ##
    # @see http://www.imagemagick.org/script/import.php
    #
    class Import < MiniMagick::Tool

      def initialize(*args)
        super("import", *args)
      end

    end
  end
end
