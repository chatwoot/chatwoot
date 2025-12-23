require 'spec_helper'

describe SCSSLint::Linter::DeclarationOrder do
  context 'when rule is empty' do
    let(:scss) { <<-SCSS }
      p {
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when rule contains only properties' do
    let(:scss) { <<-SCSS }
      p {
        background: #000;
        margin: 5px;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when rule contains only mixins' do
    let(:scss) { <<-SCSS }
      p {
        @include border-radius(5px);
        @include box-shadow(5px);
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when rule contains no mixins or properties' do
    let(:scss) { <<-SCSS }
      p {
        a {
          color: #f00;
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when rule contains properties after nested rules' do
    let(:scss) { <<-SCSS }
      p {
        a {
          color: #f00;
        }
        color: #f00;
        margin: 5px;
      }
    SCSS

    it { should report_lint }
  end

  context 'when @extend appears before any properties or rules' do
    let(:scss) { <<-SCSS }
      .warn {
        font-weight: bold;
      }
      .error {
        @extend .warn;
        color: #f00;
        a {
          color: #ccc;
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when @extend appears after a property' do
    let(:scss) { <<-SCSS }
      .warn {
        font-weight: bold;
      }
      .error {
        color: #f00;
        @extend .warn;
        a {
          color: #ccc;
        }
      }
    SCSS

    it { should report_lint line: 6 }
  end

  context 'when nested rule set' do
    context 'contains @extend before a property' do
      let(:scss) { <<-SCSS }
        p {
          a {
            @extend foo;
            color: #f00;
          }
        }
      SCSS

      it { should_not report_lint }
    end

    context 'contains @extend after a property' do
      let(:scss) { <<-SCSS }
        p {
          a {
            color: #f00;
            @extend foo;
          }
        }
      SCSS

      it { should report_lint line: 4 }
    end

    context 'contains @extend after nested rule set' do
      let(:scss) { <<-SCSS }
        p {
          a {
            span {
              color: #000;
            }
            @extend foo;
          }
        }
      SCSS

      it { should report_lint line: 6 }
    end
  end

  context 'when @include appears' do
    context 'before a property and rule set' do
      let(:scss) { <<-SCSS }
        .error {
          @include warn;
          color: #f00;
          a {
            color: #ccc;
          }
        }
      SCSS

      it { should_not report_lint }
    end

    context 'after a property and before a rule set' do
      let(:scss) { <<-SCSS }
        .error {
          color: #f00;
          @include warn;
          a {
            color: #ccc;
          }
        }
      SCSS

      it { should report_lint line: 3 }
    end
  end

  context 'when @include that features @content appears' do
    context 'before a property' do
      let(:scss) { <<-SCSS }
        .foo {
          @include breakpoint("phone") {
            color: #ccc;
          }
          color: #f00;
        }
      SCSS

      it { should report_lint line: 5 }
    end

    context 'after a property' do
      let(:scss) { <<-SCSS }
        .foo {
          color: #f00;
          @include breakpoint("phone") {
            color: #ccc;
          }
        }
      SCSS

      it { should_not report_lint }
    end

    context 'before an @extend' do
      let(:scss) { <<-SCSS }
        .foo {
          @include breakpoint("phone") {
            color: #ccc;
          }
          @extend .bar;
        }
      SCSS

      it { should report_lint line: 5 }
    end

    context 'before a rule set' do
      let(:scss) { <<-SCSS }
        .foo {
          @include breakpoint("phone") {
            color: #ccc;
          }
          a {
            color: #fff;
          }
        }
      SCSS

      it { should_not report_lint }
    end

    context 'after a rule set' do
      let(:scss) { <<-SCSS }
        .foo {
          a {
            color: #fff;
          }
          @include breakpoint("phone") {
            color: #ccc;
          }
        }
      SCSS

      it { should report_lint line: 5 }
    end

    context 'with its own nested rule set' do
      context 'before a property' do
        let(:scss) { <<-SCSS }
          @include breakpoint("phone") {
            a {
              color: #000;
            }
            color: #ccc;
          }
        SCSS

        it { should report_lint line: 5 }
      end

      context 'after a property' do
        let(:scss) { <<-SCSS }
          @include breakpoint("phone") {
            color: #ccc;
            a {
              color: #000;
            }
          }
        SCSS

        it { should_not report_lint }
      end
    end
  end

  context 'when the nesting is crazy deep' do
    context 'and nothing is wrong' do
      let(:scss) { <<-SCSS }
        div {
          ul {
            @extend .thing;
            li {
              @include box-shadow(yes);
              background: green;
              a {
                span {
                  @include border-radius(5px);
                  color: #000;
                }
              }
            }
          }
        }
      SCSS

      it { should_not report_lint }
    end

    context 'and something is wrong' do
      let(:scss) { <<-SCSS }
        div {
          ul {
            li {
              a {
                span {
                  color: #000;
                  @include border-radius(5px);
                }
              }
            }
          }
        }
      SCSS

      it { should report_lint line: 7 }
    end
  end

  context 'when inside a @media query and rule set' do
    context 'contains @extend before a property' do
      let(:scss) { <<-SCSS }
        @media only screen and (max-width: 1px) {
          a {
            @extend foo;
            color: #f00;
          }
        }
      SCSS

      it { should_not report_lint }
    end

    context 'contains @extend after a property' do
      let(:scss) { <<-SCSS }
        @media only screen and (max-width: 1px) {
          a {
            color: #f00;
            @extend foo;
          }
        }
      SCSS

      it { should report_lint line: 4 }
    end

    context 'contains @extend after nested rule set' do
      let(:scss) { <<-SCSS }
        @media only screen and (max-width: 1px) {
          a {
            span {
              color: #000;
            }
            @extend foo;
          }
        }
      SCSS

      it { should report_lint line: 6 }
    end
  end

  context 'when a pseudo-element appears before a property' do
    let(:scss) { <<-SCSS }
      a {
        &:hover {
          color: #000;
        }
        color: #fff;
      }
    SCSS

    it { should report_lint line: 5 }
  end

  context 'when a pseudo-element appears after a property' do
    let(:scss) { <<-SCSS }
      a {
        color: #fff;
        &:focus {
          color: #000;
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a chained selector appears after a property' do
    let(:scss) { <<-SCSS }
      a {
        color: #fff;
        &.is-active {
          color: #000;
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a chained selector appears before a property' do
    let(:scss) { <<-SCSS }
      a {
        &.is-active {
          color: #000;
        }
        color: #fff;
      }
    SCSS

    it { should report_lint line: 5 }
  end

  context 'when a selector with parent reference appears after a property' do
    let(:scss) { <<-SCSS }
      a {
        color: #fff;
        .is-active & {
          color: #000;
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a selector with parent reference appears before a property' do
    let(:scss) { <<-SCSS }
      a {
        .is-active & {
          color: #000;
        }
        color: #fff;
      }
    SCSS

    it { should report_lint line: 5 }
  end

  context 'when a pseudo-element appears after a property' do
    let(:scss) { <<-SCSS }
      a {
        color: #fff;
        &:before {
          color: #000;
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a pseudo-element appears before a property' do
    let(:scss) { <<-SCSS }
      a {
        &:before {
          color: #000;
        }
        color: #fff;
      }
    SCSS

    it { should report_lint line: 5 }
  end

  context 'when a direct descendent appears after a property' do
    let(:scss) { <<-SCSS }
      a {
        color: #fff;
        > .foo {
          color: #000;
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a direct descendent appears before a property' do
    let(:scss) { <<-SCSS }
      a {
        > .foo {
          color: #000;
        }
        color: #fff;
      }
    SCSS

    it { should report_lint line: 5 }
  end

  context 'when an adjacent sibling appears after a property' do
    let(:scss) { <<-SCSS }
      a {
        color: #fff;
        & + .foo {
          color: #000;
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when an adjacent sibling appears before a property' do
    let(:scss) { <<-SCSS }
      a {
        & + .foo {
          color: #000;
        }
        color: #fff;
      }
    SCSS

    it { should report_lint line: 5 }
  end

  context 'when a general sibling appears after a property' do
    let(:scss) { <<-SCSS }
      a {
        color: #fff;
        & ~ .foo {
          color: #000;
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a general sibling appears before a property' do
    let(:scss) { <<-SCSS }
      a {
        & ~ .foo {
          color: #000;
        }
        color: #fff;
      }
    SCSS

    it { should report_lint line: 5 }
  end

  context 'when a descendent appears after a property' do
    let(:scss) { <<-SCSS }
      a {
        color: #fff;
        .foo {
          color: #000;
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a descendent appears before a property' do
    let(:scss) { <<-SCSS }
      a {
        .foo {
          color: #000;
        }
        color: #fff;
      }
    SCSS

    it { should report_lint line: 5 }
  end

  context 'when order within a media query is incorrect' do
    let(:scss) { <<-SCSS }
      @media screen and (max-width: 600px) {
        @include mix1();

        width: 100%;
        height: 100%;

        @include mix2();
      }
    SCSS

    it { should report_lint }
  end
end
