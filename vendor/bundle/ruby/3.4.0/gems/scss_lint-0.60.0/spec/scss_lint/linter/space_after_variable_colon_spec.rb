require 'spec_helper'

describe SCSSLint::Linter::SpaceAfterVariableColon do
  let(:linter_config) { { 'style' => style } }

  context 'when one space is preferred' do
    let(:style) { 'one_space' }

    context 'when the colon after a variable is not followed by space' do
      let(:scss) { '$my-color:#fff;' }

      it { should report_lint line: 1 }
    end

    context 'when the colon after a variable is followed by more than one space' do
      let(:scss) { '$my-color:  #fff;' }

      it { should report_lint line: 1 }
    end

    context 'when the colon after a variable is followed by a space' do
      let(:scss) { '$my-color: #fff;' }

      it { should_not report_lint }
    end

    context 'when the colon after a variable is surrounded by spaces' do
      let(:scss) { '$my-color : #fff;' }

      it { should_not report_lint }
    end

    context 'when the colon after a variable is followed by a space and a newline' do
      let(:scss) { <<-SCSS }
        $my-color:\s
        #fff;
      SCSS

      it { should report_lint line: 1 }
    end

    context 'when the colon after a property is followed by a tab' do
      let(:scss) { <<-SCSS }
        $my-color:\t#fff;
      SCSS

      it { should report_lint line: 1 }
    end
  end

  context 'when no spaces are allowed' do
    let(:style) { 'no_space' }

    context 'when the colon after a variable is not followed by space' do
      let(:scss) { '$my-color:#fff;' }

      it { should_not report_lint }
    end

    context 'when colon after variable is not followed by space and the semicolon is missing' do
      let(:scss) { '$my-color:#fff' }

      it { should_not report_lint }
    end

    context 'when the colon after a property is followed by a space' do
      let(:scss) { '$my-color: #fff;' }

      it { should report_lint line: 1 }
    end

    context 'when the colon after a property is surrounded by spaces' do
      let(:scss) { '$my-color : #fff;' }

      it { should report_lint line: 1 }
    end

    context 'when the colon after a property is followed by multiple spaces' do
      let(:scss) { '$my-color:  #fff;' }

      it { should report_lint line: 1 }
    end

    context 'when the colon after a property is followed by a newline' do
      let(:scss) { <<-SCSS }
        $my-color:
        #fff;
      SCSS

      it { should report_lint line: 1 }
    end

    context 'when the colon after a property is followed by a tab' do
      let(:scss) { <<-SCSS }
        $my-color:\t#fff;
      SCSS

      it { should report_lint line: 1 }
    end
  end

  context 'when at least one space is preferred' do
    let(:style) { 'at_least_one_space' }

    context 'when the colon after a variable is not followed by space' do
      let(:scss) { '$my-color:#fff;' }

      it { should report_lint line: 1 }
    end

    context 'when colon after variable is not followed by space and the semicolon is missing' do
      let(:scss) { '$my-color:#fff' }

      it { should report_lint line: 1 }
    end

    context 'when the colon after a variable is followed by a space' do
      let(:scss) { '$my-color: #fff;' }

      it { should_not report_lint }
    end

    context 'when the colon after a variable is surrounded by spaces' do
      let(:scss) { '$my-color : #fff;' }

      it { should_not report_lint }
    end

    context 'when the colon after a variable is followed by multiple spaces' do
      let(:scss) { '$my-color:  #fff;' }

      it { should_not report_lint }
    end

    context 'when the colon after a property is followed by multiple spaces and a tab' do
      let(:scss) { <<-SCSS }
        $my-color:  \t#fff;
      SCSS

      it { should report_lint line: 1 }
    end
  end

  context 'when one space or newline is preferred' do
    let(:style) { 'one_space_or_newline' }

    context 'when the colon after a variabl is not followed by space' do
      let(:scss) { '$my-color:#fff;' }

      it { should report_lint line: 1 }
    end

    context 'when the colon after a variable is followed by a space' do
      let(:scss) { '$my-color: #fff;' }

      it { should_not report_lint }
    end

    context 'when the colon after a variable is followed by a newline and spaces' do
      let(:scss) { <<-SCSS }
        $my-color:
              #fff;
      SCSS

      it { should_not report_lint }
    end

    context 'when the colon after a variable is followed by a newline and no spaces' do
      let(:scss) { <<-SCSS }
        $my-color:
#fff;
      SCSS

      it { should_not report_lint }
    end

    context 'when the colon after a variable is followed by a space and then a newline' do
      let(:scss) { <<-SCSS }
        $my-color:\s
#fff;
      SCSS

      it { should report_lint line: 1 }
    end
  end
end
