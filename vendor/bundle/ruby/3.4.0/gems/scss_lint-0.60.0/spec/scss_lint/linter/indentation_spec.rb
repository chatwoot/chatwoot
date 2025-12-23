require 'spec_helper'

describe SCSSLint::Linter::Indentation do
  context 'when a line at the root level is indented' do
    let(:scss) { <<-SCSS }
      $var: 5px;
        $other: 10px;
    SCSS

    it { should_not report_lint line: 1 }
    it { should report_lint line: 2 }
  end

  context 'when a line in a rule set is properly indented' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0;
      }
    SCSS

    it { should_not report_lint }

    context 'with carriage returns for newlines' do
      let(:scss) { "p {\r  margin: 0;\r}" }
      it { should_not report_lint }
    end
  end

  context 'when lines in a rule set are not properly indented' do
    let(:scss) { <<-SCSS }
      p {
      margin: 0;
        padding: 1em;
      opacity: 0.5;
      }
    SCSS

    it { should report_lint line: 2 }
    it { should_not report_lint line: 3 }
    it { should report_lint line: 4 }

    context 'with carriage returns for newlines' do
      let(:scss) { "p {\rmargin: 0;\r  padding: 1em;}" }
      it { should_not report_lint line: 1 }
      it { should report_lint line: 2 }
      it { should_not report_lint line: 3 }
    end
  end

  context 'when selector of a nested rule set is not properly indented' do
    let(:scss) { <<-SCSS }
      p {
      em {
        font-style: italic;
      }
      }
    SCSS

    it { should report_lint line: 2 }
    it { should_not report_lint line: 3 }
    it { should_not report_lint line: 4 }
  end

  context 'when multi-line selector of a nested rule set is not properly indented' do
    let(:scss) { <<-SCSS }
      p {
      b,
      em,
      i {
        font-style: italic;
      }
      }
    SCSS

    it { should report_lint line: 2 }
    it { should_not report_lint line: 3 }
    it { should_not report_lint line: 4 }
    it { should_not report_lint line: 5 }
  end

  context 'when a property is on the same line as its rule selector' do
    let(:scss) { 'h1 { margin: 5px; }' }
    it { should_not report_lint }
  end

  context 'when an argument list spans multiple lines' do
    let(:scss) { <<-SCSS }
      @include mixin(one,
                     two,
                     three);
    SCSS

    it { should_not report_lint }
  end

  context 'when an argument list of an improperly indented script spans multiple lines' do
    let(:scss) { <<-SCSS }
      p {
      @include mixin(one,
                     two,
                     three);
      }
    SCSS

    it { should report_lint line: 2 }
    it { should_not report_lint line: 3 }
    it { should_not report_lint line: 4 }
  end

  context 'when an if statement is incorrectly indented' do
    let(:scss) { <<-SCSS }
      $condition: true;
        @if $condition {
        padding: 0;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when an if statement is accompanied by a correctly indented else statement' do
    let(:scss) { <<-SCSS }
      @if $condition {
        padding: 0;
      } @else {
        margin: 0;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when @at-root directive contains correctly indented children' do
    let(:scss) { <<-SCSS }
      .block {
        @at-root {
          .something {}
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when @at-root directive with an inline selector contains correctly indented children' do
    let(:scss) { <<-SCSS }
      .block {
        @at-root .something {
          .something-else {}
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when @at-root directive with no inline selector contains comment' do
    let(:scss) { <<-SCSS }
      @at-root {
        // A comment that causes a crash
        .something-else {}
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when the indentation width has been explicitly set' do
    let(:linter_config) { { 'width' => 3 } }

    let(:scss) { <<-SCSS }
      p {
        margin: 0;
         padding: 5px;
      }
    SCSS

    it { should report_lint line: 2 }
    it { should_not report_lint line: 3 }
  end

  context 'when there are selectors across multiple lines' do
    let(:scss) { <<-SCSS }
      .class1,
      .class2 {
        margin: 0;
        padding: 5px;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when there are selectors across multiple lines with a single line block' do
    let(:scss) { <<-SCSS }
      .class1,
      .class2 { margin: 0; }
    SCSS

    it { should_not report_lint }
  end

  context 'when a comment node precedes a node' do
    let(:scss) { <<-SCSS }
      // A comment
      $var: 1;
    SCSS

    it { should_not report_lint }
  end

  context 'when a line is indented with tabs' do
    let(:scss) { <<-SCSS }
      p {
      \tmargin: 0;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when a line contains a mix of tabs and spaces' do
    let(:scss) { <<-SCSS }
      p {
        \tmargin: 0;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when an @import spans multiple lines' do
    let(:scss) { <<-SCSS }
      @import 'foo',
          'bar';
    SCSS

    it { should_not report_lint }
  end

  context 'when an @import spans multiple lines and leads with a newline' do
    let(:scss) { <<-SCSS }
      @import
          'foo',
          'bar';
    SCSS

    it { should_not report_lint }
  end

  context 'when tabs are preferred' do
    let(:linter_config) { { 'character' => 'tab', 'width' => 1 } }

    context 'and the line is indented correctly' do
      let(:scss) { <<-SCSS }
        p {
        \tmargin: 0;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'and the line is incorrectly indented' do
      let(:scss) { <<-SCSS }
        p {
        \t\tmargin: 0;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'and the line is indented with spaces' do
      let(:scss) { <<-SCSS }
        p {
          margin: 0;
        }
      SCSS

      it { should report_lint line: 2 }
    end
  end

  context 'when indentation in non-nested code is allowed' do
    let(:linter_config) do
      {
        'allow_non_nested_indentation' => true,
        'character' => 'space',
        'width' => 2,
      }
    end

    context 'and an if statement is accompanied by a correctly indented else statement' do
      let(:scss) { <<-SCSS }
        @mixin my-func() {
          @if $condition {
            padding: 0;
          } @else {
            margin: 0;
          }
        }
      SCSS

      it { should_not report_lint }
    end

    context 'and non-nested code is indented' do
      let(:scss) { <<-SCSS }
        .component {}
          .component__image {}
          .component__text {}
            $some-variable: 0;
            .component-subblock {}
            .component-subblock__text {}
          .component-category {}
            .component-other {}
      SCSS

      it { should_not report_lint }
    end

    context 'and nested code is indented too much' do
      let(:scss) { <<-SCSS }
        .component {
          .component__image {}
          .component__text {}
            .component-subblock {}
        }
      SCSS

      it { should_not report_lint line: 2 }
      it { should_not report_lint line: 3 }
      it { should report_lint line: 4 }
    end

    context 'and nested code is indented too little' do
      let(:scss) { <<-SCSS }
        .component {
          .component__image {}
          .component__text {}
        .component-subblock {}
        }
      SCSS

      it { should_not report_lint line: 2 }
      it { should_not report_lint line: 3 }
      it { should report_lint line: 4 }
    end

    context 'and a nested non-ruleset is correctly indented' do
      let(:scss) { <<-SCSS }
        .one {
          color: #000;
        }
          .two {
            margin: 0;
          }
      SCSS

      it { should_not report_lint }
    end

    context 'and a nested non-ruleset is incorrectly indented' do
      let(:scss) { <<-SCSS }
        .one {
          color: #000;
        }
          .two {
              margin: 0;
          }
      SCSS

      it { should report_lint line: 5 }
    end

    context 'and a non-nested non-ruleset is correctly indented' do
      let(:scss) { <<-SCSS }
        $var: 1
      SCSS

      it { should_not report_lint }
    end
  end
end
