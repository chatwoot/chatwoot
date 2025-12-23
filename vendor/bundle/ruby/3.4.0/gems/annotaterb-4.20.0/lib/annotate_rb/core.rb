# frozen_string_literal: true

module AnnotateRb
  module Core
    class << self
      def version
        @version ||= File.read(File.expand_path("../../VERSION", __dir__)).strip
      end

      def load_rake_tasks
        return if @load_rake_tasks

        rake_tasks = Dir[File.join(File.dirname(__FILE__), "tasks", "**/*.rake")]

        rake_tasks.each do |task|
          load task
        end

        @load_rake_tasks = true
      end
    end
  end
end
