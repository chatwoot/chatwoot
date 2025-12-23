# frozen_string_literal: true

module RuboCop
  module Rails
    # It loads db/schema.rb and return Schema object.
    # Cops refers database schema information with this module.
    module SchemaLoader
      extend self

      # It parses `db/schema.rb` and return it.
      # It returns `nil` if it can't find `db/schema.rb`.
      # So a cop that uses the loader should handle `nil` properly.
      #
      # @return [Schema, nil]
      def load(target_ruby_version, parser_engine)
        return @load if defined?(@load)

        @load = load!(target_ruby_version, parser_engine)
      end

      def reset!
        return unless instance_variable_defined?(:@load)

        remove_instance_variable(:@load)
      end

      def db_schema_path
        path = Pathname.pwd
        until path.root?
          schema_path = path.join('db/schema.rb')
          return schema_path if schema_path.exist?

          path = path.join('../').cleanpath
        end

        nil
      end

      private

      def load!(target_ruby_version, parser_engine)
        path = db_schema_path
        return unless path

        ast = RuboCop::ProcessedSource.new(File.read(path), target_ruby_version, path, parser_engine: parser_engine).ast

        Schema.new(ast) if ast
      end
    end
  end
end
