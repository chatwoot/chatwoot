require 'spec_helper'

describe SCSSLint::Linter::BorderZero do
  context 'when a rule is empty' do
    let(:scss) { <<-SCSS }
      p {
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a property' do
    let(:lint_description) { subject.lints.first.description }

    context 'contains a normal border' do
      let(:scss) { <<-SCSS }
        p {
          border: 1px solid #000;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'has a border of 0' do
      let(:scss) { <<-SCSS }
        p {
          border: 0;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'has a border of none' do
      let(:scss) { <<-SCSS }
        p {
          border: none;
        }
      SCSS

      it { should report_lint line: 2 }

      it 'should report lint with the border property in the description' do
        lint_description.should == '`border: 0` is preferred over `border: none`'
      end
    end

    context 'has a border-top of none' do
      let(:scss) { <<-SCSS }
        p {
          border-top: none;
        }
      SCSS

      it { should report_lint line: 2 }

      it 'should report lint with the border-top property in the description' do
        lint_description.should == '`border-top: 0` is preferred over `border-top: none`'
      end
    end

    context 'has a border-right of none' do
      let(:scss) { <<-SCSS }
        p {
          border-right: none;
        }
      SCSS

      it { should report_lint line: 2 }

      it 'should report lint with the border-right property in the description' do
        lint_description.should == '`border-right: 0` is preferred over `border-right: none`'
      end
    end

    context 'has a border-bottom of none' do
      let(:scss) { <<-SCSS }
        p {
          border-bottom: none;
        }
      SCSS

      it { should report_lint line: 2 }

      it 'should report lint with the border-bottom property in the description' do
        lint_description.should == '`border-bottom: 0` is preferred over `border-bottom: none`'
      end
    end

    context 'has a border-left of none' do
      let(:scss) { <<-SCSS }
        p {
          border-left: none;
        }
      SCSS

      it { should report_lint line: 2 }

      it 'should report lint with the border-left property in the description' do
        lint_description.should == '`border-left: 0` is preferred over `border-left: none`'
      end
    end
  end

  context 'when a convention of `none` is preferred' do
    let(:linter_config) { { 'convention' => 'none' } }

    context 'and the border is `none`' do
      let(:scss) { <<-SCSS }
        p {
          border: none;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'and the border is `0`' do
      let(:scss) { <<-SCSS }
        p {
          border: 0;
        }
      SCSS

      it { should report_lint }
    end

    context 'and the border is a non-zero value' do
      let(:scss) { <<-SCSS }
        p {
          border: 5px;
        }
      SCSS

      it { should_not report_lint }
    end
  end
end
