require 'spec_helper'

describe SCSSLint::Linter::SelectorFormat do
  context 'when class has alphanumeric chars and is separated by hyphens' do
    let(:scss) { <<-SCSS }
      .foo-bar-77 {
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when id has alphanumeric chars and is separated by hyphens' do
    let(:scss) { <<-SCSS }
      #foo-bar-77 {
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when element has alphanumeric chars and is separated by hyphens' do
    let(:scss) { <<-SCSS }
      foo-bar-77 {
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when placeholder has alphanumeric chars and is separated by hyphens' do
    let(:scss) { <<-SCSS }
      %foo-bar-77 {
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when selector has alphanumeric chars and is separated by underscores' do
    let(:scss) { <<-SCSS }
      .foo_bar {
      }
    SCSS

    it { should report_lint line: 1 }
  end

  context 'when selector is camelCase' do
    let(:scss) { <<-SCSS }
      fooBar77 {
      }
    SCSS

    it { should report_lint line: 1 }
  end

  context 'when placeholder has alphanumeric chars and is separated by underscores' do
    let(:scss) { <<-SCSS }
      %foo_bar {
      }
    SCSS

    it { should report_lint line: 1 }
  end

  context 'when attribute has alphanumeric chars and is separated by underscores' do
    let(:scss) { <<-SCSS }
      [data_text] {
      }
    SCSS

    it { should report_lint line: 1 }
  end

  context 'when attribute selector has alphanumeric chars and is separated by underscores' do
    let(:scss) { <<-SCSS }
      [data-text=some_text] {
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when convention is set to snake_case' do
    let(:linter_config) { { 'convention' => 'snake_case' } }

    context 'when selector has alphanumeric chars and is separated by underscores' do
      let(:scss) { <<-SCSS }
        .foo_bar_77 {
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when selector has alphanumeric chars and is separated by hyphens' do
      let(:scss) { <<-SCSS }
        .foo-bar-77 {
        }
      SCSS

      it { should report_lint line: 1 }
    end

    context 'when selector is in camelCase' do
      let(:scss) { <<-SCSS }
        .fooBar77 {
        }
      SCSS

      it { should report_lint line: 1 }
    end
  end

  context 'when convention is set to camel_case' do
    let(:linter_config) { { 'convention' => 'camel_case' } }

    context 'when selector is camelCase' do
      let(:scss) { <<-SCSS }
        .fooBar77 {
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when selector capitalizes first word' do
      let(:scss) { <<-SCSS }
        .FooBar77 {
        }
      SCSS

      it { should report_lint line: 1 }
    end

    context 'when selector has alphanumeric chars and is separated by underscores' do
      let(:scss) { <<-SCSS }
        .foo_bar_77 {
        }
      SCSS

      it { should report_lint line: 1 }
    end

    context 'when selector has alphanumeric chars and is separated by hyphens' do
      let(:scss) { <<-SCSS }
        .foo-bar-77 {
        }
      SCSS

      it { should report_lint line: 1 }
    end
  end

  context 'when convention is set to use a regex' do
    let(:linter_config) { { 'convention' => /^[0-9]*$/ } }

    context 'when selector uses regex properly' do
      let(:scss) { <<-SCSS }
        .1337 {
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when selector does not use regex properly' do
      let(:scss) { <<-SCSS }
        .leet {
        }
      SCSS

      it { should report_lint line: 1 }
    end
  end

  context 'when ignored names are set' do
    let(:linter_config) { { 'ignored_names' => ['fooBar'] } }

    context 'it ignores exact string matches' do
      let(:scss) { <<-SCSS }
        fooBar {
        }
      SCSS

      it { should_not report_lint }
    end
  end

  context 'when ignored types is set to class' do
    let(:linter_config) { { 'ignored_types' => ['class'] } }

    context 'it ignores all invalid classes' do
      let(:scss) { <<-SCSS }
        .fooBar {
        }
      SCSS

      it { should_not report_lint }
    end
  end

  context 'when ignored types is set to id, element, placeholder' do
    let(:linter_config) do
      { 'ignored_types' => %w[id attribute element placeholder] }
    end

    context 'it ignores all invalid ids' do
      let(:scss) { <<-SCSS }
        #fooBar {
        }
      SCSS

      it { should_not report_lint }
    end

    context 'it ignores all invalid elements' do
      let(:scss) { <<-SCSS }
        fooBar {
        }
      SCSS

      it { should_not report_lint }
    end

    context 'it ignores all invalid placeholders' do
      let(:scss) { <<-SCSS }
        %fooBar {
        }
      SCSS

      it { should_not report_lint }
    end

    context 'it ignores all invalid attributes' do
      let(:scss) { <<-SCSS }
        [fooBar=fooBar] {
        }
      SCSS

      it { should_not report_lint }
    end
  end

  context 'when using a unique `id_convention`' do
    let(:linter_config) { { 'id_convention' => 'snake_case' } }

    context 'and actual id is correct' do
      let(:scss) { <<-SCSS }
        .hyphenated-lowercase {}
        #snake_case {}
      SCSS

      it { should_not report_lint }
    end

    context 'and actual id is incorrect' do
      let(:scss) { <<-SCSS }
        .hyphenated-lowercase {}
        #hyphenated-lowercase {}
      SCSS

      it { should report_lint line: 2 }
    end

    context 'and something else uses the `id_convention`' do
      let(:scss) { <<-SCSS }
        .snake_case {}
        #hyphenated-lowercase {}
      SCSS

      it { should report_lint line: 1 }
    end
  end

  context 'when using a unique `class_convention`' do
    let(:linter_config) { { 'class_convention' => 'camel_case' } }

    context 'and actual class is correct' do
      let(:scss) { <<-SCSS }
        .camelCase {}
        #hyphenated-lowercase {}
      SCSS

      it { should_not report_lint }
    end

    context 'and actual class is incorrect' do
      let(:scss) { <<-SCSS }
        .hyphenated-lowercase {}
        #hyphenated-lowercase {}
      SCSS

      it { should report_lint line: 1 }
    end

    context 'and something else uses the `class_convention`' do
      let(:scss) { <<-SCSS }
        .hyphenated-lowercase {}
        #camelCase {}
      SCSS

      it { should report_lint line: 2 }
    end
  end

  context 'when using a unique `placeholder_convention`' do
    let(:linter_config) { { 'placeholder_convention' => 'snake_case' } }

    context 'and actual placeholder is correct' do
      let(:scss) { <<-SCSS }
        .hyphenated-lowercase {}
        %snake_case {}
      SCSS

      it { should_not report_lint }
    end

    context 'and actual placeholder is incorrect' do
      let(:scss) { <<-SCSS }
        .hyphenated-lowercase {}
        %hyphenated-lowercase {}
      SCSS

      it { should report_lint line: 2 }
    end

    context 'and something else uses the `placeholder_convention`' do
      let(:scss) { <<-SCSS }
        .snake_case {}
        %snake_case {}
      SCSS

      it { should report_lint line: 1 }
    end
  end

  context 'when using a unique `element_convention`' do
    let(:linter_config) do
      {
        'convention' => 'camel_case',
        'element_convention' => 'hyphenated-lowercase'
      }
    end

    context 'and actual element is correct' do
      let(:scss) { <<-SCSS }
        hyphenated-lowercase {}
        #camelCase {}
      SCSS

      it { should_not report_lint }
    end

    context 'and actual element is incorrect' do
      let(:scss) { <<-SCSS }
        camelCase {}
        #camelCase {}
      SCSS

      it { should report_lint line: 1 }
    end

    context 'and something else uses the `element_convention`' do
      let(:scss) { <<-SCSS }
        hyphenated-lowercase {}
        #hyphenated-lowercase {}
      SCSS

      it { should report_lint line: 2 }
    end
  end

  context 'when using a unique `attribute_convention`' do
    let(:linter_config) do
      {
        'convention' => 'camel_case',
        'attribute_convention' => 'hyphenated-lowercase'
      }
    end

    context 'and actual attribute is correct' do
      let(:scss) { <<-SCSS }
        [hyphenated-lowercase] {}
        #camelCase {}
      SCSS

      it { should_not report_lint }
    end

    context 'and actual attribute is incorrect' do
      let(:scss) { <<-SCSS }
        [camelCase] {}
        #camelCase {}
      SCSS

      it { should report_lint line: 1 }
    end

    context 'and something else uses the `attribute_convention`' do
      let(:scss) { <<-SCSS }
        [hyphenated-lowercase] {}
        #hyphenated-lowercase {}
      SCSS

      it { should report_lint line: 2 }
    end
  end

  context 'when using a blend of unique conventions' do
    let(:linter_config) do
      {
        'convention' => 'camel_case',
        'element_convention' => 'hyphenated-lowercase',
        'attribute_convention' => 'snake_case',
        'class_convention' => /[a-z]+\-\-[a-z]+/
      }
    end

    context 'and everything is correct' do
      let(:scss) { <<-SCSS }
        #camelCase {}
        hyphenated-lowercase {}
        [snake_case] {}
        .foo--bar {}
      SCSS

      it { should_not report_lint }
    end

    context 'some things are not correct' do
      let(:scss) { <<-SCSS }
        #camelCase {}
        camelCase {}
        [snake_case] {}
        .fooBar {}
      SCSS

      it { should report_lint line: 2 }
      it { should report_lint line: 4 }
    end

    context 'other things are not correct' do
      let(:scss) { <<-SCSS }
        #snake_case {}
        hyphenated-lowercase {}
        [camelCase] {}
        .foo--bar {}
      SCSS

      it { should report_lint line: 1 }
      it { should report_lint line: 3 }
    end
  end

  context 'when the classic_BEM convention is specified' do
    let(:linter_config) { { 'convention' => 'classic_BEM' } }

    context 'when a name contains no underscores or hyphens' do
      let(:scss) { '.block {}' }

      it { should_not report_lint }
    end

    context 'when a name contains single hyphen' do
      let(:scss) { '.b-block {}' }

      it { should_not report_lint }
    end

    context 'when a name contains multiple hyphens' do
      let(:scss) { '.b-block-name {}' }

      it { should_not report_lint }
    end

    context 'when a name contains multiple hyphens in a row' do
      let(:scss) { '.b-block--modifier {}' }

      it { should report_lint }
    end

    context 'when a name contains a single underscore' do
      let(:scss) { '.block_modifier {}' }

      it { should_not report_lint }
    end

    context 'when a block has name-value modifier' do
      let(:scss) { '.block_modifier_value {}' }

      it { should_not report_lint }
    end

    context 'when a block has name-value modifier with lots of hyphens' do
      let(:scss) { '.b-block-name_modifier-name-here_value-name-here {}' }

      it { should_not report_lint }
    end

    context 'when a name has double underscores' do
      let(:scss) { '.b-block__element {}' }

      it { should_not report_lint }
    end

    context 'when element goes after block with modifier' do
      let(:scss) { '.block_modifier_value__element {}' }

      it { should report_lint }
    end

    context 'when element has modifier' do
      let(:scss) { '.block__element_modifier_value {}' }

      it { should_not report_lint }
    end

    context 'when element has not paired modifier' do
      let(:scss) { '.block__element_modifier {}' }

      it { should_not report_lint }
    end

    context 'when element has hypenated modifier' do
      let(:scss) { '.block__element--modifier {}' }

      it { should report_lint }
    end

    context 'when element has hypenated paired modifier' do
      let(:scss) { '.block__element--modifier_value {}' }

      it { should report_lint }
    end
  end

  context 'when the strict_BEM convention is specified' do
    let(:linter_config) { { 'convention' => 'strict_BEM' } }

    context 'when a name contains no underscores or hyphens' do
      let(:scss) { '.block {}' }

      it { should_not report_lint }
    end

    context 'when a name contains single hyphen' do
      let(:scss) { '.b-block {}' }

      it { should_not report_lint }
    end

    context 'when a name contains multiple hyphens' do
      let(:scss) { '.b-block-name {}' }

      it { should_not report_lint }
    end

    context 'when a name contains multiple hyphens in a row' do
      let(:scss) { '.b-block--modifier {}' }

      it { should report_lint }
    end

    context 'when a name contains a single underscore' do
      let(:scss) { '.block_modifier {}' }

      it { should report_lint }
    end

    context 'when a block has name-value modifier' do
      let(:scss) { '.block_modifier_value {}' }

      it { should_not report_lint }
    end

    context 'when a block has name-value modifier with lots of hyphens' do
      let(:scss) { '.b-block-name_modifier-name-here_value-name-here {}' }

      it { should_not report_lint }
    end

    context 'when a name has double underscores' do
      let(:scss) { '.b-block__element {}' }

      it { should_not report_lint }
    end

    context 'when element goes after block with modifier' do
      let(:scss) { '.block_modifier_value__element {}' }

      it { should report_lint }
    end

    context 'when element has modifier' do
      let(:scss) { '.block__element_modifier_value {}' }

      it { should_not report_lint }
    end

    context 'when element has not paired modifier' do
      let(:scss) { '.block__element_modifier {}' }

      it { should report_lint }
    end

    context 'when element has hypenated modifier' do
      let(:scss) { '.block__element--modifier {}' }

      it { should report_lint }
    end

    context 'when element has hypenated paired modifier' do
      let(:scss) { '.block__element--modifier_value {}' }

      it { should report_lint }
    end
  end

  context 'when the hyphenated_BEM convention is specified' do
    let(:linter_config) { { 'convention' => 'hyphenated_BEM' } }

    context 'when a name contains no underscores or hyphens' do
      let(:scss) { '.block {}' }

      it { should_not report_lint }
    end

    context 'when a name contains single hyphen' do
      let(:scss) { '.b-block {}' }

      it { should_not report_lint }
    end

    context 'when a name contains multiple hyphens' do
      let(:scss) { '.b-block-name {}' }

      it { should_not report_lint }
    end

    context 'when a name contains multiple hyphens in a row' do
      let(:scss) { '.b-block--modifier {}' }

      it { should_not report_lint }
    end

    context 'when a name contains a single underscore' do
      let(:scss) { '.block_modifier {}' }

      it { should report_lint }
    end

    context 'when a block has name-value modifier' do
      let(:scss) { '.block--modifier-value {}' }

      it { should_not report_lint }
    end

    context 'when a block has name-value modifier with lots of hyphens' do
      let(:scss) { '.b-block-name--modifier-name-here-value-name-here {}' }

      it { should_not report_lint }
    end

    context 'when a name has double underscores' do
      let(:scss) { '.b-block__element {}' }

      it { should_not report_lint }
    end

    context 'when element goes after block with modifier' do
      let(:scss) { '.block--modifier-value__element {}' }

      it { should_not report_lint }
    end

    context 'when element has modifier' do
      let(:scss) { '.block__element--modifier-value {}' }

      it { should_not report_lint }
    end

    context 'when element has hypenated modifier' do
      let(:scss) { '.block__element--modifier {}' }

      it { should_not report_lint }
    end

    context 'when element has hypenated paired modifier' do
      let(:scss) { '.block__element--modifier-value {}' }

      it { should_not report_lint }
    end

    context 'when a block contains an underscore' do
      let(:scss) { '.a_block__element--modifier {}' }

      it { should report_lint }
    end

    context 'when an element contains an underscore' do
      let(:scss) { '.block__an_element--modifier {}' }

      it { should report_lint }
    end

    context 'when a modifier contains an underscore' do
      let(:scss) { '.block__element--a_modifier {}' }

      it { should report_lint }
    end
  end
end
