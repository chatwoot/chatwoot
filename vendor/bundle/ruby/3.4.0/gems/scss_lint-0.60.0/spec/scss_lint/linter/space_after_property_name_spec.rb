require 'spec_helper'

describe SCSSLint::Linter::SpaceAfterPropertyName do
  context 'when a property name is followed by a space' do
    let(:scss) { <<-SCSS }
      p {
        margin : 0;
      }
    SCSS

    it { should report_lint line: 2 }
  end

  context 'when a property name is not followed by a space' do
    let(:scss) { <<-SCSS }
      p {
        margin: 0;
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when interpolation within single quotes is followed by inline property' do
    context 'and property name is followed by a space' do
      let(:scss) { "[class~='\#{$test}'] { width: 100%; }" }

      it { should_not report_lint }
    end

    context 'and property name is not followed by a space' do
      let(:scss) { "[class~='\#{$test}'] { width : 100%; }" }

      it { should report_lint }
    end
  end
end
