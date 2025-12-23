require 'spec_helper'

describe SCSSLint::Linter::NameFormat do
  shared_examples 'hyphenated_lowercase' do
    context 'when no variable, functions, or mixin declarations exist' do
      let(:scss) { <<-SCSS }
        p {
          margin: 0;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when a variable name contains a hyphen' do
      let(:scss) { '$content-padding: 10px;' }

      it { should_not report_lint }
    end

    context 'when a variable name contains an underscore' do
      let(:scss) { '$content_padding: 10px;' }

      it { should report_lint line: 1 }
    end

    context 'when a variable name contains an uppercase character' do
      let(:scss) { '$contentPadding: 10px;' }

      it { should report_lint line: 1 }
    end

    context 'when a function is declared with a capital letter' do
      let(:scss) { <<-SCSS }
        @function badFunction() {
        }
      SCSS

      it { should report_lint line: 1 }
    end

    context 'when a function is declared with an underscore' do
      let(:scss) { <<-SCSS }
        @function bad_function() {
        }
      SCSS

      it { should report_lint line: 1 }
    end

    context 'when a function contains variables with capital letters' do
      let(:scss) { <<-SCSS }
        p {
          content: good-function($badVariable);
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'when a mixin is declared with a capital letter' do
      let(:scss) { <<-SCSS }
        @mixin badMixin() {
        }
      SCSS

      it { should report_lint line: 1 }
    end

    context 'when a mixin is declared with an underscore' do
      let(:scss) { <<-SCSS }
        @mixin bad_mixin() {
        }
      SCSS

      it { should report_lint line: 1 }
    end

    context 'when no invalid usages exist' do
      let(:scss) { <<-SCSS }
        p {
          margin: 0;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when a referenced variable name has a capital letter' do
      let(:scss) { <<-SCSS }
        p {
          margin: $badVar;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'when a referenced variable name has an underscore' do
      let(:scss) { <<-SCSS }
        p {
          margin: $bad_var;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'when a referenced function name has a capital letter' do
      let(:scss) { <<-SCSS }
        p {
          margin: badFunc();
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'when a referenced function name has an underscore' do
      let(:scss) { <<-SCSS }
        p {
          margin: bad_func();
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'when an included mixin name has a capital letter' do
      let(:scss) { '@include badMixin();' }

      it { should report_lint line: 1 }
    end

    context 'when an included mixin name has an underscore' do
      let(:scss) { '@include bad_mixin();' }

      it { should report_lint line: 1 }
    end

    context 'when function is a transform function' do
      %w[rotateX rotateY rotateZ
         scaleX scaleY scaleZ
         skewX skewY
         translateX translateY translateZ].each do |function|
        let(:scss) { <<-SCSS }
          p {
            transform: #{function}(2);
          }
        SCSS

        it { should_not report_lint }
      end
    end

    context 'when mixin is a transform function' do
      let(:scss) { <<-SCSS }
        p {
          @include translateX(2);
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when using whitelisted css function' do
      let(:scss) { <<-SCSS }
        .gradient {
          background: linear-gradient(#000, #fff);
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when a mixin contains keyword arguments with underscores' do
      let(:scss) { '@include mixin($some_var: 4);' }

      it { should report_lint }
    end

    context 'when a mixin contains keyword arguments with hyphens' do
      let(:scss) { '@include mixin($some-var: 4);' }

      it { should_not report_lint }
    end
  end

  context 'when no configuration is specified' do
    it_behaves_like 'hyphenated_lowercase'

    context 'when a name contains a leading underscore' do
      let(:scss) { <<-SCSS }
        @function _private-method() {
        }
      SCSS

      it { should_not report_lint }
    end
  end

  context 'when leading underscores are not allowed' do
    let(:linter_config) { { 'allow_leading_underscore' => false } }

    it_behaves_like 'hyphenated_lowercase'

    context 'when a name contains a leading underscore' do
      let(:scss) { <<-SCSS }
        @function _private-method() {
        }
      SCSS

      it { should report_lint line: 1 }
    end
  end

  context 'when the camel_case convention is specified' do
    let(:linter_config) { { 'convention' => 'camel_case' } }

    context 'when a name contains all lowercase letters' do
      let(:scss) { '$variable: 1;' }

      it { should_not report_lint }
    end

    context 'when a name contains all lowercase letters and underscores' do
      let(:scss) { '$my_variable: 1;' }

      it { should report_lint }
    end

    context 'when a name contains all lowercase letters and hyphens' do
      let(:scss) { '$my-variable: 1;' }

      it { should report_lint }
    end

    context 'when a name is written in camelCase' do
      let(:scss) { '$myVariable: 1;' }

      it { should_not report_lint }
    end
  end

  context 'when the snake_case convention is specified' do
    let(:linter_config) { { 'convention' => 'snake_case' } }

    context 'when a name contains all lowercase letters' do
      let(:scss) { '$variable: 1;' }

      it { should_not report_lint }
    end

    context 'when a name contains all lowercase letters and underscores' do
      let(:scss) { '$my_variable: 1;' }

      it { should_not report_lint }
    end

    context 'when a name contains all lowercase letters and hyphens' do
      let(:scss) { '$my-variable: 1;' }

      it { should report_lint }
    end

    context 'when a name contains any uppercase letters' do
      let(:scss) { '$myVariable: 1;' }

      it { should report_lint }
    end
  end

  context 'when type-specific convention is defined with a global convention' do
    let(:linter_config) do
      { 'convention' => 'camel_case', 'variable_convention' => 'snake_case' }
    end

    context 'when specific type satisfies the type-specific convention' do
      let(:scss) { '$my_variable: 1;' }

      it { should_not report_lint }
    end

    context 'when specific type does not satisfy the type-specific convention' do
      let(:scss) { '$myVariable: 1;' }

      it { should report_lint }
    end

    context 'when other type satisfies the global convention' do
      let(:scss) { '@function myFunction() {}' }

      it { should_not report_lint }
    end

    context 'when other type does not satisfy the global convention' do
      let(:scss) { '@function my_function() {}' }

      it { should report_lint }
    end
  end
end
