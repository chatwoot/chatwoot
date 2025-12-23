module GLI
  module Commands
    module HelpModules
      # Given a list of two-element lists, formats on the terminal 
      class ListFormatter
        def initialize(list,wrapper_class=TextWrapper)
          @list = list
          @wrapper_class = wrapper_class
        end

        # Output the list to the output_device
        def output(output_device)
          return if @list.empty?
          max_width = @list.map { |_| _[0].length }.max
          wrapper = @wrapper_class.new(Terminal.instance.size[0],4 + max_width + 3)
          @list.each do |(name,description)|
            output_device.printf("    %-#{max_width}s - %s\n",name,wrapper.wrap(String(description).strip))
          end
        end
      end
    end
  end
end
