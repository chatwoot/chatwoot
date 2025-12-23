require 'spec_helper'

describe SCSSLint::Linter::TrailingWhitespace do
  context 'when lines contain trailing spaces' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0;\s\s
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when lines contain trailing tabs' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0;\t\t
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when lines does not contain trailing whitespace' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0;
      }
    SCSS

    it { should_not report_lint }
  end
end
