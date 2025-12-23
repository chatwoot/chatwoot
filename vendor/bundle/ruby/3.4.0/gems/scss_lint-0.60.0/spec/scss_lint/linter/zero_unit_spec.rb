require 'spec_helper'

describe SCSSLint::Linter::ZeroUnit do
  context 'when no properties exist' do
    let(:scss) { <<-SCSS }
      p {
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when properties with unit-less zeros exist' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when properties with non-zero values exist' do
    let(:scss) { <<-SCSS }
      p {
        margin: 5px;
        line-height: 1.5em;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when properties with zero values contain units' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0px;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when properties with multiple zero values containing units exist' do
    let(:scss) { <<-SCSS }
      p {
        margin: 5em 0em 2em 0px;
      }
    SCSS

    it { should report_lint line: 2, count: 2 }
  end

  context 'when function call contains a zero value with units' do
    let(:scss) { <<-SCSS }
      p {
        margin: some-function(0em);
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when mixin include contains a zero value with units' do
    let(:scss) { <<-SCSS }
      p {
        @include some-mixin(0em);
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when string contains a zero value with units' do
    let(:scss) { <<-SCSS }
      p {
        content: func("0em");
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when property value has a ".0" fractional component' do
    let(:scss) { <<-SCSS }
      p {
        margin: 4.0em;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when property value has a color hex with a leading 0' do
    let(:scss) { <<-SCSS }
      p {
        color: #0af;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when property with zero value is a dimension' do
    let(:scss) { <<-SCSS }
      p {
        transition-delay: 0s;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when calc expression with zero value has units' do
    let(:scss) { <<-SCSS }
      p {
        width: calc(0px + 1.5em);
      }
    SCSS

    it { should_not report_lint }
  end
end
