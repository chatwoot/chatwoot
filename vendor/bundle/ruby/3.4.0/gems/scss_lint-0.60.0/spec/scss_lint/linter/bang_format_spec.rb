require 'spec_helper'

describe SCSSLint::Linter::BangFormat do
  context 'when no bang is used' do
    let(:scss) { <<-SCSS }
      p {
        color: #000;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when !important is used correctly' do
    let(:scss) { <<-SCSS }
      p {
        color: #000 !important;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when !important has no space before' do
    let(:scss) { <<-SCSS }
      p {
        color: #000!important;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when !important has a space after' do
    let(:scss) { <<-SCSS }
      p {
        color: #000 ! important;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when !important has a space after and config allows it' do
    let(:linter_config) { { 'space_before_bang' => true, 'space_after_bang' => true } }

    let(:scss) { <<-SCSS }
      p {
        color: #000 ! important;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when !important has a space before but config does not allow it' do
    let(:linter_config) { { 'space_before_bang' => false, 'space_after_bang' => true } }

    let(:scss) { <<-SCSS }
      p {
        color: #000 ! important;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when !important has no spaces around and config allows it' do
    let(:linter_config) { { 'space_before_bang' => false, 'space_after_bang' => false } }

    let(:scss) { <<-SCSS }
      p {
        color: #000!important;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'with a !default variable declaration' do
    context 'and !default is used correctly' do
      let(:scss) { <<-SCSS }
        $foo: bar !default;
      SCSS

      it { should_not report_lint }
    end

    context 'and there is no space before' do
      let(:scss) { <<-SCSS }
        $foo: bar!default;
      SCSS

      it { should report_lint line: 1 }
    end
  end

  context 'with a !global variable declaration' do
    context 'and !global is used correctly' do
      let(:scss) { <<-SCSS }
        $foo: bar !global;
      SCSS

      it { should_not report_lint }
    end

    context 'and there is no space before' do
      let(:scss) { <<-SCSS }
        $foo: bar!global;
      SCSS

      it { should report_lint line: 1 }
    end
  end

  context 'with an !optional @extend directive' do
    context 'and !optional is used correctly' do
      let(:scss) { <<-SCSS }
        .foo {
          @extend .bar !optional;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'and there is no space before' do
      let(:scss) { <<-SCSS }
        .foo {
          @extend .bar!optional;
        }
      SCSS

      it { should report_lint line: 2 }
    end
  end

  context 'when ! appears within a string' do
    let(:scss) { <<-SCSS }
      p:before { content: "!important"; }
      p:before { content: "imp!ortant"; }
      p:after { content: '!'; }
      div:before { content: 'important!'; }
      div:after { content: '  !  '; }
      p[attr="foo!bar"] {};
      p[attr='foo!bar'] {};
      p[attr="!foobar"] {};
      p[attr='foobar!'] {};
      $foo: 'bar!';
      $foo: "bar!";
      $foo: "!bar";
      $foo: "b!ar";
    SCSS

    it { should_not report_lint }
  end

  context 'when !<word> is not followed by a semicolon' do
    let(:scss) { <<-SCSS }
      .class {
        margin: 0 !important
      }
    SCSS

    it 'does not loop forever' do
      should_not report_lint
    end
  end

  context 'when property contains a list literal with an empty list' do
    let(:scss) { <<-SCSS }
      p {
        content: 0 ();
      }
    SCSS

    it { should_not report_lint }
  end
end
