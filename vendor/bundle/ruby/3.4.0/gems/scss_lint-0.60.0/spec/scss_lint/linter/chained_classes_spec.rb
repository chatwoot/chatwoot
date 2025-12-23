require 'spec_helper'

describe SCSSLint::Linter::ChainedClasses do
  context 'with a single class' do
    let(:scss) { <<-SCSS }
      .class {}
    SCSS

    it { should_not report_lint }
  end

  context 'with a single class with a descendant ' do
    let(:scss) { <<-SCSS }
      .class .descendant {}
    SCSS

    it { should_not report_lint }
  end

  context 'with a chained class' do
    let(:scss) { <<-SCSS }
      .chained.class {}
    SCSS

    it { should report_lint line: 1 }
  end

  context 'with a chained class in a nested rule set' do
    let(:scss) { <<-SCSS }
      p {
        .chained.class {}
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'with a chained class in part of a sequence' do
    let(:scss) { <<-SCSS }
      .some .sequence .with .chained.class .in .it {}
    SCSS

    it { should report_lint line: 1 }
  end

  context 'with a chained class in a multiline comma sequence' do
    let(:scss) { <<-SCSS }
      .one,
      .two.three {}
    SCSS

    it { should report_lint line: 2 }
  end
end
