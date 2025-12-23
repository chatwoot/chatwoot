require 'spec_helper'

describe SCSSLint::Linter::Shorthand do
  context 'when a rule' do
    context 'is empty' do
      let(:scss) { <<-SCSS }
        p {
        }
      SCSS

      it { should_not report_lint }
    end

    context 'contains properties with valid shorthand values' do
      let(:scss) { <<-SCSS }
        p {
          border-radius: 1px 2px 1px 3px;
          border-width: 1px;
          color: rgba(0, 0, 0, .5);
          margin: 1px 2px;
          padding: 0 0 1px;
        }
      SCSS

      it { should_not report_lint }
    end
  end

  context 'when a property' do
    context 'has a value repeated 4 times' do
      let(:scss) { <<-SCSS }
        p {
          padding: 1px 1px 1px 1px;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'has a value repeated 3 times' do
      let(:scss) { <<-SCSS }
        p {
          padding: 3px 3px 3px;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'has interpolation in its name and starts with a shorthandable property' do
      let(:scss) { <<-SCSS }
        p {
          border-color\#{$type}: 1px 1px;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'has exactly two identical values' do
      let(:scss) { <<-SCSS }
        p {
          padding: 10px 10px;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'appears to have two identical values, but cannot be shorthanded' do
      let(:scss) { <<-SCSS }
        p:before {
          content: ' ';
        }
      SCSS

      it { should_not report_lint }
    end

    context 'has its first two values repeated' do
      let(:scss) { <<-SCSS }
        p {
          padding: 1px 2px 1px 2px;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'has its first value repeated in the third position' do
      let(:scss) { <<-SCSS }
        p {
          padding: 1px 2px 1px;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'has its second value repeated in the fourth position' do
      let(:scss) { <<-SCSS }
        p {
          padding: 1px 2px 3px 2px;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'contains numeric values and function calls' do
      let(:scss) { <<-SCSS }
        p {
          margin: 10px percentage(1 / 100);
        }
      SCSS

      it { should_not report_lint }
    end

    context 'contains a list of function calls that can be shortened' do
      let(:scss) { <<-SCSS }
        p {
          margin: percentage(1 / 100) percentage(1 / 100);
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'contains a list of function calls that cannot be shortened' do
      let(:scss) { <<-SCSS }
        p {
          margin: percentage(1 / 100) percentage(5 / 100);
        }
      SCSS

      it { should_not report_lint }
    end

    context 'contains a list of variables that can be shortened' do
      let(:scss) { <<-SCSS }
        p {
          margin: $my-var 1px $my-var;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'contains a number with no trailing semicolon' do
      let(:scss) { <<-SCSS }
        p {
          margin: 4px
        }
      SCSS

      it { should_not report_lint }
    end

    context 'can be shortened and is followed by !important modifier' do
      let(:scss) { <<-SCSS }
        p {
          padding: 1px 2px 3px 2px !important;
          margin: 0 0 0 0 !important; // A comment
        }
      SCSS

      it { should report_lint line: 2 }
      it { should report_lint line: 3 }
    end
  end

  context 'when configured with allowed_shorthands, and a rule' do
    let(:linter_config) { { 'allowed_shorthands' => allowed } }

    context 'can be shortened to 1, 2, or 3, but 1 is not allowed' do
      let(:allowed) { [2, 3] }
      let(:scss) { <<-SCSS }
        p {
          margin: 4px 4px 4px 4px;
        }
      SCSS

      it { should report_lint }
    end

    context 'can be shortened to 1, but 1 is not allowed' do
      let(:allowed) { [2, 3] }
      let(:scss) { <<-SCSS }
        p {
          margin: 4px 4px 4px;
        }
      SCSS

      it { should_not report_lint }

      context 'and ends with !important' do
        let(:scss) { <<-SCSS }
          p {
            margin: 4px 4px 4px !important;
          }
        SCSS

        it { should_not report_lint }
      end
    end

    context 'is fine but length is not allowed' do
      let(:allowed) { [1, 2, 3] }
      let(:scss) { <<-SCSS }
        p {
          margin: 1px 2px 3px 4px;
        }
      SCSS

      it { should report_lint }
    end

    context 'when allowed_shorthands is a empty list' do
      let(:allowed) { [] }
      let(:scss) { <<-SCSS }
        p {
          margin: 0;
        }
      SCSS

      it { should report_lint line: 2, message: /forbidden/ }
    end
  end
end
