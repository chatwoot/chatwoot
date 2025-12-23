require 'spec_helper'

describe SCSSLint::Linter::TrailingZero do
  context 'when no values exist' do
    let(:scss) { 'p {}' }

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

  context 'when a unitless fractional value with no trailing zero exists' do
    let(:scss) { <<-SCSS }
      p {
        line-height: .5;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a unitless fractional value with multiple trailing zero exists' do
    let(:scss) { <<-SCSS }
      p {
        line-height: .600;
      }
    SCSS

    it { should report_lint }
  end

  context 'when a negative unitless fractional value with no trailing zero exists' do
    let(:scss) { <<-SCSS }
      p {
        line-height: -.5;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a fractional value with units and no trailing zero exists' do
    let(:scss) { <<-SCSS }
      p {
        margin: .5em;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a negative fractional value with units and no trailing zero exists' do
    let(:scss) { <<-SCSS }
      p {
        margin: -.5em;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a fractional value with a trailing zero exists' do
    let(:scss) { <<-SCSS }
      p {
        line-height: .50;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when a fractional value with units and a trailing zero exists' do
    let(:scss) { <<-SCSS }
      p {
        margin: .50em;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when a negative fractional value with units and a trailing zero exists' do
    let(:scss) { <<-SCSS }
      p {
        margin: -.50em;
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

  context 'when multiple fractional values with trailing zeros exist' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0.50em .50 0.10px .90pt;
      }
    SCSS

    it { should report_lint count: 4, line: 2 }
  end

  context 'when trailing zeros appear in function arguments' do
    let(:scss) { <<-SCSS }
      p {
        margin: some-function(.50em, 0.40 0.30 .2);
      }
    SCSS

    it { should report_lint count: 3, line: 2 }
  end

  context 'when trailing zeros appear in mixin arguments' do
    let(:scss) { <<-SCSS }
      p {
        @include some-mixin(0.50em, 0.40 0.30 .2);
      }
    SCSS

    it { should report_lint count: 3, line: 2 }
  end

  context 'when trailiing zeros appear in variable declarations' do
    let(:scss) { '$some-var: .50em;' }

    it { should report_lint line: 1 }
  end

  context 'when trailing zeros appear in named arguments' do
    let(:scss) { <<-SCSS }
      p {
        @include line-clamp($line-height: .90, $line-count: 2);
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when trailing zeros appear in parameter defaults' do
    let(:scss) { <<-SCSS }
      @mixin my-mixin($bad-value: .50, $good-value: .9, $string-value: ".90") {
        margin: $some-value;
        padding: $some-other-value;
      }
    SCSS

    it { should report_lint count: 1, line: 1 }
  end
end
