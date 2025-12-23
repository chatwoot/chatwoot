require 'spec_helper'

describe SCSSLint::Linter::LengthVariable do
  context 'when a length literal is used in a variable declaration' do
    let(:scss) { <<-SCSS }
      $my-length: 10px;
    SCSS

    it { should_not report_lint }
  end

  context 'when a length calculation containing literals is used in a variable declaration' do
    let(:scss) { <<-SCSS }
      $my-length: 10px / 2;
    SCSS

    it { should_not report_lint }
  end

  context 'when a length literal is used in a property' do
    let(:scss) { <<-SCSS }
      p {
        width: 10px;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when a negative length literal is used in a property' do
    let(:scss) { <<-SCSS }
      p {
        margin: -10px;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when a length literal is used in a function call' do
    let(:scss) { <<-SCSS }
      p {
        width: my-func(10px);
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when a length literal is used in a mixin' do
    let(:scss) { <<-SCSS }
      p {
        @include my-mixin(10px);
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when a length literal is used in a shorthand property' do
    let(:scss) { <<-SCSS }
      p {
        text-shadow: 10px 10px black;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when a length literal is used as a mixin default argument' do
    let(:scss) { <<-SCSS }
      @mixin checkbox ($length: 10px) {
        width: $length;
      }
    SCSS

    it { should report_lint line: 1 }
  end

  context 'when a number is used in a property' do
    let(:scss) { <<-SCSS }
      p {
        z-index: 9000;
        transition-duration: 250ms;
        line-height: 1;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a non-length keyword is used in a property' do
    let(:scss) { <<-SCSS }
      p {
        width: auto;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a variable is used in a property' do
    let(:scss) { <<-SCSS }
      p {
        width: $my-length;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a variable is used in a function call' do
    let(:scss) { <<-SCSS }
      p {
        width: my-func($my-length);
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a variable operated with a literal' do
    let(:scss) { <<-SCSS }
      p {
        width: $my-length + 10px;
        height: $my-length - 10px;
        top: $my-length * 10px;
        bottom: $my-length - 10px;
      }
    SCSS

    it { should report_lint line: 2 }
    it { should report_lint line: 3 }
    it { should report_lint line: 4 }
    it { should report_lint line: 5 }
  end

  context 'when a variable unary operation' do
    let(:scss) { <<-SCSS }
      p {
        top: -$my-length;
        bottom: +$my-length;
      }
    SCSS

    it { should_not report_lint line: 2 }
    it { should_not report_lint line: 3 }
  end

  context 'when a variable is used in a shorthand property' do
    let(:scss) { <<-SCSS }
      p {
        border: $my-length solid black;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a property contains "auto"' do
    let(:scss) { <<-SCSS }
      p {
        margin: auto;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a length literal is used in a map declaration' do
    let(:scss) { <<-SCSS }
      $margins: (
        small:  4px,
        medium: 8px,
        large:  16px
      );
    SCSS

    it { should_not report_lint }
  end

  context 'when a string with a length is used in a function call' do
    let(:scss) { <<-SCSS }
      p {
        width: my-func('10px');
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a variable is interpolated in a multiline comment' do
    let(:scss) { <<-SCSS }
      $a: 0;

      /*!
       * test \#{a}
       */
    SCSS

    it { should_not report_lint }
  end

  context 'when using calc' do
    let(:scss) { <<-SCSS }
      p {
        width: calc(100em + 5px);
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when using calc with no spacing' do
    let(:scss) { <<-SCSS }
      p {
        width: calc(100em+5px);
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when using calc with all interpolations' do
    let(:scss) { <<-SCSS }
      p {
        width: calc(\#{$my-width} + \#{$my-spacing});
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a variable is interpolated' do
    let(:scss) { <<-SCSS }
      p {
        width: calc(\#{$my-length} + 5px)
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when a literal is interpolated' do
    let(:scss) { <<-SCSS }
      p {
        width: calc(\#{10px} + $my-length)
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when a string is interpolated' do ## analogous to the ColorVariable linter
    let(:scss) { <<-SCSS }
      p {
        width: calc(\#{'10px'} + $my-length)
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when disambiguating with brackets' do
    let(:scss) { <<-SCSS }
      p {
        margin: (-10px) (-10px);
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'in the awkward looking font shorthand' do
    let(:scss) { <<-SCSS }
      strong { font: bold 10px/14px sans-serif; }
      em { font: bold $my-font-size/14px sans-serif; }
      blockquote { font: bold 10px/$my-line-height sans-serif; }
      p { font: bold $my-font-size/1 sans-serif; }
    SCSS

    it { should report_lint line: 1 }
    it { should report_lint line: 2 }
    it { should report_lint line: 3 }
    it { should_not report_lint line: 4 }
  end

  context 'when a length is used in a media query' do
    let(:scss) { <<-SCSS }
      @media (min-width:100px) {
        p { color: red; }
      }
      @media (max-width: 100px ) {
        p { color: blue; }
      }
      @media (max-width: 100px*5) {
        p { color: orange; }
      }
      @media (min-device-pixel-ratio: 2) {
        p { color: green; }
      }
    SCSS

    it { should report_lint line: 1 }
    it { should report_lint line: 4 }
    it { should report_lint line: 7 }
    it { should_not report_lint line: 10 }
  end

  context 'when length is allowed' do
    let(:linter_config) { { 'allowed_lengths' => %w[100px 0 5px] } }
    context 'when using an allowed length' do
      let(:scss) { <<-SCSS }
        p {
          width: 100px;
          border-width: 0;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when using an allowed length in a calculation' do
      let(:scss) { <<-SCSS }
        p {
          margin: -(5px);
          border-width: $my-variable + 5px;
          width: calc(100px + \#{$my-margin});
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when using a similar disallowed length' do
      let(:scss) { <<-SCSS }
        p {
          width: 101px;
          margin: 100em;
          border-width: 0;
        }
      SCSS

      it { should report_lint line: 2 }
      it { should report_lint line: 3 }
      it { should_not report_lint line: 4 }
    end
  end

  context 'when using a length with an allowed property' do
    let(:linter_config) { { 'allowed_properties' => %w[text-shadow box-shadow] } }
    let(:scss) { <<-SCSS }
      p {
        text-shadow: 10px 10px 5px blue;
        box-shadow: 10px 10px 5px red;
        width: $my-variable;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a length calculation containing literals is used in a property' do
    let(:scss) { <<-SCSS }
      p {
        width: 10px + 10px;
      }
      a {
        width: 10px - 10px;
      }
      i {
        width: 10px / 4;
      }
      span {
        width: 10px * 2;
      }
      .class {
        width: -10px + 11;
      }
    SCSS

    it { should report_lint line: 2 }
    it { should report_lint line: 5 }
    it { should report_lint line: 8 }
    it { should report_lint line: 11 }
    it { should report_lint line: 14 }
  end
end
