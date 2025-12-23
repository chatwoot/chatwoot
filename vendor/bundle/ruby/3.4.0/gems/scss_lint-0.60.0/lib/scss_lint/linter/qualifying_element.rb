module SCSSLint
  # Checks for element selectors qualifying id, classes, or attribute selectors.
  class Linter::QualifyingElement < Linter
    include LinterRegistry

    def visit_simple_sequence(seq)
      return unless seq_contains_sel_class?(seq, Sass::Selector::Element)
      check_id(seq) unless config['allow_element_with_id']
      check_class(seq) unless config['allow_element_with_class']
      check_attribute(seq) unless config['allow_element_with_attribute']
    end

  private

    # Checks if a simple sequence contains a
    # simple selector of a certain class.
    #
    # @param seq [Sass::Selector::SimpleSequence]
    # @param selector_class [Sass::Selector::Simple]
    # @returns [Boolean]
    def seq_contains_sel_class?(seq, selector_class)
      seq.members.any? do |simple|
        simple.is_a?(selector_class)
      end
    end

    def check_id(seq)
      return unless seq_contains_sel_class?(seq, Sass::Selector::Id)
      add_lint(seq.line, 'Avoid qualifying id selectors with an element.')
    end

    def check_class(seq)
      return unless seq_contains_sel_class?(seq, Sass::Selector::Class)
      add_lint(seq.line, 'Avoid qualifying class selectors with an element.')
    end

    def check_attribute(seq)
      return unless seq_contains_sel_class?(seq, Sass::Selector::Attribute)
      add_lint(seq.line, 'Avoid qualifying attribute selectors with an element.')
    end
  end
end
