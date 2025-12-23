require 'generators/rspec'

module Rspec
  module Generators
    # @private
    class JobGenerator < Base
      def create_job_spec
        file_suffix = file_name.end_with?('job') ? 'spec.rb' : 'job_spec.rb'
        template 'job_spec.rb.erb', target_path('jobs', class_path, [file_name, file_suffix].join('_'))
      end
    end
  end
end
