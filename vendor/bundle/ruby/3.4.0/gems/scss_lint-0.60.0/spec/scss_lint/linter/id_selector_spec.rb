require 'spec_helper'

describe SCSSLint::Linter::IdSelector do
  context 'when rule is a type' do
    let(:scss) { 'p {}' }

    it { should_not report_lint }
  end

  context 'when rule is an ID' do
    let(:scss) { '#identifier {}' }

    it { should report_lint line: 1 }
  end

  context 'when rule is a class' do
    let(:scss) { '.class {}' }

    it { should_not report_lint }
  end

  context 'when rule is a type with a class' do
    let(:scss) { 'a.class {}' }

    it { should_not report_lint }
  end

  context 'when rule is a type with an ID' do
    let(:scss) { 'a#identifier {}' }

    it { should report_lint line: 1 }
  end

  context 'when rule is an ID with a pseudo-selector' do
    let(:scss) { '#identifier:active {}' }

    it { should report_lint line: 1 }
  end

  context 'when rule contains a nested rule with type and ID' do
    let(:scss) { <<-SCSS }
      p {
        a#identifier {}
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when rule contains multiple selectors' do
    context 'when all of the selectors are just IDs, classes, or types' do
      let(:scss) { <<-SCSS }
        #identifier,
        .class,
        a {
        }
      SCSS

      it { should report_lint line: 1 }
    end
  end
end
