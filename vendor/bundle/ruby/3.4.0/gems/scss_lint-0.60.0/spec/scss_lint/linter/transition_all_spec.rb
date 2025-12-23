require 'spec_helper'

describe SCSSLint::Linter::TransitionAll do
  context 'when transition-property is not set' do
    let(:scss) { <<-SCSS }
      p {
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when transition-property is set to none' do
    let(:scss) { <<-SCSS }
      p {
        transition-property: none;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when transition-property is not set to all' do
    let(:scss) { <<-SCSS }
      p {
        transition-property: color;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when transition-property is set to all' do
    let(:scss) { <<-SCSS }
      p {
        transition-property: all;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when transition shorthand for transition-property is not set' do
    let(:scss) { <<-SCSS }
      p {
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when transition shorthand for transition-property is set to none' do
    let(:scss) { <<-SCSS }
      p {
        transition: none;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when transition shorthand for transition-property is not set to all' do
    let(:scss) { <<-SCSS }
      p {
        transition: color 1s linear;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when transition shorthand for transition-property is set to all' do
    let(:scss) { <<-SCSS }
      p {
        transition: all 1s linear;
      }
    SCSS

    it { should report_lint line: 2 }
  end
end
