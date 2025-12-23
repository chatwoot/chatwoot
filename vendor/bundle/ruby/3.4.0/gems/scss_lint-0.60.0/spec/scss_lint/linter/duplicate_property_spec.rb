require 'spec_helper'

describe SCSSLint::Linter::DuplicateProperty do
  context 'when rule set is empty' do
    let(:scss) { <<-SCSS }
      p {
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when rule set contains no duplicates' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0;
        padding: 0;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when rule set contains duplicates' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0;
        padding: 0;
        margin: 1em;
      }
    SCSS

    it { should report_lint line: 4 }
  end

  context 'when rule set contains duplicates but only on vendor-prefixed property values' do
    let(:scss) { <<-SCSS }
      p {
        background: -moz-linear-gradient(center top , #fff, #000);
        background: -ms-linear-gradient(center top , #fff, #000);
        background: -o-linear-gradient(center top , #fff, #000);
        background: -webkit-gradient(linear, left top, left bottom, from(#fff), to(#000));
        background: linear-gradient(center top , #fff, #000);
        margin: 1em;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when placeholder contains duplicates but only on vendor-prefixed values' do
    let(:scss) { <<-SCSS }
      %cursor-grabbing {
        cursor: -moz-grabbing;
        cursor: -webkit-grabbing;
        cursor: grabbing;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when placeholder contains exact duplicates besides for vendor-prefixed values' do
    let(:scss) { <<-SCSS }
      %cursor-grabbing {
        cursor: grabbing;
        cursor: grabbing;
      }
    SCSS

    it { should report_lint line: 3 }
  end

  context 'when mixin contains duplicates but only on vendor-prefixed values' do
    let(:scss) { <<-SCSS }
      @mixin cursor-grabbing($num) {
        cursor: -moz-grabbing;
        cursor: -webkit-grabbing;
        cursor: -foo-grabbing unquote('!important');
        cursor: grabbing;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when mixin contains duplicates besides for vendor-prefixed values' do
    let(:scss) { <<-SCSS }
      @mixin cursor-grabbing($num) {
        cursor: grabbing;
        cursor: grabbing;
      }
    SCSS

    it { should report_lint line: 3 }
  end

  context 'when rule set contains exact duplicates besides for vendor-prefixed property values' do
    let(:scss) { <<-SCSS }
      p {
        background: -moz-linear-gradient(center top , #fff, #000);
        background: -ms-linear-gradient(center top , #fff, #000);
        background: -o-linear-gradient(center top , #fff, #000);
        background: -webkit-gradient(linear, left top, left bottom, from(#fff), to(#000));
        background: linear-gradient(center top , #fff, #000);
        background: linear-gradient(center top , #fff, #000);
        margin: 1em;
      }
    SCSS

    it { should report_lint line: 7 }
  end

  context 'when rule set contains non-exact duplicates besides for vendor-prefixed values' do
    let(:scss) { <<-SCSS }
      p {
        background: -moz-linear-gradient(center top , #fff, #000);
        background: -ms-linear-gradient(center top , #fff, #000);
        background: -o-linear-gradient(center top , #fff, #000);
        background: -webkit-gradient(linear, left top, left bottom, from(#fff), to(#000));
        background: linear-gradient(center top , #fff, #000);
        background: linear-gradient-b(center top , #fff, #000);
        margin: 1em;
      }
    SCSS

    it { should report_lint line: 7 }
  end

  context 'when rule set contains multiple duplicates' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0;
        padding: 0;
        margin: 1em;
        margin: 2em;
      }
    SCSS

    it { should report_lint line: 4 }
    it { should report_lint line: 5 }
  end

  context 'when rule set contains duplicate properties with interpolation' do
    let(:scss) { <<-SCSS }
      p {
        $direction: 'right';
        margin-\#{direction}: 0;
        $direction: 'left';
        margin-\#{direction}: 0;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when property contains a variable' do
    let(:scss) { <<-SCSS }
      p {
        color: $some-color;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when property contains a duplicate variable' do
    let(:scss) { <<-SCSS }
      p {
        color: $some-color;
        color: $some-color;
      }
    SCSS

    it { should report_lint line: 3 }
  end

  context 'when property contains a duplicate value in a nested rule set' do
    let(:scss) { <<-SCSS }
      .outer {
        .inner {
          color: $some-color;
          color: $some-color;
        }
      }
    SCSS

    it { should report_lint line: 4 }
  end

  context 'when consecutive duplicate properties are allowed' do
    let(:linter_config) { { 'ignore_consecutive' => true } }

    context 'when rule set contains consecutive duplicates' do
      let(:scss) { <<-SCSS }
        p {
          background-color: #fff;
          background-color: rgba(255, 255, 255, 0.7);
          background-color: a-third-thing;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when rule set contains non-consecutive duplicates' do
      let(:scss) { <<-SCSS }
        p {
          margin: 0;
          padding: 0;
          margin: 1em;
        }
      SCSS

      it { should report_lint line: 4 }
    end
  end

  context 'when specific consecutive duplicate properties are allowed' do
    let(:linter_config) { { 'ignore_consecutive' => %w[background-color transition] } }

    context 'when rule set contains consecutive duplicates in whitelist' do
      let(:scss) { <<-SCSS }
        p {
          background-color: #fff;
          background-color: rgba(255, 255, 255, 0.7);
          background-color: a-third-thing;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when rule set contains consecutive duplicates not in whitelist' do
      let(:scss) { <<-SCSS }
        p {
          margin: 0;
          margin: 5px;
        }
      SCSS

      it { should report_lint line: 3 }
    end
  end

  context 'when media query contains duplicates' do
    let(:scss) { <<-SCSS }
      p {
        @media (min-width: 400px) {
          margin: 0;
          padding: 0;
          margin: 1em;
        }
      }
    SCSS

    it { should report_lint line: 5 }
  end
end
