require 'spec_helper'

describe SCSSLint::Linter::ColorVariable do
  context 'when a color literal is used in a variable declaration' do
    let(:scss) { <<-SCSS }
      $my-color: #f00;
      $my-shadow: 2px 2px 2px #f00;
    SCSS

    it { should_not report_lint }
  end

  context 'when a color function containing literals is used in a variable declaration' do
    let(:scss) { <<-SCSS }
      $my-color: rgba(0, 0, 0, 0.2);
      $my-shadow: 2px 2px 2px rgba(0, 0, 0, 0.2);
    SCSS

    it { should_not report_lint }
  end

  context 'when a color literal is used in a property' do
    let(:scss) { <<-SCSS }
      p {
        color: #f00;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when a color literal is used in a function call' do
    let(:scss) { <<-SCSS }
      p {
        color: my-func(#f00);
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when a color literal is used in a mixin' do
    let(:scss) { <<-SCSS }
      p {
        @include my-mixin(#f00);
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when a color literal is used in a shorthand property' do
    let(:scss) { <<-SCSS }
      p {
        border: 1px solid #f00;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when a number is used in a property' do
    let(:scss) { <<-SCSS }
      p {
        z-index: 9000;
        transition-duration: 250ms;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a non-color keyword is used in a property' do
    let(:scss) { <<-SCSS }
      p {
        overflow: hidden;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a variable is used in a property' do
    let(:scss) { <<-SCSS }
      p {
        color: $my-color;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a variable is used in a function call' do
    let(:scss) { <<-SCSS }
      p {
        color: my-func($my-color);
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a variable is used in a shorthand property' do
    let(:scss) { <<-SCSS }
      p {
        border: 1px solid $my-color;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a property contains "transparent"' do
    let(:scss) { <<-SCSS }
      p {
        border: 1px solid transparent;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a property with function calls contains "transparent"' do
    let(:scss) { <<-SCSS }
      p {
        border: 1px solid some-func(transparent);
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a color literal is used in the special rgba shorthand helper' do
    let(:scss) { <<-SCSS }
      p {
        color: rgba(#fff, .5);
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when a color literal is used in a map declaration' do
    let(:scss) { <<-SCSS }
      $shades-of-gray: (
        darker:  #4c4c4c,
        dark:    #626262,
        light:   #7d7d7d,
        lighter: #979797
      );
    SCSS

    it { should_not report_lint }
  end

  context 'when a string with a color name is used in a function call' do
    let(:scss) { <<-SCSS }
      p {
        color: my-func('blue');
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

  context 'when a color function containing literals is used in a property' do
    let(:scss) { <<-SCSS }
      p {
        color: rgb(0, 100, 200);
      }
      a {
        color: rgb(0%, 50%, 80%);
      }
      i {
        color: rgba(0, 0, 0, .5);
      }
      span {
        color: hsl(0, 100%, 50%);
      }
      .class {
        color: hsla(0, 100%, 50%, .5);
      }
    SCSS

    it { should report_lint line: 2 }
    it { should report_lint line: 5 }
    it { should report_lint line: 8 }
    it { should report_lint line: 11 }
    it { should report_lint line: 14 }
  end

  context 'when transforming a variable value in a function call' do
    let(:scss) { <<-SCSS }
      p {
        color: rgba($red, .5);
      }

      a {
        color: lighten($red, 5%);
      }
    SCSS

    it { should_not report_lint }
  end
end
