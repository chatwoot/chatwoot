require 'spec_helper'

describe SCSSLint::Linter::UnnecessaryMantissa do
  context 'when value is zero' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0;
        padding: func(0);
        top: 0em;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when value contains no mantissa' do
    let(:scss) { <<-SCSS }
      p {
        margin: 1;
        padding: func(1);
        top: 1em;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when value contains a mantissa with a zero' do
    let(:scss) { <<-SCSS }
      p {
        margin: 1.0;
        padding: func(1.0);
        top: 1.0em;
      }
    SCSS

    it { should report_lint line: 2 }
    it { should report_lint line: 3 }
    it { should report_lint line: 4 }
  end

  context 'when value contains a mantissa with multiple zeroes' do
    let(:scss) { <<-SCSS }
      p {
        margin: 1.000;
        padding: func(1.000);
        top: 1.000em;
      }
    SCSS

    it { should report_lint line: 2 }
    it { should report_lint line: 3 }
    it { should report_lint line: 4 }
  end

  context 'when value contains a mantissa with multiple zeroes followed by a number' do
    let(:scss) { <<-SCSS }
      p {
        margin: 1.0001;
        padding: func(1.0001);
        top: 1.0001em;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a decimal value appears in a single-quoted string' do
    let(:scss) { <<-SCSS }
      p {
        content: '1.0';
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a decimal value appears in a double-quoted string' do
    let(:scss) { <<-SCSS }
      p {
        content: "1.0";
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a decimal value appears in a URL' do
    let(:scss) { <<-SCSS }
      p {
        background: url(https://www.example.com/v1.0/image.jpg);
      }
    SCSS

    it { should_not report_lint }
  end
end
