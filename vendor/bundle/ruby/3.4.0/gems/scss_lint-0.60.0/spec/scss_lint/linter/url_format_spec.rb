require 'spec_helper'

describe SCSSLint::Linter::UrlFormat do
  shared_examples_for 'UrlFormat linter' do
    context 'when URL contains protocol' do
      let(:url) { 'https://something.com/image.png' }

      it { should report_lint }
    end

    context 'when URL contains domain with protocol-less double slashes' do
      let(:url) { '//something.com/image.png' }

      it { should report_lint }
    end

    context 'when URL contains absolute path' do
      let(:url) { '/absolute/path/to/image.png' }

      it { should_not report_lint }
    end

    context 'when URL contains relative path' do
      let(:url) { 'relative/path/to/image.png' }

      it { should_not report_lint }
    end

    context 'when URL is a data URI' do
      let(:url) { 'data:image/png;base64,iVBORI=' }

      it { should_not report_lint }
    end

    context 'when URL contains a variable' do
      let(:scss) { <<-SCSS }
        .block {
          background: url('${url}');
        }
      SCSS

      it { should_not report_lint }
    end
  end

  context 'when URL is enclosed in quotes' do
    let(:scss) { <<-SCSS }
      .block {
        background: url('#{url}');
      }
    SCSS

    it_should_behave_like 'UrlFormat linter'
  end

  context 'when URL is not enclosed in quotes' do
    let(:scss) { <<-SCSS }
      .block {
        background: url(#{url});
      }
    SCSS

    it_should_behave_like 'UrlFormat linter'
  end
end
