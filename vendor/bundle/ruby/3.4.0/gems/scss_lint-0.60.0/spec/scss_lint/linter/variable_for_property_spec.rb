require 'spec_helper'

describe SCSSLint::Linter::VariableForProperty do
  context 'when properties are specified' do
    let(:linter_config) { { 'properties' => %w[color font] } }

    context 'when configured property value is a variable' do
      let(:scss) { <<-SCSS }
        p {
          color: $black;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when configured property value is a hex string' do
      let(:scss) { <<-SCSS }
        p {
          color: #000;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'when configured property value is a color keyword' do
      let(:scss) { <<-SCSS }
        p {
          color: red;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'when an unspecified property value is a variable' do
      let(:scss) { <<-SCSS }
        p {
          background-color: $black;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when an unspecified property value is not a variable' do
      let(:scss) { <<-SCSS }
        p {
          background-color: #000;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when multiple configured property values are variables' do
      let(:scss) { <<-SCSS }
        p {
          color: $black;
          font: $small;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when multiple configured property values are not variables' do
      let(:scss) { <<-SCSS }
        p {
          color: #000;
          font: 8px;
        }
      SCSS

      it { should report_lint line: 2 }
      it { should report_lint line: 3 }
    end

    context 'when configured property values are mixed' do
      let(:scss) { <<-SCSS }
        p {
          color: $black;
          font: 8px;
        }
      SCSS

      it { should report_lint line: 3 }
    end

    context 'when configured property value is used with !important' do
      let(:scss) { <<-SCSS }
        p {
          color: $black !important;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when property specifies `currentColor`' do
      let(:scss) { <<-SCSS }
        p {
          background-color: currentColor;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when property specifies `inherit`' do
      let(:scss) { <<-SCSS }
        p {
          color: inherit;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when property specifies `initial`' do
      let(:scss) { <<-SCSS }
        p {
          color: initial;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when property specifies `transparent`' do
      let(:scss) { <<-SCSS }
        p {
          color: transparent;
        }
      SCSS

      it { should_not report_lint }
    end
  end

  context 'when properties are not specified' do
    let(:linter_config) { { 'properties' => [] } }

    context 'when property value is a variable' do
      let(:scss) { <<-SCSS }
        p {
          color: $black;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when property value is not a variable' do
      let(:scss) { <<-SCSS }
        p {
          color: #000;
        }
      SCSS

      it { should_not report_lint }
    end
  end
end
