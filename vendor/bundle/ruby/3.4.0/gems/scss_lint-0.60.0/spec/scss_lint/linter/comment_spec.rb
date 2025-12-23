require 'spec_helper'

describe SCSSLint::Linter::Comment do
  context 'when no comments exist' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when comment is a single line comment' do
    let(:scss) { '// Single line comment' }

    it { should_not report_lint }
  end

  context 'when comment is a single line comment at the end of a line' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0; // Comment at end of line
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when comment is a multi-line comment' do
    let(:scss) { <<-SCSS }
      h1 {
        color: #eee;
      }
      /*
       * This is a multi-line comment that should report a lint
       */
      p {
        color: #DDD;
      }
    SCSS

    it { should report_lint line: 4 }
  end

  context 'when multi-line-style comment is a at the end of a line' do
    let(:scss) { <<-SCSS }
      h1 {
        color: #eee; /* This is a comment */
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when multi-line comment is allowed by config' do
    let(:linter_config) { { 'allowed' => '^[/\\* ]*Copyright' } }
    let(:scss) { <<-SCSS }
      /* Copyright someone. */
      a {
        color: #DDD;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when multi-line comment is not allowed by config' do
    let(:linter_config) { { 'allowed' => '^[/\\* ]*Copyright' } }
    let(:scss) { <<-SCSS }
      /* Other multiline. */
      p {
        color: #DDD;
      }
    SCSS

    it { should report_lint }
  end

  context 'when multi-line comments are preferred' do
    let(:linter_config) { { 'style' => 'loud' } }

    context 'and silent comments are present' do
      let(:scss) { '// A silent comment' }

      it { should report_lint }
    end

    context 'and loud comments are present' do
      let(:scss) { '/* A loud comment */' }

      it { should_not report_lint }
    end
  end
end
