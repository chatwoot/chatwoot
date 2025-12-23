require 'spec_helper'

describe SCSSLint::Engine do
  let(:engine) { described_class.new(options) }
  let(:command) { 'my-command' }
  let(:scss) { <<-SCSS }
    ---
    ---
    $red: #f00;
  SCSS
  let(:processed) { <<-SCSS }
    $red: #f00;
  SCSS

  context 'preprocess_command is specified' do
    let(:options) { { code: scss, preprocess_command: command } }

    it 'preprocesses, and Sass is able to parse' do
      open3 = class_double('Open3').as_stubbed_const
      open3.should_receive(:capture2).with(command, stdin_data: scss).and_return([processed, 0])

      variable = engine.tree.children[0]
      expect(variable).to be_instance_of(Sass::Tree::VariableNode)
      expect(variable.name).to eq('red')
    end
  end

  context 'preprocessor fails' do
    let(:options) { { code: scss, preprocess_command: command } }

    it 'preprocesses, and Sass is able to parse' do
      open3 = class_double('Open3').as_stubbed_const
      open3.should_receive(:capture2).with(command, stdin_data: scss).and_return([processed, 1])

      expect { engine }.to raise_error(SCSSLint::Exceptions::PreprocessorError)
    end
  end

  context 'both preprocess_command and preprocess_files are specified' do
    let(:path) { 'foo/a.scss' }

    context 'file should be preprocessed' do
      let(:options) do
        { path: path,
          preprocess_command: command,
          preprocess_files: ['foo/*.scss'] }
      end

      it 'preprocesses, and Sass is able to parse' do
        open3 = class_double('Open3').as_stubbed_const
        open3.should_receive(:capture2).with(command, stdin_data: scss).and_return([processed, 0])
        File.should_receive(:read).with(path).and_return(scss)

        variable = engine.tree.children[0]
        expect(variable).to be_instance_of(Sass::Tree::VariableNode)
        expect(variable.name).to eq('red')
      end
    end

    context 'file should not be preprocessed' do
      let(:options) do
        { path: path,
          preprocess_command: command,
          preprocess_files: ['bar/*.scss'] }
      end

      it 'does not preprocess, and Sass throws' do
        File.should_receive(:read).with(path).and_return(scss)
        expect { engine }.to raise_error(Sass::SyntaxError)
      end
    end

    context 'code should never be preprocessed' do
      let(:options) do
        { code: scss,
          preprocess_command: command,
          preprocess_files: ['foo/*.scss'] }
      end

      it 'does not preprocess, and Sass throws' do
        expect { engine }.to raise_error(Sass::SyntaxError)
      end
    end
  end
end
