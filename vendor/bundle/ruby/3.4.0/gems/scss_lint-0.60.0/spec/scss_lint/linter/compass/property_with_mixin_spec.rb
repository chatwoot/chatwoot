require 'spec_helper'

describe SCSSLint::Linter::Compass::PropertyWithMixin do
  context 'when a rule has a property with an equivalent Compass mixin' do
    let(:scss) { <<-SCSS }
      p {
        opacity: .5;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when a rule includes a Compass property mixin' do
    let(:scss) { <<-SCSS }
      p {
        @include opacity(.5);
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a rule does not have a property with a corresponding Compass mixin' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a rule includes display: inline-block' do
    let(:scss) { <<-SCSS }
      p {
        display: inline-block;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when properties are ignored' do
    let(:linter_config) { { 'ignore' => %w[inline-block] } }

    let(:scss) { <<-SCSS }
      p {
        display: inline-block;
      }
    SCSS

    it { should_not report_lint }
  end
end
