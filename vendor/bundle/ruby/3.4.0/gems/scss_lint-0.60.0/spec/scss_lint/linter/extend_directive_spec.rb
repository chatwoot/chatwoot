require 'spec_helper'

describe SCSSLint::Linter::ExtendDirective do
  context 'when extending with a class' do
    let(:scss) { <<-SCSS }
      p {
        @extend .error;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when extending with a type' do
    let(:scss) { <<-SCSS }
      p {
        @extend span;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when extending with an id' do
    let(:scss) { <<-SCSS }
      p {
        @extend #some-identifer;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when extending with a placeholder' do
    let(:scss) { <<-SCSS }
      p {
        @extend %placeholder;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when extending with a selector whose prefix is not a placeholder' do
    let(:scss) { <<-SCSS }
      p {
        @extend .blah-\#{$dynamically_generated_name};
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when extending with a selector whose prefix is dynamic' do
    let(:scss) { <<-SCSS }
      p {
        @extend \#{$dynamically_generated_placeholder_name};
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when not using extend' do
    let(:scss) { <<-SCSS }
      p {
        @include mixin;
      }
    SCSS

    it { should_not report_lint }
  end
end
