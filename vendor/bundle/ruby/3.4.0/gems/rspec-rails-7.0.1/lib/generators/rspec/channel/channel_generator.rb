require 'generators/rspec'

module Rspec
  module Generators
    # @private
    class ChannelGenerator < Base
      def create_channel_spec
        template 'channel_spec.rb.erb', target_path('channels', class_path, "#{file_name}_channel_spec.rb")
      end
    end
  end
end
