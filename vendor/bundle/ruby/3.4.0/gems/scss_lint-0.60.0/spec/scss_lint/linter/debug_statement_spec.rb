require 'spec_helper'

describe SCSSLint::Linter::DebugStatement do
  context 'when no debug statements are present' do
    let(:scss) { <<-SCSS }
      p {
        color: #fff;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a debug statement is present' do
    let(:scss) { <<-SCSS }
      @debug 'This is a debug statement';
    SCSS

    it { should report_lint line: 1 }
  end
end
