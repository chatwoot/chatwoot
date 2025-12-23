require 'spec_helper'

describe SCSSLint::Linter::LeadingZero do
  context 'when no values exist' do
    let(:scss) { <<-SCSS }
      p {
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a zero exists' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when an integer value exists' do
    let(:scss) { <<-SCSS }
      p {
        line-height: 2;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when an integer value with units exists' do
    let(:scss) { <<-SCSS }
      p {
        margin: 5px;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a unitless fractional value with no leading zero exists' do
    let(:scss) { <<-SCSS }
      p {
        line-height: .5;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a negative unitless fractional value with no leading zero exists' do
    let(:scss) { <<-SCSS }
      p {
        line-height: -.5;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a fractional value with units and no leading zero exists' do
    let(:scss) { <<-SCSS }
      p {
        margin: .5em;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a negative fractional value with units and no leading zero exists' do
    let(:scss) { <<-SCSS }
      p {
        margin: -.5em;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a fractional value with a leading zero exists' do
    let(:scss) { <<-SCSS }
      p {
        line-height: 0.5;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when a fractional value with units and a leading zero exists' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0.5em;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when a negative fractional value with units and a leading zero exists' do
    let(:scss) { <<-SCSS }
      p {
        margin: -0.5em;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when a fractional value with a mantissa ending in zero exists' do
    let(:scss) { <<-SCSS }
      p {
        line-height: 10.5;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when multiple fractional values with leading zeros exist' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0.5em 0.5 0.1px 0.9pt;
      }
    SCSS

    it { should report_lint count: 4, line: 2 }
  end

  context 'when leading zeros appear in function arguments' do
    let(:scss) { <<-SCSS }
      p {
        margin: some-function(0.5em, 0.4 0.3 .2);
      }
    SCSS

    it { should report_lint count: 3, line: 2 }
  end

  context 'when leading zeros appear in mixin arguments' do
    let(:scss) { <<-SCSS }
      p {
        @include some-mixin(0.5em, 0.4 0.3 .2);
      }
    SCSS

    it { should report_lint count: 3, line: 2 }
  end

  context 'when leading zeros appear in variable declarations' do
    let(:scss) { '$some-var: 0.5em;' }

    it { should report_lint line: 1 }
  end

  context 'when leading zeros appear in named arguments' do
    let(:scss) { <<-SCSS }
      p {
        @include line-clamp($line-height: 0.9, $line-count: 2);
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when leading zeros appear in parameter defaults' do
    let(:scss) { <<-SCSS }
      @mixin my-mixin($bad-value: 0.5, $good-value: .9, $string-value: "0.9") {
        margin: $some-value;
        padding: $some-other-value;
      }
    SCSS

    it { should report_lint count: 1, line: 1 }
  end

  context 'when a leading zero exists in interpolation in a comment' do
    let(:scss) { <<-SCSS }
      .outer {
        .inner {
          /* \#{0.5} */
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when leading zeros are preferred' do
    let(:linter_config) { { 'style' => 'include_zero' } }

    context 'when a zero exists' do
      let(:scss) { <<-SCSS }
        p {
          margin: 0;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when a non-zero integer value exists' do
      let(:scss) { <<-SCSS }
        p {
          line-height: 2;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when a fractional value with no leading zero exists' do
      let(:scss) { <<-SCSS }
        p {
          padding: .5em;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'when a fractional value with leading zero exists' do
      let(:scss) { <<-SCSS }
        p {
          padding: 0.5em;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when a fractional value with a mantissa ending in zero exists' do
      let(:scss) { <<-SCSS }
        p {
          padding: 10.5em;
        }
      SCSS

      it { should_not report_lint }
    end
  end
end
