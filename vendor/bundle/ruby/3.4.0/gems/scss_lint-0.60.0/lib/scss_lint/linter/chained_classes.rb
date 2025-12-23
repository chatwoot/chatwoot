module SCSSLint
  # Checks for uses of chained classes (e.g. .foo.bar).
  class Linter::ChainedClasses < Linter
    include LinterRegistry

    def visit_sequence(sequence)
      line_offset = 0
      sequence.members.each do |member|
        line_offset += 1 if member.to_s =~ /\n/
        next unless chained_class?(member)
        add_lint(member.line + line_offset,
                 'Prefer using a distinct class over chained classes ' \
                 '(e.g. .new-class over .foo.bar')
      end
    end

  private

    def chained_class?(simple_sequence)
      return unless simple_sequence.is_a?(Sass::Selector::SimpleSequence)
      simple_sequence.members.count { |member| member.is_a?(Sass::Selector::Class) } >= 2
    end
  end
end
