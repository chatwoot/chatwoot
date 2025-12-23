require 'spec_helper'

describe SCSSLint::Linter::UrlQuotes do
  context 'when property has a literal URL' do
    let(:scss) { <<-SCSS }
      p {
        background: url(example.png);
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when property has a URL enclosed in single quotes' do
    let(:scss) { <<-SCSS }
      p {
        background: url('example.png');
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when property has a URL enclosed in double quotes' do
    let(:scss) { <<-SCSS }
      p {
        background: url("example.png");
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when property has a literal URL in a list' do
    let(:scss) { <<-SCSS }
      p {
        background: transparent url(example.png);
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when property has a single-quoted URL in a list' do
    let(:scss) { <<-SCSS }
      p {
        background: transparent url('example.png');
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when property has a double-quoted URL in a list' do
    let(:scss) { <<-SCSS }
      p {
        background: transparent url("example.png");
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when property has a data URI' do
    let(:scss) { <<-SCSS }
      .tracking-pixel {
        background: url(data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==);
      }
    SCSS

    it { should_not report_lint }
  end
end
