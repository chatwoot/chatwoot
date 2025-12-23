require 'spec_helper'

describe SCSSLint::Linter::BemDepth do
  context 'with the default maximum number of elements' do
    context 'when a selector lacks elements' do
      let(:scss) { <<-SCSS }
        .block {
          background: #f00;
        }
        %block {
          background: #0f0;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when a selector contains one element' do
      let(:scss) { <<-SCSS }
        .block__element {
          background: #f00;
        }
        %block__element {
          background: #f00;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when a selector contains one element with a modifier' do
      let(:scss) { <<-SCSS }
        .block__element--modifier {
          background: #f00;
        }
        %block__element--modifier {
          background: #f00;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when a selector contains more than one element' do
      let(:scss) { <<-SCSS }
        .block__element__subelement {
          background: #f00;
        }
        %block__element__subelement {
          background: #f00;
        }
      SCSS

      it { should report_lint line: 1 }
      it { should report_lint line: 4 }
    end

    context 'when a selector contains more than one element with a modifier' do
      let(:scss) { <<-SCSS }
        .block__element__subelement--modifier {
          background: #f00;
        }
        %block__element__subelement--modifier {
          background: #f00;
        }
      SCSS

      it { should report_lint line: 1 }
      it { should report_lint line: 4 }
    end
  end

  context 'with a custom maximum number of elements' do
    let(:linter_config) { { 'max_elements' => 2 } }

    context 'when selectors have up to the custom number of elements' do
      let(:scss) { <<-SCSS }
        .block__element__subelement {
          background: #f00;
        }
        %block__element__subelement {
          background: #f00;
        }
        .block__element__subelement--modifier {
          background: #0f0;
        }
        %block__element__subelement--modifier {
          background: #0f0;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when selectors have more than the custom number of elements' do
      let(:scss) { <<-SCSS }
        .block__element__subelement__other {
          background: #f00;
        }
        %block__element__subelement__other {
          background: #f00;
        }
        .block__element__subelement__other--modifier {
          background: #0f0;
        }
        %block__element__subelement__other--modifier {
          background: #0f0;
        }
      SCSS

      it { should report_lint line: 1 }
      it { should report_lint line: 4 }
      it { should report_lint line: 7 }
      it { should report_lint line: 10 }
    end
  end
end
