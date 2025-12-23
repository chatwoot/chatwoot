module ScoutApm
  module Utils
    module KlassHelper
      # KlassHelper.defined?("ActiveRecord", "Base") #=> true / false
      # KlassHelper.defined?("ActiveRecord::Base")   #=> true / false

      def self.defined?(*names)
        lookup(*names) != :missing_class
      end

      # KlassHelper.lookup("ActiveRecord::Base") => ActiveRecord::Base
      # KlassHelper.lookup("ActiveRecord::SomethingThatDoesNotExist") => :missing_class
      def self.lookup(*names)
        if names.length == 1
          names = names[0].split("::")
        end

        obj = Object

        names.each do |name|
          begin
            obj = obj.const_get(name)
          rescue NameError
            return :missing_class
          end
        end

        obj
      end
    end
  end
end
