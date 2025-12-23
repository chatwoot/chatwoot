require 'spec_helper'

describe SCSSLint::Linter::PropertyCount do
  let(:linter_config) { { 'max_properties' => 3 } }

  context 'when the number of properties in each individual rule set is under the limit' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0;
        padding: 0;
        float: left;

        a {
          color: #f00;
          text-decoration: none;
          text-transform: uppercase;
        }
      }

      i {
        color: #000;
        text-decoration: underline;
        text-transform: lowercase;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when the number of properties in an individual rule set is over the limit' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0;
        padding: 0;
        float: left;

        a {
          color: #f00;
          font: 15px arial, sans-serif;
          text-decoration: none;
          text-transform: uppercase;
        }
      }

      i {
        color: #000;
        text-decoration: underline;
        text-transform: lowercase;
      }
    SCSS

    it { should_not report_lint line: 1 }
    it { should report_lint line: 6 }
  end

  context 'when nested rule sets are included in the count' do
    let(:linter_config) { super().merge('include_nested' => true) }

    context 'when the number of total nested properties under the limit' do
      let(:scss) { <<-SCSS }
        p {
          margin: 0;

          a {
            color: #f00;
            text-transform: uppercase;
          }
        }

        i {
          color: #000;
          text-decoration: underline;
          text-transform: lowercase;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'when the number of total nested properties is over the limit' do
      let(:scss) { <<-SCSS }
        p {
          margin: 0;
          padding: 0;

          a {
            color: #f00;
            text-decoration: none;
            text-transform: uppercase;
          }
        }

        i {
          color: #000;
          text-decoration: underline;
          text-transform: lowercase;
        }
      SCSS

      it { should report_lint line: 1 }
      it { should_not report_lint line: 12 }
    end
  end
end
