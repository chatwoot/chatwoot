# frozen_string_literal: true

module RuboCop
  module RSpec
    # Mixin for `expect_offense` and `expect_no_offenses`
    #
    # This mixin makes it easier to specify strict offense expectations
    # in a declarative and visual fashion. Just type out the code that
    # should generate an offense, annotate code by writing '^'s
    # underneath each character that should be highlighted, and follow
    # the carets with a string (separated by a space) that is the
    # message of the offense. You can include multiple offenses in
    # one code snippet.
    #
    # @example Usage
    #
    #     expect_offense(<<~RUBY)
    #       a do
    #         b
    #       end.c
    #       ^^^^^ Avoid chaining a method call on a do...end block.
    #     RUBY
    #
    # @example Equivalent assertion without `expect_offense`
    #
    #     inspect_source(<<~RUBY)
    #       a do
    #         b
    #       end.c
    #     RUBY
    #
    #     expect(cop.offenses.size).to be(1)
    #
    #     offense = cop.offenses.first
    #     expect(offense.line).to be(3)
    #     expect(offense.column_range).to be(0...5)
    #     expect(offense.message).to eql(
    #       'Avoid chaining a method call on a do...end block.'
    #     )
    #
    # Autocorrection can be tested using `expect_correction` after
    # `expect_offense`.
    #
    # @example `expect_offense` and `expect_correction`
    #
    #   expect_offense(<<~RUBY)
    #     x % 2 == 0
    #     ^^^^^^^^^^ Replace with `Integer#even?`.
    #   RUBY
    #
    #   expect_correction(<<~RUBY)
    #     x.even?
    #   RUBY
    #
    # If you do not want to specify an offense then use the
    # companion method `expect_no_offenses`. This method is a much
    # simpler assertion since it just inspects the source and checks
    # that there were no offenses. The `expect_offense` method has
    # to do more work by parsing out lines that contain carets.
    #
    # If the code produces an offense that could not be autocorrected, you can
    # use `expect_no_corrections` after `expect_offense`.
    #
    # @example `expect_offense` and `expect_no_corrections`
    #
    #   expect_offense(<<~RUBY)
    #     a do
    #       b
    #     end.c
    #     ^^^^^ Avoid chaining a method call on a do...end block.
    #   RUBY
    #
    #   expect_no_corrections
    #
    # If your code has variables of different lengths, you can use `%{foo}`,
    # `^{foo}`, and `_{foo}` to format your template; you can also abbreviate
    # offense messages with `[...]`:
    #
    #   %w[raise fail].each do |keyword|
    #     expect_offense(<<~RUBY, keyword: keyword)
    #       %{keyword}(RuntimeError, msg)
    #       ^{keyword}^^^^^^^^^^^^^^^^^^^ Redundant `RuntimeError` argument [...]
    #     RUBY
    #
    #   %w[has_one has_many].each do |type|
    #     expect_offense(<<~RUBY, type: type)
    #       class Book
    #         %{type} :chapter, foreign_key: 'book_id'
    #         _{type}           ^^^^^^^^^^^^^^^^^^^^^^ Specifying the default [...]
    #       end
    #     RUBY
    #   end
    #
    # If you need to specify an offense on a blank line, use the empty `^{}` marker:
    #
    # @example `^{}` empty line offense
    #
    #   expect_offense(<<~RUBY)
    #
    #     ^{} Missing frozen string literal comment.
    #     puts 1
    #   RUBY
    module ExpectOffense
      def format_offense(source, **replacements)
        replacements.each do |keyword, value|
          value = value.to_s
          source = source.gsub("%{#{keyword}}", value)
                         .gsub("^{#{keyword}}", '^' * value.size)
                         .gsub("_{#{keyword}}", ' ' * value.size)
        end
        source
      end

      # rubocop:disable Metrics/AbcSize
      def expect_offense(source, file = nil, severity: nil, chomp: false, **replacements)
        expected_annotations = parse_annotations(source, **replacements)
        source = expected_annotations.plain_source
        source = source.chomp if chomp

        @processed_source = parse_processed_source(source, file)
        @offenses = _investigate(cop, @processed_source)
        actual_annotations = expected_annotations.with_offense_annotations(@offenses)

        expect(actual_annotations).to eq(expected_annotations), ''
        expect(@offenses.map(&:severity).uniq).to eq([severity]) if severity

        # Validate that all offenses have a range that formatters can display
        expect do
          @offenses.each { |offense| offense.location.source_line }
        end.not_to raise_error, 'One of the offenses has a misconstructed range, for ' \
                                'example if the offense is on line 1 and the source is empty'

        @offenses
      end
      # rubocop:enable Metrics/AbcSize

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
      def expect_correction(correction, loop: true, source: nil)
        if source
          expected_annotations = parse_annotations(source, raise_error: false)
          @processed_source = parse_processed_source(expected_annotations.plain_source)
          _investigate(cop, @processed_source)
        end

        raise '`expect_correction` must follow `expect_offense`' unless @processed_source

        source = @processed_source.raw_source

        raise 'Use `expect_no_corrections` if the code will not change' if correction == source

        iteration = 0
        new_source = loop do
          iteration += 1

          corrected_source = @last_corrector.rewrite

          break corrected_source unless loop
          break corrected_source if @last_corrector.empty?

          if iteration > RuboCop::Runner::MAX_ITERATIONS
            raise RuboCop::Runner::InfiniteCorrectionLoop.new(@processed_source.path, [@offenses])
          end

          # Prepare for next loop
          @processed_source = parse_source(corrected_source, @processed_source.path)
          _investigate(cop, @processed_source)
        end

        raise 'Expected correction but no corrections were made' if new_source == source

        expect(new_source).to eq(correction)
        expect(@processed_source).to be_valid_syntax, 'Expected correction to be valid syntax'
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity

      def expect_no_corrections
        raise '`expect_no_corrections` must follow `expect_offense`' unless @processed_source

        return if @last_corrector.empty?

        # This is just here for a pretty diff if the source actually got changed
        new_source = @last_corrector.rewrite
        expect(new_source).to eq(@processed_source.buffer.source)

        # There is an infinite loop if a corrector is present that did not make
        # any changes. It will cause the same offense/correction on the next loop.
        raise RuboCop::Runner::InfiniteCorrectionLoop.new(@processed_source.path, [@offenses])
      end

      def expect_no_offenses(source, file = nil)
        offenses = inspect_source(source, file)

        # Since source given `expect_no_offenses` does not have annotations, we do not need to parse
        # for them, and can just build an `AnnotatedSource` object from the source lines.
        # This also prevents treating source lines that begin with a caret as an annotation.
        expected_annotations = AnnotatedSource.new(source.each_line.to_a, [])
        actual_annotations = expected_annotations.with_offense_annotations(offenses)
        expect(actual_annotations.to_s).to eq(source)
      end

      def parse_annotations(source, raise_error: true, **replacements)
        set_formatter_options

        source = format_offense(source, **replacements)
        annotations = AnnotatedSource.parse(source)
        return annotations unless raise_error && annotations.plain_source == source

        raise 'Use `expect_no_offenses` to assert that no offenses are found'
      end

      def parse_processed_source(source, file = nil)
        processed_source = parse_source(source, file)
        return processed_source if processed_source.valid_syntax?

        raise 'Error parsing example code: ' \
              "#{processed_source.diagnostics.map(&:render).join("\n")}"
      end

      def set_formatter_options
        RuboCop::Formatter::DisabledConfigFormatter.config_to_allow_offenses = {}
        RuboCop::Formatter::DisabledConfigFormatter.detected_styles = {}
        cop.instance_variable_get(:@options)[:autocorrect] = true
      end

      # Parsed representation of code annotated with the `^^^ Message` style
      class AnnotatedSource
        # Ignore escaped carets, don't treat as annotations
        ANNOTATION_PATTERN = /\A\s*((?<!\\)\^+|\^{}) ?/.freeze
        ABBREV = "[...]\n"

        # @param annotated_source [String] string passed to the matchers
        #
        # Separates annotation lines from source lines. Tracks the real
        # source line number that each annotation corresponds to.
        #
        # @return [AnnotatedSource]
        def self.parse(annotated_source)
          source      = []
          annotations = []

          annotated_source.each_line do |source_line|
            if ANNOTATION_PATTERN.match?(source_line)
              annotations << [source.size, source_line]
            else
              source << source_line
            end
          end
          annotations.each { |a| a[0] = 1 } if source.empty?

          new(source, annotations)
        end

        # @param lines [Array<String>]
        # @param annotations [Array<(Integer, String)>]
        #   each entry is the annotated line number and the annotation text
        #
        # @note annotations are sorted so that reconstructing the annotation
        #   text via {#to_s} is deterministic
        def initialize(lines, annotations)
          @lines       = lines.freeze
          @annotations = annotations.sort.freeze
        end

        def ==(other)
          other.is_a?(self.class) && other.lines == lines && match_annotations?(other)
        end

        # Dirty hack: expectations with [...] are rewritten when they match
        # This way the diff is clean.
        def match_annotations?(other)
          annotations.zip(other.annotations) do |(_actual_line, actual_annotation),
                                                 (_expected_line, expected_annotation)|
            if expected_annotation&.end_with?(ABBREV) &&
               actual_annotation.start_with?(expected_annotation[0...-ABBREV.length])

              expected_annotation.replace(actual_annotation)
            end
          end

          annotations == other.annotations
        end

        # Construct annotated source string (like what we parse)
        #
        # Reconstruct a deterministic annotated source string. This is
        # useful for eliminating semantically irrelevant annotation
        # ordering differences.
        #
        # @example standardization
        #
        #     source1 = AnnotatedSource.parse(<<-RUBY)
        #     line1
        #     ^ Annotation 1
        #      ^^ Annotation 2
        #     RUBY
        #
        #     source2 = AnnotatedSource.parse(<<-RUBY)
        #     line1
        #      ^^ Annotation 2
        #     ^ Annotation 1
        #     RUBY
        #
        #     source1.to_s == source2.to_s # => true
        #
        # @return [String]
        def to_s
          reconstructed = lines.dup

          annotations.reverse_each do |line_number, annotation|
            reconstructed.insert(line_number, annotation)
          end

          reconstructed.join
        end
        alias inspect to_s

        # Return the plain source code without annotations
        #
        # @return [String]
        def plain_source
          lines.join
        end

        # Annotate the source code with the RuboCop offenses provided
        #
        # @param offenses [Array<RuboCop::Cop::Offense>]
        #
        # @return [self]
        def with_offense_annotations(offenses)
          offense_annotations =
            offenses.map do |offense|
              indent     = ' ' * offense.column
              carets     = '^' * offense.column_length
              carets     = '^{}' if offense.column_length.zero?

              [offense.line, "#{indent}#{carets} #{offense.message}\n"]
            end

          self.class.new(lines, offense_annotations)
        end

        protected

        attr_reader :lines, :annotations
      end
    end
  end
end
