require 'spec_helper'

describe SCSSLint::Linter do
  describe 'control comments' do
    let(:linter_config) { {} }
    subject             { SCSSLint::Linter::Fake.new }

    module SCSSLint
      class Linter::Fake < SCSSLint::Linter
        def visit_root(_node)
          add_lint(engine.lines.count, 'final new line') unless engine.lines[-1][-1] == "\n"
          yield
        end

        def visit_prop(node)
          return unless node.value.first.to_sass.strip == 'fail1'
          add_lint(node, 'everything offends me')
        end

        def visit_class(klass)
          return unless klass.to_s == '.badClass'
          add_lint(klass, 'a bad class was used')
        end

        # Bypasses the visit order so a control comment might not be reached before a lint is
        # added
        def visit_rule(node)
          node.children
              .select { |child| child.is_a?(Sass::Tree::PropNode) }
              .reject { |prop| prop.name.any? { |item| item.is_a?(Sass::Script::Node) } }
              .each do |prop|
                add_lint(prop, 'everything offends me 2') if prop.value.first.to_sass.strip == 'fail2'
              end

          yield
        end
      end
    end

    context 'when a disable is not present' do
      let(:scss) { <<-SCSS }
        p {
          border: fail1;

          a {
            border: fail1;
          }
        }
      SCSS

      it { should report_lint }
    end

    context 'when a disable is present at the top level' do
      let(:scss) { <<-SCSS.strip }
        // scss-lint:disable Fake
        p {
          border: fail1;

          a {
            border: fail1;
          }
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when a disable is present at the top level for another linter' do
      let(:scss) { <<-SCSS }
        // scss-lint:disable Bogus
        p {
          border: fail1;
        }
        p {
          border: bogus;
        }
      SCSS

      it { should report_lint lint: 3 }
    end

    context 'when a linter is disabled then enabled again' do
      let(:scss) { <<-SCSS }
        // scss-lint:disable Fake
        p {
          border: fail1;
        }
        // scss-lint:enable Fake
        p {
          border: fail1;
        }
      SCSS

      it { should_not report_lint line: 3 }
      it { should report_lint line: 7 }
    end

    context 'when a linter is disabled within a rule' do
      let(:scss) { <<-SCSS }
        p {
          // scss-lint:disable Fake
          border: fail1;

          a {
            border: fail1;
          }
        }

        p {
          border: fail1;
        }
      SCSS

      it { should_not report_lint line: 3 }
      it { should_not report_lint line: 6 }
      it { should report_lint line: 11 }
    end

    context 'when more than one linter is disabled' do
      let(:scss) { <<-SCSS }
        // scss-lint:disable Bogus, Fake
        p {
          border: fail1;
        }

        p {
          border: bogus;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when more than one linter is disabled without spaces between the linter names' do
      let(:scss) { <<-SCSS }
        // scss-lint:disable Fake,Bogus
        p {
          border: fail1;
        }

        p {
          border: Bogus;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when more than one linter is disabled without commas between the linter names' do
      let(:scss) { <<-SCSS }
        // scss-lint:disable Fake Bogus
        p {
          border: fail1;
        }

        p {
          border: bogus;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when two linters are disabled and only one is reenabled' do
      let(:scss) { <<-SCSS }
        // scss-lint:disable Fake, Bogus
        p {
          border: fail1;
        }
        // scss-lint:enable Fake

        p {
          margin: fail1;
          border: bogus;
        }
      SCSS

      it { should_not report_lint line: 3 }
      it { should report_lint line: 8 }
    end

    context 'when all linters are disabled' do
      let(:scss) { <<-SCSS }
        // scss-lint:disable all
        p {
          border: fail1;
        }

        p {
          margin: fail1;
          border: bogus;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when all linters are disabled and then one is re-enabled' do
      let(:scss) { <<-SCSS }
        // scss-lint:disable all
        p {
          border: fail1;
        }
        // scss-lint:enable Fake

        p {
          margin: fail1;
          border: bogus;
        }
      SCSS

      it { should_not report_lint line: 3 }
      it { should report_lint line: 8 }
    end

    context 'when a linter is bypassing the visit tree order' do
      let(:scss) { <<-SCSS }
        p {
          // scss-lint:disable Fake
          border: fail2;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when the command comment is next to other comments' do
      let(:scss) { <<-SCSS }
        p {
          // scss-lint:disable Fake
          // more comments
          border: fail2;
        }

        p {
          // more comments
          // scss-lint:disable Fake
          border: fail2;
        }

        p {
          background: red; // [1]
          //scss-lint:disable Fake
          border: fail2;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when there are multiple consecutive command comments' do
      let(:scss) { <<-SCSS }
        // scss-lint:disable Fake
        // scss-lint:disable Fake2
        p {
          border: fail1;
        }
      SCSS

      it { should_not report_lint }

      it 'disabled both linters' do
        class SCSSLint::Linter::Fake2 < SCSSLint::Linter::Fake; end
        SCSSLint::Linter::Fake2.new.should_not report_lint
      end
    end

    context 'when the command comment is below an attached comment and a lint' do
      let(:scss) { <<-SCSS }
        // 1. Some comment about my background
        .foo {
          background: fail1; // [1]
          // scss-lint:disable Fake
          border: fail1
          // scss-lint:enable Fake
        }
      SCSS

      it { should report_lint line: 3 }
      it { should_not report_lint line: 5 }
    end

    context 'when the command comment is at the end of a statement' do
      let(:scss) { <<-SCSS }
        p {
          border: fail1; // scss-lint:disable Fake
          border: fail1;
        }
      SCSS

      it { should_not report_lint line: 2 }
      it { should report_lint line: 3 }
    end

    context 'when global disable comes before an @include' do
      let(:scss) { <<-SCSS }
        // scss-lint:disable Fake
        p {
          border: fail1;
        }

        @include mixin(param) {
          border: fail1;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when // control comment appears in the middle of a comma sequence' do
      let(:scss) { <<-SCSS }
        .badClass, // scss-lint:disable Fake
        .good-selector {
          border: fail1;
        }

        p {
          color: #FFF;
        }
      SCSS

      it { should_not report_lint line: 1 }
      it { should report_lint line: 3 }
    end

    context 'when /* control comment appears in the middle of a comma sequence' do
      let(:scss) { <<-SCSS }
        p {
          color: #FFF;
        }

        .badClass, /* scss-lint:disable Fake */
        .good-selector {
          border: fail1;
        }
      SCSS

      it { should_not report_lint line: 1 }
      it { should report_lint line: 7 }
    end
  end
end
