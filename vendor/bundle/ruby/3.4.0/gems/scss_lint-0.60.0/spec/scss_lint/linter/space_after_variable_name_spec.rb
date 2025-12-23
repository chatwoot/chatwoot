require 'spec_helper'

describe SCSSLint::Linter::SpaceAfterVariableName do
  let(:scss) { <<-SCSS }
    $none: #fff;
    $one : #fff;
    $two  : #fff;
   SCSS

  it { should_not report_lint line: 1 }
  it { should report_lint line: 2 }
  it { should report_lint line: 3 }

  context 'when a map contains aligned colons' do
    let(:scss) { <<-SCSS }
      $map: (
        'one'   : 350px,
        'two'   : 450px,
        'three' : 560px,
      );
    SCSS

    it { should_not report_lint }
  end
end
