require 'spec_helper'

describe SCSSLint::Linter::SpaceBetweenParens do
  context 'when the opening parens is followed by a space' do
    let(:scss) { <<-SCSS }
      p {
        property: ( value);
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when the closing parens is preceded by a space' do
    let(:scss) { <<-SCSS }
      p {
        property: (value );
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when both parens are space padded' do
    let(:scss) { <<-SCSS }
      p {
        property: ( value );
      }
    SCSS

    it { should report_lint line: 2, count: 2 }
  end

  context 'when neither parens are space padded' do
    let(:scss) { <<-SCSS }
      p {
        property: (value);
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when parens are multi-line' do
    let(:scss) { <<-SCSS }
      p {
        property: (
          value
        );
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when parens are multi-line with tabs' do
    let(:scss) { <<-SCSS }
\t\t\tp {
\t\t\t\tproperty: (
\t\t\t\t\tvalue
\t\t\t\t);
\t\t\t}
    SCSS

    it { should_not report_lint }
  end

  context 'when outer parens are space padded' do
    let(:scss) { <<-SCSS }
      p {
        property: fn( fn2(val1, val2) );
      }
    SCSS

    it { should report_lint line: 2, count: 2 }
  end

  context 'when inner parens are space padded' do
    let(:scss) { <<-SCSS }
      p {
        property: fn(fn2( val1, val2 ));
      }
    SCSS

    it { should report_lint line: 2, count: 2 }
  end

  context 'when both parens are not space padded' do
    let(:scss) { <<-SCSS }
      p {
        property: fn(fn2(val1, val2));
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when both parens are space padded' do
    let(:scss) { <<-SCSS }
      p {
        property: fn( fn2( val1, val2 ) );
      }
    SCSS

    it { should report_lint line: 2, count: 4 }
  end

  context 'when multi level parens are multi-line' do
    let(:scss) { <<-SCSS }
      p {
        property: fn(
          fn2(
            val1, val2
          )
        );
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a 0-argument function has nothing between parens' do
    let(:scss) { <<-SCSS }
      p {
        property: unique-id();
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a 0-argument function has space between parens' do
    let(:scss) { <<-SCSS }
      p {
        property: unique-id(  );
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when parens exist in a silent comment' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0; // Some comment ( with parens )
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when parens exist in an outputted comment' do
    let(:scss) { <<-SCSS }
      p {
        /*
         * Some comment ( with parens )
         */
        margin: 0;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when an import uses parens' do
    let(:scss) { <<-SCSS }
      @import url( foo );
      @import url(bar);
    SCSS

    it { should report_lint line: 1, count: 2 }
  end

  context 'when a variable definition uses parens' do
    let(:scss) { <<-SCSS }
      $family: unquote( "Droid+Sans" );
      $family: unquote("Droid+Sans");
    SCSS

    it { should report_lint line: 1, count: 2 }
  end

  context 'when a variable definition is wrapped in parens' do
    let(:scss) { <<-SCSS }
      $value-map: (text: #00ff00, background: #0000ff, border: #ff0000);
      $value-map: ( text: #00ff00, background: #0000ff, border: #ff0000 );
    SCSS

    it { should report_lint line: 2, count: 2 }
  end

  context 'when a url uses parens' do
    let(:scss) { <<-SCSS }
      p {
        background-image: url( 'bg1.png' );
      }

      code {
        background-image: url('bg2.png');
      }
    SCSS

    it { should report_lint line: 2, count: 2 }
  end

  context 'when a @media directive uses parens' do
    let(:scss) { <<-SCSS }
      @media screen and (orientation: landscape) {
        // Stuff.
      }

      @media screen and ( orientation: landscape ) {
        // Stuff.
      }
    SCSS

    it { should report_lint line: 5, count: 2 }
  end

  context 'when an @at-root directive uses parens' do
    let(:scss) { <<-SCSS }
      @media screen {
        @at-root (without: media) {
          // Stuff.
        }
        @at-root ( with: media ) {
          // Stuff.
        }
      }
    SCSS

    it { should report_lint line: 5, count: 2 }
  end

  context 'when an @if directive uses parens' do
    let(:scss) { <<-SCSS }
      p {
        @if (1 + 2 == 2) { border: 1px; }

        @if ( 1 + 2 == 2 ) { border: 1px; }
      }
    SCSS

    it { should report_lint line: 4, count: 2 }
  end

  context 'when an @each directive uses parens around a list' do
    let(:scss) { <<-SCSS }
      @each $animal in (puma, sea-slug, egret) {
        // Stuff.
      }

      @each $animal in ( puma, sea-slug, egret ) {
        // Stuff.
      }
    SCSS

    it { should report_lint line: 5, count: 2 }
  end

  context 'when an @each directive uses parens' do
    let(:scss) { <<-SCSS }
      /*@each $color, $cursor in (black, default), (blue, pointer) {
        // Stuff.
      }*/

      @each $color, $cursor in ( black, default ), ( blue, pointer ) {
        // Stuff.
      }
    SCSS

    it { should report_lint line: 5, count: 4 }
  end

  context 'when a @mixin uses parens' do
    let(:scss) { <<-SCSS }
      @mixin sexy-border($color, $width) {
        // Stuff.
      }

      @mixin rockin-border( $color, $width ) {
        // Stuff.
      }
    SCSS

    it { should report_lint line: 5, count: 2 }
  end

  context 'when an @include uses parens' do
    let(:scss) { <<-SCSS }
      @mixin sexy-border($color, $width) {
        // Stuff.
      }

      a { @include sexy-border(blue, 1in); }
      p { @include sexy-border( blue, 1in ); }
    SCSS

    it { should report_lint line: 6, count: 2 }
  end

  context 'when a @function uses parens' do
    let(:scss) { <<-SCSS }
      @function grid-width($n) {
        @return $n * 2;
      }

      @function grid-height( $n ) {
        @return $n * 2;
      }
    SCSS

    it { should report_lint line: 5, count: 2 }
  end

  context 'when the number of spaces has been explicitly set' do
    let(:linter_config) { { 'spaces' => 1 } }

    context 'when the opening parens is followed by a space' do
      let(:scss) { <<-SCSS }
        p {
          property: ( value);
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'when the closing parens is preceded by a space' do
      let(:scss) { <<-SCSS }
        p {
          property: (value );
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'when neither parens are space padded' do
      let(:scss) { <<-SCSS }
        p {
          property: (value);
        }
      SCSS

      it { should report_lint line: 2, count: 2 }
    end

    context 'when both parens are space padded' do
      let(:scss) { <<-SCSS }
        p {
          property: ( value );
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when parens are multi-line' do
      let(:scss) { <<-SCSS }
        p {
          property: (
            value
          );
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when parens are multi-line with tabs' do
      let(:scss) { <<-SCSS }
\t\t\t\tp {
\t\t\t\t\tproperty: (
\t\t\t\t\t\tvalue
\t\t\t\t\t);
\t\t\t\t}
      SCSS

      it { should_not report_lint }
    end

    context 'when outer parens are space padded' do
      let(:scss) { <<-SCSS }
        p {
          property: fn( fn2(val1, val2) );
        }
      SCSS

      it { should report_lint line: 2, count: 2 }
    end

    context 'when inner parens are space padded' do
      let(:scss) { <<-SCSS }
        p {
          property: fn(fn2( val1, val2 ));
        }
      SCSS

      it { should report_lint line: 2, count: 2 }
    end

    context 'when both parens are not space padded' do
      let(:scss) { <<-SCSS }
        p {
          property: fn(fn2(val1, val2));
        }
      SCSS

      it { should report_lint line: 2, count: 4 }
    end

    context 'when both parens are space padded' do
      let(:scss) { <<-SCSS }
        p {
          property: fn( fn2( val1, val2 ) );
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when multi level parens are multi-line' do
      let(:scss) { <<-SCSS }
        p {
          property: fn(
            fn2(
              val1, val2
            )
          );
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when a 0-argument function has nothing between parens' do
      let(:scss) { <<-SCSS }
        p {
          property: unique-id();
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'when a 0-argument function has one space between parens' do
      let(:scss) { <<-SCSS }
        p {
          property: unique-id( );
        }
      SCSS

      it { should_not report_lint }
    end
  end
end
