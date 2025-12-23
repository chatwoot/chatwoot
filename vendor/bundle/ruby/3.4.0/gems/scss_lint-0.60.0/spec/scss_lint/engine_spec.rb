require 'spec_helper'

describe SCSSLint::Engine do
  let(:engine) { described_class.new(code: scss) }

  context 'when a @media directive is present' do
    let(:scss) { <<-SCSS }
      @media only screen {
      }
    SCSS

    it 'has a parse tree' do
      engine.tree.should_not be_nil
    end
  end

  context 'when a custom property is present' do
    let(:scss) { <<-SCSS }
      :root {
        --my-font-family: Helvetica;
      }
    SCSS

    it 'has a parse tree' do
      engine.tree.should_not be_nil
    end
  end

  context 'when the file being linted has an invalid byte sequence' do
    let(:scss) { "\xC0\u0001" }

    it 'raises a SyntaxError' do
      expect { engine }.to raise_error(SCSSLint::FileEncodingError)
    end
  end
end
