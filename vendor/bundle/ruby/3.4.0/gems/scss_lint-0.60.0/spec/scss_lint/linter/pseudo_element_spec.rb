require 'spec_helper'

describe SCSSLint::Linter::PseudoElement do
  context 'when a pseudo-element has two colons' do
    let(:scss) { <<-SCSS }
      ::before {}
      p::before {}
      p#nav::before {}
      p div::before {}
      p::before div {}
      p, div::before {}
      p::before, div {}
    SCSS

    it { should_not report_lint }
  end

  context 'when a pseudo-element has one colon' do
    let(:scss) { <<-SCSS }
      :before {}
      p:before {}
      p#nav:before {}
      p div:before {}
      p:before div {}
      p, div:before {}
      p:before, div {}
    SCSS

    it { should report_lint line: 1 }
    it { should report_lint line: 2 }
    it { should report_lint line: 3 }
    it { should report_lint line: 4 }
    it { should report_lint line: 5 }
    it { should report_lint line: 6 }
    it { should report_lint line: 7 }
  end

  context 'when a pseudo-selector has one colon' do
    let(:scss) { <<-SCSS }
      :hover {}
      p:hover {}
      p#nav:hover {}
      p div:hover {}
      p:hover div {}
      p, div:hover {}
      p:hover, div {}
    SCSS

    it { should_not report_lint }
  end

  context 'when a pseudo-selector has two colons' do
    let(:scss) { <<-SCSS }
      ::hover {}
      p::hover {}
      p#nav::hover {}
      p div::hover {}
      p::hover div {}
      p, div::hover {}
      p::hover, div {}
    SCSS

    it { should report_lint line: 1 }
    it { should report_lint line: 2 }
    it { should report_lint line: 3 }
    it { should report_lint line: 4 }
    it { should report_lint line: 5 }
    it { should report_lint line: 6 }
    it { should report_lint line: 7 }
  end
end
