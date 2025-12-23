require 'spec_helper'

describe SCSSLint::Linter::PrivateNamingConvention do
  context 'when a private variable' do
    context 'is not used in the same file it is defined' do
      let(:scss) { <<-SCSS }
        $_foo: red;
      SCSS

      it { should report_lint line: 1 }
    end

    context 'is used but not defined in the same file' do
      let(:scss) { <<-SCSS }
        p {
          color: $_foo;
          background: rgba($_foo, 0);
        }
      SCSS

      it { should report_lint line: 2 }
      it { should report_lint line: 3 }
    end

    context 'is used but has not been defined quite yet' do
      let(:scss) { <<-SCSS }
        p {
          color: $_foo;
          background: rgba($_foo, 0);
        }

        $_foo: red;
      SCSS

      it { should report_lint line: 2 }
      it { should report_lint line: 3 }
    end

    context 'is defined and used in the same file' do
      let(:scss) { <<-SCSS }
        $_foo: red;

        p {
          color: $_foo;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'is defined and used in the same file in a function' do
      let(:scss) { <<-SCSS }
        $_foo: red;

        p {
          color: rgba($_foo, 0);
        }
      SCSS

      it { should_not report_lint }
    end

    context 'is defined and used in the same file that starts with an @import' do
      let(:scss) { <<-SCSS }
        @import 'bar';

        $_foo: red;

        p {
          color: $_foo;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'is defined and used in a for loop when the file begins with a comment' do
      let(:scss) { <<-SCSS }
        // A comment
        @function _foo() {
          @return red;
        }

        @for $i from 0 through 1 {
          .foo {
            color: _foo();
          }
        }
      SCSS

      it { should_not report_lint }
    end

    context 'is defined and used in the same file when the file begins with a comment' do
      let(:scss) { <<-SCSS }
        // A comment
        @function _foo() {
          @return red;
        }

        .foo {
          color: _foo();
        }
      SCSS

      it { should_not report_lint }
    end

    context 'is defined within a selector and not used' do
      let(:scss) { <<-SCSS }
        p {
          $_foo: red;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'is defined within a selector and used' do
      let(:scss) { <<-SCSS }
        p {
          $_foo: red;
          color: $_foo;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'is defined within a selector and used in a nested selector' do
      let(:scss) { <<-SCSS }
        p {
          $_foo: red;

          a {
            color: $_foo;
          }
        }
      SCSS

      it { should_not report_lint }
    end

    context 'is defined within a selector but too late' do
      let(:scss) { <<-SCSS }
        p {
          color: $_foo;
          $_foo: red;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'is defined within a selector but after the nested selector it is used in' do
      let(:scss) { <<-SCSS }
        p {
          a {
            color: $_foo;
          }

          $_foo: red;
        }
      SCSS

      it { should report_lint line: 3 }
    end

    context 'is defined in a different selector than it is used in' do
      let(:scss) { <<-SCSS }
        p {
          $_foo: red;
        }

        a {
          color: $_foo;
        }
      SCSS

      it { should report_lint line: 6 }
    end
  end

  context 'when a public variable' do
    context 'is used but not defined' do
      let(:scss) { <<-SCSS }
        p {
          color: $foo;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'is defined but not used' do
      let(:scss) { <<-SCSS }
        $foo: red;
      SCSS

      it { should_not report_lint }
    end
  end

  context 'when a private mixin' do
    context 'is not used in the same file it is defined' do
      let(:scss) { <<-SCSS }
        @mixin _foo {
          color: red;
        }
      SCSS

      it { should report_lint line: 1 }
    end

    context 'is used but not defined in the same file' do
      let(:scss) { <<-SCSS }
        p {
          @include _foo;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'is used but has not been defined quite yet' do
      let(:scss) { <<-SCSS }
        p {
          @include _foo;
        }

        @mixin _foo {
          color: red;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'is defined within a selector and not used' do
      let(:scss) { <<-SCSS }
        p {
          @mixin _foo {
            color: red;
          }
        }
      SCSS

      it { should_not report_lint }
    end

    context 'is defined within a selector and used within that selector' do
      let(:scss) { <<-SCSS }
        p {
          @mixin _foo {
            color: red;
          }

          @include _foo;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'is defined within a selector and used within a nested selector' do
      let(:scss) { <<-SCSS }
        p {
          @mixin _foo {
            color: red;
          }

          a {
            @include _foo;
          }
        }
      SCSS

      it { should_not report_lint }
    end

    context 'is defined within a selector and used within that selector too early' do
      let(:scss) { <<-SCSS }
        p {
          @include _foo;

          @mixin _foo {
            color: red;
          }
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'is defined within a selector and used within a nested selector too early' do
      let(:scss) { <<-SCSS }
        p {
          a {
            @include _foo;
          }

          @mixin _foo {
            color: red;
          }
        }
      SCSS

      it { should report_lint line: 3 }
    end

    context 'is defined and used in the same file' do
      let(:scss) { <<-SCSS }
        @mixin _foo {
          color: red;
        }

        p {
          @include _foo;
        }
      SCSS

      it { should_not report_lint }
    end
  end

  context 'when a public mixin' do
    context 'is used but not defined' do
      let(:scss) { <<-SCSS }
        p {
          @include foo;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'is defined but not used' do
      let(:scss) { <<-SCSS }
        @mixin foo {
          color: red;
        }
      SCSS

      it { should_not report_lint }
    end
  end

  describe 'when a private function' do
    context 'is not used in the same file it is defined' do
      let(:scss) { <<-SCSS }
        @function _foo() {
          @return red;
        }
      SCSS

      it { should report_lint line: 1 }
    end

    context 'is used but not defined in the same file' do
      let(:scss) { <<-SCSS }
        p {
          color: _foo();
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'is used but has not been defined quite yet' do
      let(:scss) { <<-SCSS }
        p {
          color: _foo();
        }

        @function _foo() {
          @return red;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'is defined within a selector and not used' do
      let(:scss) { <<-SCSS }
        p {
          @function _foo() {
            @return red;
          }
        }
      SCSS

      it { should_not report_lint }
    end

    context 'is defined within a selector and used within the same selector' do
      let(:scss) { <<-SCSS }
        p {
          @function _foo() {
            @return red;
          }

          color: _foo();
        }
      SCSS

      it { should_not report_lint }
    end

    context 'is defined within a selector and used within a nested selector' do
      let(:scss) { <<-SCSS }
        p {
          @function _foo() {
            @return red;
          }

          a {
            color: _foo();
          }
        }
      SCSS

      it { should_not report_lint }
    end

    context 'is defined within a selector and used within the same selector too early' do
      let(:scss) { <<-SCSS }
        p {
          color: _foo();

          @function _foo() {
            @return red;
          }
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'is defined within a selector and used within a nested too early' do
      let(:scss) { <<-SCSS }
        p {
          a {
            color: _foo();
          }

          @function _foo() {
            @return red;
          }
        }
      SCSS

      it { should report_lint line: 3 }
    end

    context 'is defined and used in the same file' do
      let(:scss) { <<-SCSS }
        @function _foo() {
          @return red;
        }

        p {
          color: _foo();
        }
      SCSS

      it { should_not report_lint }
    end

    context 'is defined and used within another private function' do
      let(:scss) { <<-SCSS }
        @function _foo() {
          @return red;
        }

        @function _bar() {
          @return _foo();
        }

        $use: _bar();
      SCSS

      it { should_not report_lint }
    end
  end

  context 'when a public function' do
    context 'is used but not defined' do
      let(:scss) { <<-SCSS }
        p {
          color: foo();
        }
      SCSS

      it { should_not report_lint }
    end

    context 'is defined but not used' do
      let(:scss) { <<-SCSS }
        @function foo() {
          @return red;
        }
      SCSS

      it { should_not report_lint }
    end
  end
end
