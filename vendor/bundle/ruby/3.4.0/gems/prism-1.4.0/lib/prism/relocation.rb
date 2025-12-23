# frozen_string_literal: true

module Prism
  # Prism parses deterministically for the same input. This provides a nice
  # property that is exposed through the #node_id API on nodes. Effectively this
  # means that for the same input, these values will remain consistent every
  # time the source is parsed. This means we can reparse the source same with a
  # #node_id value and find the exact same node again.
  #
  # The Relocation module provides an API around this property. It allows you to
  # "save" nodes and locations using a minimal amount of memory (just the
  # node_id and a field identifier) and then reify them later.
  module Relocation
    # An entry in a repository that will lazily reify its values when they are
    # first accessed.
    class Entry
      # Raised if a value that could potentially be on an entry is missing
      # because it was either not configured on the repository or it has not yet
      # been fetched.
      class MissingValueError < StandardError
      end

      # Initialize a new entry with the given repository.
      def initialize(repository)
        @repository = repository
        @values = nil
      end

      # Fetch the filepath of the value.
      def filepath
        fetch_value(:filepath)
      end

      # Fetch the start line of the value.
      def start_line
        fetch_value(:start_line)
      end

      # Fetch the end line of the value.
      def end_line
        fetch_value(:end_line)
      end

      # Fetch the start byte offset of the value.
      def start_offset
        fetch_value(:start_offset)
      end

      # Fetch the end byte offset of the value.
      def end_offset
        fetch_value(:end_offset)
      end

      # Fetch the start character offset of the value.
      def start_character_offset
        fetch_value(:start_character_offset)
      end

      # Fetch the end character offset of the value.
      def end_character_offset
        fetch_value(:end_character_offset)
      end

      # Fetch the start code units offset of the value, for the encoding that
      # was configured on the repository.
      def start_code_units_offset
        fetch_value(:start_code_units_offset)
      end

      # Fetch the end code units offset of the value, for the encoding that was
      # configured on the repository.
      def end_code_units_offset
        fetch_value(:end_code_units_offset)
      end

      # Fetch the start byte column of the value.
      def start_column
        fetch_value(:start_column)
      end

      # Fetch the end byte column of the value.
      def end_column
        fetch_value(:end_column)
      end

      # Fetch the start character column of the value.
      def start_character_column
        fetch_value(:start_character_column)
      end

      # Fetch the end character column of the value.
      def end_character_column
        fetch_value(:end_character_column)
      end

      # Fetch the start code units column of the value, for the encoding that
      # was configured on the repository.
      def start_code_units_column
        fetch_value(:start_code_units_column)
      end

      # Fetch the end code units column of the value, for the encoding that was
      # configured on the repository.
      def end_code_units_column
        fetch_value(:end_code_units_column)
      end

      # Fetch the leading comments of the value.
      def leading_comments
        fetch_value(:leading_comments)
      end

      # Fetch the trailing comments of the value.
      def trailing_comments
        fetch_value(:trailing_comments)
      end

      # Fetch the leading and trailing comments of the value.
      def comments
        leading_comments.concat(trailing_comments)
      end

      # Reify the values on this entry with the given values. This is an
      # internal-only API that is called from the repository when it is time to
      # reify the values.
      def reify!(values) # :nodoc:
        @repository = nil
        @values = values
      end

      private

      # Fetch a value from the entry, raising an error if it is missing.
      def fetch_value(name)
        values.fetch(name) do
          raise MissingValueError, "No value for #{name}, make sure the " \
            "repository has been properly configured"
        end
      end

      # Return the values from the repository, reifying them if necessary.
      def values
        @values || (@repository.reify!; @values)
      end
    end

    # Represents the source of a repository that will be reparsed.
    class Source
      # The value that will need to be reparsed.
      attr_reader :value

      # Initialize the source with the given value.
      def initialize(value)
        @value = value
      end

      # Reparse the value and return the parse result.
      def result
        raise NotImplementedError, "Subclasses must implement #result"
      end

      # Create a code units cache for the given encoding.
      def code_units_cache(encoding)
        result.code_units_cache(encoding)
      end
    end

    # A source that is represented by a file path.
    class SourceFilepath < Source
      # Reparse the file and return the parse result.
      def result
        Prism.parse_file(value)
      end
    end

    # A source that is represented by a string.
    class SourceString < Source
      # Reparse the string and return the parse result.
      def result
        Prism.parse(value)
      end
    end

    # A field that represents the file path.
    class FilepathField
      # The file path that this field represents.
      attr_reader :value

      # Initialize a new field with the given file path.
      def initialize(value)
        @value = value
      end

      # Fetch the file path.
      def fields(_value)
        { filepath: value }
      end
    end

    # A field representing the start and end lines.
    class LinesField
      # Fetches the start and end line of a value.
      def fields(value)
        { start_line: value.start_line, end_line: value.end_line }
      end
    end

    # A field representing the start and end byte offsets.
    class OffsetsField
      # Fetches the start and end byte offset of a value.
      def fields(value)
        { start_offset: value.start_offset, end_offset: value.end_offset }
      end
    end

    # A field representing the start and end character offsets.
    class CharacterOffsetsField
      # Fetches the start and end character offset of a value.
      def fields(value)
        {
          start_character_offset: value.start_character_offset,
          end_character_offset: value.end_character_offset
        }
      end
    end

    # A field representing the start and end code unit offsets.
    class CodeUnitOffsetsField
      # A pointer to the repository object that is used for lazily creating a
      # code units cache.
      attr_reader :repository

      # The associated encoding for the code units.
      attr_reader :encoding

      # Initialize a new field with the associated repository and encoding.
      def initialize(repository, encoding)
        @repository = repository
        @encoding = encoding
        @cache = nil
      end

      # Fetches the start and end code units offset of a value for a particular
      # encoding.
      def fields(value)
        {
          start_code_units_offset: value.cached_start_code_units_offset(cache),
          end_code_units_offset: value.cached_end_code_units_offset(cache)
        }
      end

      private

      # Lazily create a code units cache for the associated encoding.
      def cache
        @cache ||= repository.code_units_cache(encoding)
      end
    end

    # A field representing the start and end byte columns.
    class ColumnsField
      # Fetches the start and end byte column of a value.
      def fields(value)
        { start_column: value.start_column, end_column: value.end_column }
      end
    end

    # A field representing the start and end character columns.
    class CharacterColumnsField
      # Fetches the start and end character column of a value.
      def fields(value)
        {
          start_character_column: value.start_character_column,
          end_character_column: value.end_character_column
        }
      end
    end

    # A field representing the start and end code unit columns for a specific
    # encoding.
    class CodeUnitColumnsField
      # The repository object that is used for lazily creating a code units
      # cache.
      attr_reader :repository

      # The associated encoding for the code units.
      attr_reader :encoding

      # Initialize a new field with the associated repository and encoding.
      def initialize(repository, encoding)
        @repository = repository
        @encoding = encoding
        @cache = nil
      end

      # Fetches the start and end code units column of a value for a particular
      # encoding.
      def fields(value)
        {
          start_code_units_column: value.cached_start_code_units_column(cache),
          end_code_units_column: value.cached_end_code_units_column(cache)
        }
      end

      private

      # Lazily create a code units cache for the associated encoding.
      def cache
        @cache ||= repository.code_units_cache(encoding)
      end
    end

    # An abstract field used as the parent class of the two comments fields.
    class CommentsField
      # An object that represents a slice of a comment.
      class Comment
        # The slice of the comment.
        attr_reader :slice

        # Initialize a new comment with the given slice.
        def initialize(slice)
          @slice = slice
        end
      end

      private

      # Create comment objects from the given values.
      def comments(values)
        values.map { |value| Comment.new(value.slice) }
      end
    end

    # A field representing the leading comments.
    class LeadingCommentsField < CommentsField
      # Fetches the leading comments of a value.
      def fields(value)
        { leading_comments: comments(value.leading_comments) }
      end
    end

    # A field representing the trailing comments.
    class TrailingCommentsField < CommentsField
      # Fetches the trailing comments of a value.
      def fields(value)
        { trailing_comments: comments(value.trailing_comments) }
      end
    end

    # A repository is a configured collection of fields and a set of entries
    # that knows how to reparse a source and reify the values.
    class Repository
      # Raised when multiple fields of the same type are configured on the same
      # repository.
      class ConfigurationError < StandardError
      end

      # The source associated with this repository. This will be either a
      # SourceFilepath (the most common use case) or a SourceString.
      attr_reader :source

      # The fields that have been configured on this repository.
      attr_reader :fields

      # The entries that have been saved on this repository.
      attr_reader :entries

      # Initialize a new repository with the given source.
      def initialize(source)
        @source = source
        @fields = {}
        @entries = Hash.new { |hash, node_id| hash[node_id] = {} }
      end

      # Create a code units cache for the given encoding from the source.
      def code_units_cache(encoding)
        source.code_units_cache(encoding)
      end

      # Configure the filepath field for this repository and return self.
      def filepath
        raise ConfigurationError, "Can only specify filepath for a filepath source" unless source.is_a?(SourceFilepath)
        field(:filepath, FilepathField.new(source.value))
      end

      # Configure the lines field for this repository and return self.
      def lines
        field(:lines, LinesField.new)
      end

      # Configure the offsets field for this repository and return self.
      def offsets
        field(:offsets, OffsetsField.new)
      end

      # Configure the character offsets field for this repository and return
      # self.
      def character_offsets
        field(:character_offsets, CharacterOffsetsField.new)
      end

      # Configure the code unit offsets field for this repository for a specific
      # encoding and return self.
      def code_unit_offsets(encoding)
        field(:code_unit_offsets, CodeUnitOffsetsField.new(self, encoding))
      end

      # Configure the columns field for this repository and return self.
      def columns
        field(:columns, ColumnsField.new)
      end

      # Configure the character columns field for this repository and return
      # self.
      def character_columns
        field(:character_columns, CharacterColumnsField.new)
      end

      # Configure the code unit columns field for this repository for a specific
      # encoding and return self.
      def code_unit_columns(encoding)
        field(:code_unit_columns, CodeUnitColumnsField.new(self, encoding))
      end

      # Configure the leading comments field for this repository and return
      # self.
      def leading_comments
        field(:leading_comments, LeadingCommentsField.new)
      end

      # Configure the trailing comments field for this repository and return
      # self.
      def trailing_comments
        field(:trailing_comments, TrailingCommentsField.new)
      end

      # Configure both the leading and trailing comment fields for this
      # repository and return self.
      def comments
        leading_comments.trailing_comments
      end

      # This method is called from nodes and locations when they want to enter
      # themselves into the repository. It it internal-only and meant to be
      # called from the #save* APIs.
      def enter(node_id, field_name) # :nodoc:
        entry = Entry.new(self)
        @entries[node_id][field_name] = entry
        entry
      end

      # This method is called from the entries in the repository when they need
      # to reify their values. It is internal-only and meant to be called from
      # the various value APIs.
      def reify! # :nodoc:
        result = source.result

        # Attach the comments if they have been requested as part of the
        # configuration of this repository.
        if fields.key?(:leading_comments) || fields.key?(:trailing_comments)
          result.attach_comments!
        end

        queue = [result.value] #: Array[Prism::node]
        while (node = queue.shift)
          @entries[node.node_id].each do |field_name, entry|
            value = node.public_send(field_name)
            values = {} #: Hash[Symbol, untyped]

            fields.each_value do |field|
              values.merge!(field.fields(value))
            end

            entry.reify!(values)
          end

          queue.concat(node.compact_child_nodes)
        end

        @entries.clear
      end

      private

      # Append the given field to the repository and return the repository so
      # that these calls can be chained.
      def field(name, value)
        raise ConfigurationError, "Cannot specify multiple #{name} fields" if @fields.key?(name)
        @fields[name] = value
        self
      end
    end

    # Create a new repository for the given filepath.
    def self.filepath(value)
      Repository.new(SourceFilepath.new(value))
    end

    # Create a new repository for the given string.
    def self.string(value)
      Repository.new(SourceString.new(value))
    end
  end
end
