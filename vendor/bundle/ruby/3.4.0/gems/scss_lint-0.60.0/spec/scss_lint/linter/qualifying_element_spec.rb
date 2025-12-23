require 'spec_helper'

describe SCSSLint::Linter::QualifyingElement do
  context 'when selector does not include an element' do
    let(:scss) { <<-SCSS }
      .foo {}
      #bar {}
      [foobar] {}
      .foo .bar {}
      #bar > .foo {}
      [foobar] #bar .foo {}
    SCSS

    it { should_not report_lint }
  end

  context 'when selector includes an element' do
    context 'and element does not qualify' do
      let(:scss) { <<-SCSS }
        ul {}
      SCSS

      it { should_not report_lint }
    end

    context 'and element qualifies class' do
      let(:scss) { <<-SCSS }
        ul.list {}
      SCSS

      it { should report_lint line: 1 }
    end

    context 'and element qualifies attribute' do
      let(:scss) { <<-SCSS }
        a[href] {}
      SCSS

      it { should report_lint line: 1 }
    end

    context 'and element qualifies id' do
      let(:scss) { <<-SCSS }
        ul#list {}
      SCSS

      it { should report_lint line: 1 }
    end

    context 'and selector is in a group' do
      context 'and element does not qualify' do
        let(:scss) { <<-SCSS }
          .list li,
          .item > span {}
        SCSS

        it { should_not report_lint }
      end

      context 'and element qualifies class' do
        let(:scss) { <<-SCSS }
          .item span,
          ul > li.item {}
        SCSS

        it { should report_lint line: 1 }
      end

      context 'and element qualifies attribute' do
        let(:scss) { <<-SCSS }
          .item + span,
          li a[href] {}
        SCSS

        it { should report_lint line: 1 }
      end

      context 'and element qualifies id' do
        let(:scss) { <<-SCSS }
          #foo,
          li#item + li {}
        SCSS

        it { should report_lint line: 1 }
      end
    end

    context 'and selector involves a combinator' do
      context 'and element does not qualify' do
        let(:scss) { <<-SCSS }
          .list li {}
          .list > li {}
          .item + li {}
          .item ~ li {}
        SCSS

        it { should_not report_lint }
      end

      context 'and element qualifies class' do
        let(:scss) { <<-SCSS }
          ul > li.item {}
        SCSS

        it { should report_lint line: 1 }
      end

      context 'and element qualifies attribute' do
        let(:scss) { <<-SCSS }
          li a[href] {}
        SCSS

        it { should report_lint line: 1 }
      end

      context 'and element qualifies id' do
        let(:scss) { <<-SCSS }
          li#item + li {}
        SCSS

        it { should report_lint line: 1 }
      end
    end
  end
end
