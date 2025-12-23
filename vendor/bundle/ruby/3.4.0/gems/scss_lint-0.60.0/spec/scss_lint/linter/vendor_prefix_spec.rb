require 'spec_helper'

describe SCSSLint::Linter::VendorPrefix do
  context 'when no vendor-prefix is used' do
    let(:scss) { <<-SCSS }
      div {
        transition: none;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a rule is empty' do
    let(:scss) { <<-SCSS }
      div {
      }
    SCSS

    it { should_not report_lint }
  end

  # Properties

  context 'when a vendor-prefixed listed property is used' do
    let(:scss) { <<-SCSS }
      div {
        -webkit-transition: none;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when an unprefixed listed property is used' do
    let(:scss) { <<-SCSS }
      div {
        transition: none;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a vendor-prefixed unlisted property is used' do
    let(:scss) { <<-SCSS }
      div {
        -webkit-appearance: none;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a vendor-prefixed custom-listed property is used' do
    let(:linter_config) { { 'identifier_list' => ['transform'] } }

    let(:scss) { <<-SCSS }
      div {
        -webkit-transform: none;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when a proprietary unlisted vendor-prefixed property is used' do
    let(:scss) { <<-SCSS }
      div {
        -moz-padding-end: 0;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a proprietary listed vendor-prefixed property is used' do
    let(:linter_config) { { 'identifier_list' => ['padding-end'] } }

    let(:scss) { <<-SCSS }
      div {
        -moz-padding-end: 0;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  # Selectors

  context 'when a vendor-prefixed listed selector is used' do
    let(:scss) { <<-SCSS }
      ::-moz-placeholder {
        color: red;
      }
      :-ms-placeholder {
        color: pink;
      }
      :-moz-fullscreen p {
        font-size: 200%;
      }
    SCSS

    it { should report_lint line: 1 }
    it { should report_lint line: 4 }
    it { should report_lint line: 7 }
  end

  context 'when an unprefixed listed selector is used' do
    let(:scss) { <<-SCSS }
      ::placeholder {
        color: red;
      }
      :fullscreen p {
        font-size: 200%;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a vendor-prefixed unlisted selector is used' do
    let(:linter_config) { { 'identifier_list' => ['transform'] } }

    let(:scss) { <<-SCSS }
      ::-moz-placeholder {
        color: red;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a vendor-prefixed custom-listed selector is used' do
    let(:linter_config) { { 'identifier_list' => ['placeholder'] } }

    let(:scss) { <<-SCSS }
      ::-moz-placeholder {
        color: red;
      }
    SCSS

    it { should report_lint line: 1 }
  end

  # Directives

  context 'when a vendor-prefixed listed directive is used' do
    let(:scss) { <<-SCSS }
      @-webkit-keyframes anim {
        0% { opacity: 0; }
      }
    SCSS

    it { should report_lint line: 1 }
  end

  context 'when an unprefixed listed directive is used' do
    let(:scss) { <<-SCSS }
      @keyframes anim {
        0% { opacity: 0; }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when an vendor-prefixed unlisted directive is used' do
    let(:linter_config) { { 'identifier_list' => ['placeholder'] } }

    let(:scss) { <<-SCSS }
      @-webkit-keyframes anim {
        0% { opacity: 0; }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when an vendor-prefixed custom-listed directive is used' do
    let(:linter_config) { { 'identifier_list' => ['keyframes'] } }

    let(:scss) { <<-SCSS }
      @-webkit-keyframes anim {
        0% { opacity: 0; }
      }
    SCSS

    it { should report_lint line: 1 }
  end

  # Values

  context 'when a vendor-prefixed listed value is used' do
    let(:scss) { <<-SCSS }
      div {
        background-image: -webkit-linear-gradient(#000, #fff);
        position: -moz-sticky;
      }
    SCSS

    it { should report_lint line: 2 }
    it { should report_lint line: 3 }
  end

  context 'when an unprefixed listed value is used' do
    let(:scss) { <<-SCSS }
      div {
        background-image: linear-gradient(#000, #fff);
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a vendor-unprefixed unlisted value is used' do
    let(:linter_config) { { 'identifier_list' => ['keyframes'] } }

    let(:scss) { <<-SCSS }
      div {
        background-image: -webkit-linear-gradient(#000, #fff);
        position: -moz-sticky;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a vendor-unprefixed custom-listed value is used' do
    let(:linter_config) { { 'identifier_list' => ['linear-gradient'] } }

    let(:scss) { <<-SCSS }
      div {
        background-image: -webkit-linear-gradient(#000, #fff);
        position: -moz-sticky;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  # Identifier lists

  context 'when using non-default named identifier list' do
    let(:linter_config) { { 'identifier_list' => 'bourbon' } }

    context 'and a standard vendor-prefixed property is used' do
      let(:scss) { <<-SCSS }
        div {
          background-image: -webkit-linear-gradient(#000, #fff);
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'and a list-specific vendor-prefixed property is used' do
      let(:scss) { <<-SCSS }
        div {
          image-rendering: -moz-crisp-edges;
          -webkit-appearance: none;
        }
      SCSS

      it { should report_lint line: 2 }
      it { should report_lint line: 3 }
    end

    context 'and a list-exempt vendor-prefixed property is used' do
      let(:scss) { <<-SCSS }
        div {
          -webkit-mask-repeat: inherit;
        }
      SCSS

      it { should_not report_lint }
    end
  end

  # Excluding and Including

  context 'when manually excluding identifiers' do
    let(:linter_config) do
      {
        'identifier_list' => 'base',
        'excluded_identifiers' => %w[transform selection],
      }
    end

    let(:scss) { <<-SCSS }
      div {
        -webkit-transform: translateZ(0);
      }
      ::-moz-selection {
        color: #000;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when manually including identifiers' do
    let(:linter_config) do
      {
        'identifier_list' => 'base',
        'additional_identifiers' => ['padding-end'],
        'excluded_identifiers' => [],
      }
    end

    let(:scss) { <<-SCSS }
      div {
        -moz-padding-end: 0;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  # More
  context 'when dealing with many-hyphened vendor-prefixed identifiers' do
    let(:scss) { <<-SCSS }
      div {
        -moz-animation-timing-function: ease-out;
        -webkit-border-bottom-right-radius: 5px;
        background: -o-repeating-radial-gradient(#000, #000 5px, #fff 5px, #fff 10px)
      }
    SCSS

    it { should report_lint line: 2 }
    it { should report_lint line: 3 }
    it { should report_lint line: 4 }
  end

  context 'when dealing with many-hyphened unprefixed identifiers' do
    let(:scss) { <<-SCSS }
      div {
        animation-timing-function: ease-out;
        border-bottom-right-radius: 5px;
        background: repeating-radial-gradient(#000, #000 5px, #fff 5px, #fff 10px)
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when vendor-prefixed media queries are used' do
    let(:scss) { <<-SCSS }
    @media
      only screen and (-webkit-min-device-pixel-ratio: 1.3),
      only screen and (-o-min-device-pixel-ratio: 13/10),
      only screen and (min-resolution: 120dpi) {
        body {
          background: #fff;
        }
      }
    SCSS

    it { should_not report_lint }
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
