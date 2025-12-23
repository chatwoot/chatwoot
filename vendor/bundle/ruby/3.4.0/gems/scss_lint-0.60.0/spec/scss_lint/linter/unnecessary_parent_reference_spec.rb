require 'spec_helper'

describe SCSSLint::Linter::UnnecessaryParentReference do
  context 'when an amperand precedes a direct descendant operator' do
    let(:scss) { <<-SCSS }
      p {
        & > a {}
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when an amperand precedes a general child' do
    let(:scss) { <<-SCSS }
      p {
        & a {}
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when an amperand is chained with class' do
    let(:scss) { <<-SCSS }
      p {
        &.foo {}
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when an amperand follows a direct descendant operator' do
    let(:scss) { <<-SCSS }
      p {
        .foo > & {}
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when an ampersand precedes a sibling operator' do
    let(:scss) { <<-SCSS }
      p {
        & + & {}
        & ~ & {}
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when multiple ampersands exist with one concatenated' do
    let(:scss) { <<-SCSS }
      p {
        & + &:hover {}
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when an amperand is used in a comma sequence to DRY up code' do
    let(:scss) { <<-SCSS }
      p {
        &,
        .foo,
        .bar {
          margin: 0;
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when an ampersand is used by itself' do
    let(:scss) { <<-SCSS }
      p {
        & {}
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when an ampersand is used in concatentation' do
    let(:scss) { <<-SCSS }
      .icon {
        &-small {}
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when an ampersand is used in concatentation following an ampersand' do
    let(:scss) { <<-SCSS }
      .icon {
        & &-small {}
      }
    SCSS

    it { should_not report_lint }
  end
end
