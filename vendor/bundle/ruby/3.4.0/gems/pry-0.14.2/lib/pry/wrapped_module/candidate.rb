# frozen_string_literal: true

class Pry
  class WrappedModule
    # This class represents a single candidate for a module/class definition.
    # It provides access to the source, documentation, line and file
    # for a monkeypatch (reopening) of a class/module.
    class Candidate
      include Pry::Helpers::DocumentationHelpers
      include Pry::CodeObject::Helpers
      extend Pry::Forwardable

      # @return [String] The file where the module definition is located.
      attr_reader :file
      alias source_file file

      # @return [Fixnum] The line where the module definition is located.
      attr_reader :line
      alias source_line line

      # Methods to delegate to associated `Pry::WrappedModule
      # instance`.
      private_delegates = %i[lines_for_file method_candidates yard_docs? name]
      public_delegates = %i[wrapped module? class? nonblank_name
                            number_of_candidates]

      def_delegators :@wrapper, *public_delegates
      def_private_delegators :@wrapper, *private_delegates

      # @raise [Pry::CommandError] If `rank` is out of bounds.
      # @param [Pry::WrappedModule] wrapper The associated
      #   `Pry::WrappedModule` instance that owns the candidates.
      # @param [Fixnum] rank The rank of the candidate to
      #   retrieve. Passing 0 returns 'primary candidate' (the candidate with largest
      #   number of methods), passing 1 retrieves candidate with
      #   second largest number of methods, and so on, up to
      #   `Pry::WrappedModule#number_of_candidates() - 1`
      def initialize(wrapper, rank)
        @wrapper = wrapper

        if number_of_candidates <= 0
          raise CommandError, "Cannot find a definition for #{name} module!"
        end

        if rank > (number_of_candidates - 1)
          raise CommandError,
                "No such module candidate. Allowed candidates range is " \
                "from 0 to #{number_of_candidates - 1}"
        end

        @source = @source_location = nil
        @rank = rank
        @file, @line = source_location
      end

      # @raise [Pry::CommandError] If source code cannot be found.
      # @return [String] The source for the candidate, i.e the
      #   complete module/class definition.
      def source
        return nil if file.nil?
        return @source if @source

        @source ||= strip_leading_whitespace(
          Pry::Code.from_file(file).expression_at(line, number_of_lines_in_first_chunk)
        )
      end

      # @raise [Pry::CommandError] If documentation cannot be found.
      # @return [String] The documentation for the candidate.
      def doc
        return nil if file.nil?

        @doc ||= get_comment_content(Pry::Code.from_file(file).comment_describing(line))
      end

      # @return [Array, nil] A `[String, Fixnum]` pair representing the
      #   source location (file and line) for the candidate or `nil`
      #   if no source location found.
      def source_location
        return @source_location if @source_location

        file, line = first_method_source_location
        return nil unless file.is_a?(String)

        @source_location = [file, first_line_of_module_definition(file, line)]
      rescue Pry::RescuableException
        nil
      end

      private

      # Locate the first line of the module definition.
      # @param [String] file The file that contains the module
      #   definition (somewhere).
      # @param [Fixnum] line The module definition should appear
      #   before this line (if it exists).
      # @return [Fixnum] The line where the module is defined. This
      #   line number is one-indexed.
      def first_line_of_module_definition(file, line)
        searchable_lines = lines_for_file(file)[0..(line - 2)]
        searchable_lines.rindex { |v| module_definition_first_line?(v) } + 1
      end

      def module_definition_first_line?(line)
        mod_type_string = wrapped.class.to_s.downcase
        wrapped_name_last = wrapped.name.split(/::/).last
        /(^|=)\s*#{mod_type_string}\s+(?:(?:\w*)::)*?#{wrapped_name_last}/ =~ line ||
          /^\s*(::)?#{wrapped_name_last}\s*?=\s*?#{wrapped.class}/ =~ line ||
          /^\s*(::)?#{wrapped_name_last}\.(class|instance)_eval/ =~ line
      end

      # This method is used by `Candidate#source_location` as a
      # starting point for the search for the candidate's definition.
      # @return [Array] The source location of the base method used to
      #   calculate the source location of the candidate.
      def first_method_source_location
        @first_method_source_location ||= method_candidates[@rank].first.source_location
      end

      # @return [Array] The source location of the last method in this
      #   candidate's module definition.
      def last_method_source_location
        @last_method_source_location ||= method_candidates[@rank].last.source_location
      end

      # Return the number of lines between the start of the class definition and
      # the start of the last method. We use this value so we can quickly grab
      # these lines from the file (without having to check each intervening line
      # for validity, which is expensive) speeding up source extraction.
      #
      # @return [Integer] number of lines.
      def number_of_lines_in_first_chunk
        end_method_line = last_method_source_location.last

        end_method_line - line
      end
    end
  end
end
