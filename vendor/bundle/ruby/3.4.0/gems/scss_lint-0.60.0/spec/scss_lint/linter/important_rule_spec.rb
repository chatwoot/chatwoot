require 'spec_helper'

describe SCSSLint::Linter::ImportantRule do
  context 'when !important is not used' do
    let(:scss) { <<-SCSS }
      p {
        color: #000;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when !important is used' do
    let(:scss) { <<-SCSS }
      p {
        color: #000 !important;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when !important is used in property containing Sass script' do
    let(:scss) { <<-SCSS }
      p {
        color: \#{$my-var} !important;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when property contains a list literal with an empty list' do
    let(:scss) { <<-SCSS }
      p {
        content: 0 ();
      }
    SCSS

    it { should_not report_lint }
  end
end
