require 'spec_helper'

describe SCSSLint::Linter::TrailingSemicolon do
  context 'when a property does not end with a semicolon' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when a property ends with a semicolon' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when an !important property' do
    context 'ends with a semicolon' do
      let(:scss) { <<-SCSS }
        p {
          margin: 0 !important;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'ends with two semicolons' do
      let(:scss) { <<-SCSS }
        p {
          margin: 0 !important;;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'has a space before the semicolon' do
      let(:scss) { <<-SCSS }
        p {
          margin: 0 !important ;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'is missing a semicolon' do
      let(:scss) { <<-SCSS }
        p {
          margin: 0 !important
        }
      SCSS

      it { should report_lint line: 2 }
    end
  end

  context 'when a property ends with a space followed by a semicolon' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0 ;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when a property ends with a semicolon and is followed by a comment' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0;  // This is a comment
        padding: 0; /* This is another comment */
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a property contains nested properties' do
    context 'and there is a value on the namespace' do
      let(:scss) { <<-SCSS }
        p {
          font: 2px/3px {
            style: italic;
            weight: bold;
          }
        }
      SCSS

      it { should_not report_lint }
    end

    context 'and there is no value on the namespace' do
      let(:scss) { <<-SCSS }
        p {
          font: {
            style: italic;
            weight: bold;
          }
        }
      SCSS

      it { should_not report_lint }
    end
  end

  context 'when a nested property does not end with a semicolon' do
    let(:scss) { <<-SCSS }
      p {
        font: {
          weight: bold
        }
      }
    SCSS

    it { should report_lint line: 3 }
  end

  context 'when a multi-line property ends with a semicolon' do
    let(:scss) { <<-SCSS }
      p {
        background:
          top repeat-x url('top-image.jpg'),
          right repeat-y url('right-image.jpg'),
          bottom repeat-x url('bottom-image.jpg'),
          left repeat-y url('left-image.jpg');
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a multi-line property does not end with a semicolon' do
    let(:scss) { <<-SCSS }
      p {
        background:
          top repeat-x url('top-image.jpg'),
          right repeat-y url('right-image.jpg'),
          bottom repeat-x url('bottom-image.jpg'),
          left repeat-y url('left-image.jpg')
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when a oneline rule does not end with a semicolon' do
    let(:scss) { <<-SCSS }
      .foo { border: 0 }
    SCSS

    it { should report_lint line: 1 }
  end

  context 'when a oneline rule has a space before a semicolon' do
    let(:scss) { <<-SCSS }
      .foo { border: 0 ; }
    SCSS

    it { should report_lint line: 1 }
  end

  context 'when @extend does not end with a semicolon' do
    let(:scss) { <<-SCSS }
      .foo {
        @extend %bar
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when @extend ends with a semicolon' do
    let(:scss) { <<-SCSS }
      .foo {
        @extend %bar;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when @include does not end with a semicolon' do
    let(:scss) { <<-SCSS }
      .foo {
        @include bar
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when @include takes a block' do
    let(:scss) { <<-SCSS }
      .foo {
        @include bar {
          border: 0;
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when @include takes a block with nested props' do
    let(:scss) { <<-SCSS }
      .foo {
        @include bar {
          .bar {
            border: 0;
          }
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when @include takes a block with an if-node' do
    let(:scss) { <<-SCSS }
      .foo {
        @include bar {
          @if $var {
            border: 0;
          }
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when @include ends with a semicolon' do
    let(:scss) { <<-SCSS }
      .foo {
        @include bar;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when @import ends with a semicolon' do
    let(:scss) { '@import "something";' }

    it { should_not report_lint }
  end

  context 'when @import does not end with a semicolon' do
    let(:scss) { '@import "something"' }

    it { should report_lint line: 1 }
  end

  context 'when @import has a space before a semicolon' do
    let(:scss) { '@import "something" ;' }

    it { should report_lint line: 1 }
  end

  context 'when an import directive is split over multiple lines' do
    context 'and is missing the trailing semicolon' do
      let(:scss) { <<-SCSS }
        @import 'functions/strip-units',
                'functions/pc'
      SCSS

      it { should report_lint }
    end

    context 'and is not missing the trailing semicolon' do
      let(:scss) { <<-SCSS }
        @import 'functions/strip-units',
                'functions/pc';
      SCSS

      it { should_not report_lint }
    end
  end

  context 'when variable declaration does not end with a semicolon' do
    let(:scss) { <<-SCSS }
      .foo {
        $bar: 1
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when variable declaration ends with a semicolon' do
    let(:scss) { <<-SCSS }
      .foo {
        $bar: 1;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when variable declaration ends with multiple semicolons' do
    let(:scss) { <<-SCSS }
      .foo {
        $bar: 1;;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when interpolation within single quotes is followed by property' do
    context 'and property has a trailing semicolon' do
      let(:scss) { "[class~='\#{$test}'] { width: 100%; }" }

      it { should_not report_lint }
    end

    context 'and property does not have a trailing semicolon' do
      let(:scss) { "[class~='\#{$test}'] { width : 100% }" }

      it { should report_lint }
    end
  end

  context 'when triggering a bug based on Windows IBM437 encoding' do
    let(:scss) { <<-SCSS.force_encoding('IBM437') }
      @charset "UTF-8";

      .foo:before {
        content: '▼';
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a !default variable declaration' do
    context 'ends with a semicolon' do
      let(:scss) { '$foo: bar !default;' }

      it { should_not report_lint }
    end

    context 'ends with two semicolons' do
      let(:scss) { '$foo: bar !default;;' }

      it { should report_lint }
    end

    context 'has a space before the semicolon' do
      let(:scss) { '$foo: bar !default ;' }

      it { should report_lint }
    end

    context 'is missing a semicolon' do
      let(:scss) { '$foo: bar !default' }

      it { should report_lint }
    end
  end

  context 'when a !global variable declaration' do
    context 'ends with a semicolon' do
      let(:scss) { '$foo: bar !global;' }

      it { should_not report_lint }
    end

    context 'ends with two semicolons' do
      let(:scss) { '$foo: bar !global;;' }

      it { should report_lint }
    end

    context 'has a space before the semicolon' do
      let(:scss) { '$foo: bar !global ;' }

      it { should report_lint }
    end

    context 'is missing a semicolon' do
      let(:scss) { '$foo: bar !global' }

      it { should report_lint }
    end
  end

  context 'when the value of the variable is !important' do
    context 'ends with a semicolon' do
      let(:scss) { '$foo: bar !important;' }

      it { should_not report_lint }
    end

    context 'ends with two semicolons' do
      let(:scss) { '$foo: bar !important;;' }

      it { should report_lint }
    end

    context 'has a space before the semicolon' do
      let(:scss) { '$foo: bar !important ;' }

      it { should report_lint }
    end

    context 'is missing a semicolon' do
      let(:scss) { '$foo: bar !important' }

      it { should report_lint }
    end
  end

  context 'when variable declaration is followed by a comment and semicolon' do
    let(:scss) { '$foo: bar // comment;' }

    it { should report_lint }
  end

  context 'when a variable declaration contains parentheses' do
    context 'and ends with a semicolon' do
      let(:scss) { '$foo: ($expr);' }

      it { should_not report_lint }
    end

    context 'and is missing a semicolon' do
      let(:scss) { '$foo: ($expr)' }

      it { should report_lint }
    end
  end

  context 'when a variable declaration contains a list' do
    context 'with parentheses' do
      context 'and ends with a semicolon' do
        let(:scss) { '$foo: (1 2);' }

        it { should_not report_lint }
      end

      context 'and is missing a semicolon' do
        let(:scss) { '$foo: (1 2)' }

        it { should report_lint }
      end

      context 'and a nested list' do
        context 'with parentheses' do
          context 'on a single line' do
            context 'and ends with a semicolon' do
              let(:scss) { '$foo: (1 (2 3));' }

              it { should_not report_lint }
            end

            context 'and is missing a semicolon' do
              let(:scss) { '$foo: (1 (2 3))' }

              it { should report_lint }
            end
          end

          context 'over multiple lines' do
            context 'and ends with a semicolon' do
              let(:scss) { <<-SCSS }
                  $foo: (1
                      (2 3)
                    );
                SCSS
              it { should_not report_lint }
            end

            context 'and is missing a semicolon' do
              let(:scss) { <<-SCSS }
                  $foo: (1
                      (2 3)
                    )
                SCSS

              it { should report_lint }
            end
          end
        end

        context 'without parentheses' do
          context 'and ends with a semicolon' do
            let(:scss) { <<-SCSS }
              $foo: (10
                  20 21 22
                30);
            SCSS

            it { should_not report_lint }
          end

          context 'and is missing a semicolon' do
            let(:scss) { <<-SCSS }
              $foo: (10
                  20 21 22
                30)
            SCSS

            it { should report_lint }
          end
        end
      end
    end

    context 'without parentheses' do
      context 'and ends with a semicolon' do
        let(:scss) { '$foo: 1 2;' }

        it { should_not report_lint }
      end

      context 'and is missing a semicolon' do
        let(:scss) { '$foo: 1 2' }

        it { should report_lint }
      end

      context 'and a nested list' do
        context 'with parentheses' do
          context 'on a single line' do
            context 'and ends with a semicolon' do
              let(:scss) { '$foo: 1 (2 3);' }

              it { should_not report_lint }
            end

            context 'and is missing a semicolon' do
              let(:scss) { '$foo: 1 (2 3)' }

              it { should report_lint }
            end
          end

          context 'over multiple lines' do
            context 'and ends with a semicolon' do
              let(:scss) { <<-SCSS }
                  $foo: 1
                      (2 3);
                SCSS
              it { should_not report_lint }
            end

            context 'and is missing a semicolon' do
              let(:scss) { <<-SCSS }
                  $foo: 1
                      (2 3)
                SCSS

              it { should report_lint }
            end
          end
        end

        context 'without parentheses' do
          context 'and ends with a semicolon' do
            let(:scss) { <<-SCSS }
              $foo: 1,
                  2 3;
            SCSS

            it { should_not report_lint }
          end

          context 'and is missing a semicolon' do
            let(:scss) { <<-SCSS }
              $foo: 1,
                  2 3
            SCSS

            it { should report_lint }
          end
        end
      end
    end
  end

  context 'when a variable declaration contains a map' do
    context 'on a single line' do
      context 'and ends with a semicolon' do
        let(:scss) { '$foo: ("a": ("b": "c"));' }

        it { should_not report_lint }
      end

      context 'and is missing a semicolon' do
        let(:scss) { '$foo: ("a": ("b": "c"))' }

        it { should report_lint }
      end
    end

    context 'over multiple lines' do
      context 'with a trailing comma' do
        context 'and ends with a semicolon' do
          let(:scss) { "$foo: (\n  one: 1,\ntwo: 2,\n);" }

          it { should_not report_lint }
        end

        context 'and is missing a semicolon' do
          let(:scss) { "$foo: (\n  one: 1,\ntwo: 2,\n)" }

          it { should report_lint }
        end
      end

      context 'without a trailing comma' do
        context 'and ends with a semicolon' do
          let(:scss) { "$foo: (\n  one: 1,\ntwo: 2\n);" }

          it { should_not report_lint }
        end

        context 'and is missing a semicolon' do
          let(:scss) { "$foo: (\n  one: 1,\ntwo: 2\n)" }

          it { should report_lint }
        end
      end

      context 'and a nested list' do
        context 'and ends with a semicolon' do
          let(:scss) { <<-SCSS }
            $foo: (
              "a": (
                "b",
                "c"
              )
            );
          SCSS

          it { should_not report_lint }
        end

        context 'and is missing a semicolon' do
          let(:scss) { <<-SCSS }
            $foo: (
              "a": (
                "b",
                "c"
              )
            )
          SCSS

          it { should report_lint }
        end
      end
    end
  end

  context 'with an @extend directive' do
    context 'that ends with a semicolon' do
      let(:scss) { <<-SCSS }
        .foo {
          @extend .bar;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'with two semicolons' do
      let(:scss) { <<-SCSS }
        .foo {
          @extend .bar;;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'with a space before the semicolon' do
      let(:scss) { <<-SCSS }
        .foo {
          @extend .bar ;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'that does not have a semicolon' do
      let(:scss) { <<-SCSS }
        .foo {
          @extend .bar
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'with the !optional flag' do
      context 'that ends with a semicolon' do
        let(:scss) { <<-SCSS }
          .foo {
            @extend .bar !optional;
          }
        SCSS

        it { should_not report_lint }
      end

      context 'with two semicolons' do
        let(:scss) { <<-SCSS }
          .foo {
            @extend .bar !optional;;
          }
        SCSS

        it { should report_lint line: 2 }
      end

      context 'with a space before the semicolon' do
        let(:scss) { <<-SCSS }
          .foo {
            @extend .bar !optional ;
          }
        SCSS

        it { should report_lint line: 2 }
      end

      context 'that does not have a semicolon' do
        let(:scss) { <<-SCSS }
          .foo {
            @extend .bar !optional
          }
        SCSS

        it { should report_lint line: 2 }
      end
    end
  end
end
