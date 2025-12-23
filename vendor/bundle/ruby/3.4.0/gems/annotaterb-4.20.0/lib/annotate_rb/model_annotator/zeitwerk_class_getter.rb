# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    class ZeitwerkClassGetter
      class << self
        def call(file, options)
          new(file, options).call
        end
      end

      def initialize(file, options)
        @file = file
        @options = options
      end

      # @return [Constant, nil] Attempts to return the model class constant (e.g. User) defined in the model file
      #   can return `nil` if the file does not define the constant.
      def call
        return unless defined?(::Zeitwerk)

        @absolute_file_path = File.expand_path(@file)
        loader = ::Rails.autoloaders.main

        if supports_cpath?
          constant_using_cpath(loader)
        else
          constant(loader)
        end
      end

      private

      def constant(loader)
        root_dirs = loader.dirs(namespaces: true) # or `root_dirs = loader.root_dirs` with zeitwerk < 2.6.1
        expanded_file = @absolute_file_path

        # root_dir: "/home/dummyapp/app/models"
        root_dir, namespace = root_dirs.find do |dir, _namespace|
          expanded_file.start_with?(dir)
        end

        # expanded_file: "/home/dummyapp/app/models/collapsed/example/test_model.rb"
        # filepath_relative_to_root_dir: "/collapsed/example/test_model.rb"
        _, filepath_relative_to_root_dir = expanded_file.split(root_dir)

        # Remove leading / and the .rb extension
        filepath_relative_to_root_dir = filepath_relative_to_root_dir[1..].sub(/\.rb$/, "")

        # once we have the filepath_relative_to_root_dir, we need to see if it
        # falls within one of our Zeitwerk "collapsed" paths.
        if loader.collapse.any? { |path| path.include?(root_dir) && file.include?(path.split(root_dir)[1]) }
          # if the file is within a collapsed path, we then need to, for each
          # collapsed path, remove the root dir
          collapsed = loader.collapse.map { |path| path.split(root_dir)[1].sub(/^\//, "") }.to_set

          collapsed.each do |collapse|
            # next, we split the collapsed directory, e.g. `domain_name/models`, by
            # slash, and discard the domain_name
            _, *collapsed_namespace = collapse.split("/")

            # if there are any collapsed namespaces, e.g. `models`, we then remove
            # that from `filepath_relative_to_root_dir`.
            #
            # This would result in:
            #
            # previous filepath_relative_to_root_dir: domain_name/models/model_name
            # new filepath_relative_to_root_dir: domain_name/model_name
            if collapsed_namespace.any?
              filepath_relative_to_root_dir.sub!("/#{collapsed_namespace.last}", "")
            end
          end
        end

        camelize = loader.inflector.camelize(filepath_relative_to_root_dir, nil)
        namespace.const_get(camelize)
      rescue NameError => e
        warn e
        nil
      end

      def constant_using_cpath(loader)
        begin
          constant = loader.cpath_expected_at(@absolute_file_path)
        rescue ::Zeitwerk::Error => e
          # Raises when file does not exist
          warn "Zeitwerk unable to find file #{@file}, error:\n#{e.message}"
          return
        end

        begin
          # This uses ActiveSupport::Inflector.constantize
          klass = constant.constantize
        rescue NameError => e
          warn e
          return
        end

        klass
      end

      def supports_cpath?
        @supports_cpath ||=
          begin
            current_version = ::Gem::Version.new(::Zeitwerk::VERSION)
            required_version = ::Gem::Version.new("2.6.9")

            current_version >= required_version
          end
      end
    end
  end
end
