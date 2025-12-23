require 'spec_helper'

describe SCSSLint::Linter::PropertySpelling do
  context 'with a regular property' do
    let(:scss) { <<-SCSS }
      p {
        margin: 5px;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'with a property containing interpolation' do
    let(:scss) { <<-SCSS }
      p {
        \#{$property-name}: 5px;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'with a non-existent property' do
    let(:scss) { <<-SCSS }
      p {
        peanut-butter: jelly-time;
      }
    SCSS

    it { should report_lint }
  end

  context 'when extra properties are specified' do
    let(:linter_config) { { 'extra_properties' => ['made-up-property'] } }

    context 'with a non-existent property' do
      let(:scss) { <<-SCSS }
        p {
          peanut-butter: jelly-time;
        }
      SCSS

      it { should report_lint }
    end

    context 'with a property listed as an extra property' do
      let(:scss) { <<-SCSS }
        p {
          made-up-property: value;
        }
      SCSS

      it { should_not report_lint }
    end
  end

  context 'when disabled properties are specified' do
    let(:linter_config) do
      {
        'disabled_properties' => ['margin'],
      }
    end

    context 'with a non-existent property' do
      let(:scss) { <<-SCSS }
        p {
          peanut-butter: jelly-time;
        }
      SCSS

      it { should report_lint }
    end

    context 'with a property listed as an disabled property' do
      let(:scss) { <<-SCSS }
        p {
          margin: 0;
        }
      SCSS

      it { should report_lint }
    end
  end

  context 'with valid nested properties' do
    let(:scss) { <<-SCSS }
      p {
        text: {
          align: center;
          transform: uppercase;
        }
      }
    SCSS

    it { should_not report_lint }
  end

  context 'with invalid nested properties' do
    let(:scss) { <<-SCSS }
      p {
        text: {
          aligned: center;
          transformed: uppercase;
        }
      }
    SCSS

    it { should report_lint line: 3 }
    it { should report_lint line: 4 }
  end
end
