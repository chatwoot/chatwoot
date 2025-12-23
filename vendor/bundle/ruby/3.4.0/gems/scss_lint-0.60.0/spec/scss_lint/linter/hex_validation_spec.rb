require 'spec_helper'

describe SCSSLint::Linter::HexValidation do
  context 'when rule is empty' do
    let(:scss) { <<-SCSS }
      p {
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when rule contains valid hex codes or color keyword' do
    gradient_css = 'progid:DXImageTransform.Microsoft.gradient' \
                   '(startColorstr=#99000000, endColorstr=#99000000)'

    let(:scss) { <<-SCSS }
      p {
        background: #000;
        color: #FFFFFF;
        border-color: red;
        filter: #{gradient_css};
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when rule contains invalid hex codes' do
    let(:scss) { <<-SCSS }
      p {
        background: #dd;
        color: #dddd;
      }
    SCSS

    it { should report_lint line: 2 }
    it { should report_lint line: 3 }
  end

  context 'when rule contains hex codes in a longer string' do
    let(:scss) { <<-SCSS }
      p {
        content: 'foo#bad';
        content: 'foo #ba';
      }
    SCSS

    it { should report_lint line: 3 }
  end
end
