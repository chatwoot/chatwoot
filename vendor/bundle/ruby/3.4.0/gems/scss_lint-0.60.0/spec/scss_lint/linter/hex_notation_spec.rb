require 'spec_helper'

describe SCSSLint::Linter::HexNotation do
  let(:linter_config) { { 'style' => style } }
  let(:style) { nil }

  context 'when rule is empty' do
    let(:scss) { <<-SCSS }
      p {
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when rule contains color keyword' do
    let(:scss) { <<-SCSS }
      p {
        border-color: red;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'lowercase style' do
    let(:style) { 'lowercase' }

    context 'when rule contains properties with lowercase hex code' do
      let(:scss) { <<-SCSS }
        p {
          background: #ccc;
          color: #cccccc;
          @include crazy-color(#fff);
        }
      SCSS

      it { should_not report_lint }
    end

    context 'with uppercase hex codes' do
      let(:scss) { <<-SCSS }
        p {
          background: #CCC;
          color: #CCCCCC;
          @include crazy-color(#FFF);
        }
      SCSS

      it { should report_lint line: 2 }
      it { should report_lint line: 3 }
      it { should report_lint line: 4 }
    end
  end

  context 'uppercase style' do
    let(:style) { 'uppercase' }

    context 'with uppercase hex codes' do
      let(:scss) { <<-SCSS }
        p {
          background: #CCC;
          color: #CCCCCC;
          @include crazy-color(#FFF);
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when rule contains properties with lowercase hex code' do
      let(:scss) { <<-SCSS }
        p {
          background: #ccc;
          color: #cccccc;
          @include crazy-color(#fff);
        }
      SCSS

      it { should report_lint line: 2 }
      it { should report_lint line: 3 }
      it { should report_lint line: 4 }
    end
  end

  context 'when ID selector starts with a hex code' do
    let(:scss) { <<-SCSS }
      #aabbcc {
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when color is specified as a color keyword' do
    let(:scss) { <<-SCSS }
      p {
        @include box-shadow(0 0 1px 1px gold);
      }
    SCSS

    it { should_not report_lint }
  end
end
