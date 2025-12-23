require 'spec_helper'

describe SCSSLint::Linter::MergeableSelector do
  context 'when single root' do
    let(:scss) { <<-SCSS }
      p {
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when different roots' do
    let(:scss) { <<-SCSS }
      p {
        background: #000;
        margin: 5px;
      }
      a {
        background: #000;
        margin: 5px;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when different roots with matching inner rules' do
    let(:scss) { <<-SCSS }
      p {
        background: #000;
        margin: 5px;
        .foo {
          color: red;
        }
      }
      a {
        background: #000;
        margin: 5px;
        .foo {
          color: red;
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when multi-selector roots and parital rule match' do
    let(:scss) { <<-SCSS }
      p, a {
        background: #000;
        margin: 5px;
        .foo {
          color: red;
        }
      }
      a {
        background: #000;
        margin: 5px;
        .foo {
          color: red;
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when nested and unnested selectors match' do
    let(:scss) { <<-SCSS }
      a.current {
        background: #000;
        margin: 5px;
        .foo {
          color: red;
        }
      }
      a {
        &.current {
          background: #000;
          margin: 5px;
          .foo {
            color: red;
          }
        }
      }
    SCSS

    context 'when force_nesting is enabled' do
      let(:linter_config) { { 'force_nesting' => true } }
      it { should report_lint }
    end

    context 'when force_nesting is disabled' do
      let(:linter_config) { { 'force_nesting' => false } }
      it { should_not report_lint }
    end
  end

  context 'when same class roots' do
    let(:scss) { <<-SCSS }
      .warn {
        font-weight: bold;
      }
      .warn {
        color: #f00;
        @extend .warn;
        a {
          color: #ccc;
        }
      }
    SCSS

    it { should report_lint }
  end

  context 'when same compond selector roots' do
    let(:scss) { <<-SCSS }
      .warn .alert {
        font-weight: bold;
      }
      .warn .alert {
        color: #f00;
        @extend .warn;
        a {
          color: #ccc;
        }
      }
    SCSS

    it { should report_lint }
  end

  context 'when same class roots separated by another class' do
    let(:scss) { <<-SCSS }
      .warn {
        font-weight: bold;
      }
      .foo {
        color: red;
      }
      .warn {
        color: #f00;
        @extend .warn;
        a {
          color: #ccc;
        }
      }
    SCSS

    it { should report_lint }
  end

  context 'when rule in a mixin @include matches a root root' do
    let(:scss) { <<-SCSS }
      p {
        font-weight: bold;
      }
      @include enhance(small-tablet) {
        p {
          font-weight: normal;
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when rule in a mixin definition matches a root rule' do
    let(:scss) { <<-SCSS }
      p {
        font-weight: bold;
      }
      @mixin my-mixin {
        p {
          font-weight: normal;
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when rule in a media directive matches a root rule' do
    let(:scss) { <<-SCSS }
      p {
        font-weight: bold;
      }
      @media only screen and (min-device-pixel-ratio: 1.5) {
        p {
          font-weight: normal;
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when rule in a keyframes directive matches a root rule' do
    let(:scss) { <<-SCSS }
      @keyframes slideouttoleft {
        from {
          transform: translateX(0);
        }

        to {
          transform: translateX(-100%);
        }
      }

      @keyframes slideouttoright {
        from {
          transform: translateX(0);
        }

        to {
          transform: translateX(100%);
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when there are duplicate rules nested in a rule set' do
    let(:scss) { <<-SCSS }
      .foo {
        .bar {
          font-weight: bold;
        }
        .baz {
          font-weight: bold;
        }
        .bar {
          color: #ff0;
        }
      }
    SCSS

    it { should report_lint }
  end

  context 'when there are two parent selectors in a single selector' do
    let(:scss) { <<-SCSS }
      .b-some {
        &__image {
          width: 100%;
        }
        &__image + &__buttons {
          margin-top: 14px;
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when force_nesting is enabled' do
    let(:linter_config) { { 'force_nesting' => true } }

    context 'when one of the duplicate rules is in a comma sequence' do
      let(:scss) { <<-SCSS }
        .foo,
        .bar {
          color: #000;
        }
        .foo {
          color: #f00;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when rules start with the same prefix but are not the same' do
      let(:scss) { <<-SCSS }
        .foo {
          color: #000;
        }
        .foobar {
          color: #f00;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when a rule contains interpolation' do
      let(:scss) { <<-SCSS }
        .\#{$class-name} {}
        .foobar {}
      SCSS

      it { should_not report_lint }
    end
  end

  context 'when a whitelist list is defined' do
    let(:linter_config) { { 'whitelist' => ['polyfill-rule'] } }

    context 'when a rule is found in the whitelist' do
      let(:scss) { <<-SCSS }
        polyfill-rule { content: '.foo'; color: red; }
        polyfill-rule { content: '.foo'; color: red; }
      SCSS

      it { should_not report_lint }
    end

    context 'when a rule is not found in the whitelist' do
      let(:scss) { <<-SCSS }
        .foo polyfill-rule { content: '.foo'; color: red; }
        .foo polyfill-rule { content: '.foo'; color: red; }
      SCSS

      it { should report_lint }
    end
  end

  context 'when a single whitelist selector is defined' do
    let(:linter_config) { { 'whitelist' => 'polyfill-rule' } }

    context 'when a rule is found in the whitelist' do
      let(:scss) { <<-SCSS }
        polyfill-rule { content: '.foo'; color: red; }
        polyfill-rule { content: '.foo'; color: red; }
      SCSS

      it { should_not report_lint }
    end

    context 'when a rule is not found in the whitelist' do
      let(:scss) { <<-SCSS }
        .foo polyfill-rule { content: '.foo'; color: red; }
        .foo polyfill-rule { content: '.foo'; color: red; }
      SCSS

      it { should report_lint }
    end
  end
end
