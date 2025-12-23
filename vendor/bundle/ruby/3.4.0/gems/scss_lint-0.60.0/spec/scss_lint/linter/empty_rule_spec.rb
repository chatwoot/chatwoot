require 'spec_helper'

describe SCSSLint::Linter::EmptyRule do
  context 'when rule is empty' do
    let(:scss) { <<-SCSS }
      p {
      }
    SCSS

    it { should report_lint line: 1 }
  end

  context 'when rule contains an empty nested rule' do
    let(:scss) { <<-SCSS }
      p {
        background: #000;
        display: none;
        margin: 5px;
        padding: 10px;
        a {
        }
      }
    SCSS

    it { should report_lint line: 6 }
  end
end
