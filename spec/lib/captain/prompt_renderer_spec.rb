require 'rails_helper'

RSpec.describe Captain::PromptRenderer do
  let(:template_name) { 'test_template' }
  let(:template_content) { 'Hello {{name}}, your balance is {{balance}}' }
  let(:enterprise_template_path) { Rails.root.join('enterprise', 'lib', 'captain', 'prompts', "#{template_name}.liquid") }
  let(:oss_template_path) { Rails.root.join('lib', 'captain', 'prompts', "#{template_name}.liquid") }
  let(:context) { { name: 'John', balance: 100 } }

  before do
    if defined?(Enterprise::Captain::PromptRenderer) &&
       !Captain::PromptRenderer.singleton_class.ancestors.include?(Enterprise::Captain::PromptRenderer)
      Captain::PromptRenderer.singleton_class.prepend(Enterprise::Captain::PromptRenderer)
    end

    allow(File).to receive(:exist?).and_return(false)
    allow(File).to receive(:read)

    allow(File).to receive(:exist?).with(enterprise_template_path).and_return(false)
    allow(File).to receive(:exist?).with(oss_template_path).and_return(true)
    allow(File).to receive(:read).with(oss_template_path).and_return(template_content)
  end

  describe '.render' do
    it 'renders template with context' do
      result = described_class.render(template_name, context)

      expect(result).to eq('Hello John, your balance is 100')
    end

    it 'handles string keys in context' do
      string_context = { 'name' => 'Jane', 'balance' => 200 }
      result = described_class.render(template_name, string_context)

      expect(result).to eq('Hello Jane, your balance is 200')
    end

    it 'handles mixed symbol and string keys' do
      mixed_context = { :name => 'Bob', 'balance' => 300 }
      result = described_class.render(template_name, mixed_context)

      expect(result).to eq('Hello Bob, your balance is 300')
    end

    it 'handles nested hash context' do
      nested_template = 'User: {{user.name}}, Account: {{user.account.type}}'
      nested_context = { user: { name: 'Alice', account: { type: 'premium' } } }

      allow(File).to receive(:read).with(oss_template_path).and_return(nested_template)

      result = described_class.render(template_name, nested_context)

      expect(result).to eq('User: Alice, Account: premium')
    end

    it 'handles empty context' do
      simple_template = 'Hello World'
      allow(File).to receive(:read).with(oss_template_path).and_return(simple_template)

      result = described_class.render(template_name, {})

      expect(result).to eq('Hello World')
    end

    it 'loads and parses liquid template' do
      liquid_template_double = instance_double(Liquid::Template)
      allow(Liquid::Template).to receive(:parse).with(template_content).and_return(liquid_template_double)
      allow(liquid_template_double).to receive(:render).with(hash_including('name', 'balance')).and_return('rendered')

      result = described_class.render(template_name, context)

      expect(result).to eq('rendered')
      expect(Liquid::Template).to have_received(:parse).with(template_content)
    end

    it 'prefers enterprise template when available' do
      allow(File).to receive(:exist?).with(enterprise_template_path).and_return(true)
      allow(File).to receive(:read).with(enterprise_template_path).and_return('Enterprise {{name}}')

      result = described_class.render(template_name, context)

      expect(result).to eq('Enterprise John')
      expect(File).to have_received(:read).with(enterprise_template_path)
      expect(File).not_to have_received(:read).with(oss_template_path)
    end
  end

  describe '.load_template' do
    it 'reads template file from OSS path when enterprise file absent' do
      described_class.send(:load_template, template_name)

      expect(File).to have_received(:read).with(oss_template_path)
    end

    it 'raises error when template does not exist in either location' do
      allow(File).to receive(:exist?).with(oss_template_path).and_return(false)

      expect { described_class.send(:load_template, template_name) }
        .to raise_error("Template not found: #{template_name}")
    end

    it 'checks enterprise path before OSS path' do
      allow(File).to receive(:exist?).with(enterprise_template_path).and_return(true)
      allow(File).to receive(:read).with(enterprise_template_path).and_return('enterprise')

      described_class.send(:load_template, template_name)

      expect(File).to have_received(:exist?).with(enterprise_template_path)
      expect(File).not_to have_received(:read).with(oss_template_path)
    end
  end

  describe '.stringify_keys' do
    it 'converts symbol keys to strings' do
      hash = { name: 'John', age: 30 }
      result = described_class.send(:stringify_keys, hash)

      expect(result).to eq({ 'name' => 'John', 'age' => 30 })
    end

    it 'handles nested hashes' do
      hash = { user: { name: 'John', profile: { age: 30 } } }
      result = described_class.send(:stringify_keys, hash)

      expect(result).to eq({ 'user' => { 'name' => 'John', 'profile' => { 'age' => 30 } } })
    end

    it 'handles arrays with hashes' do
      hash = { users: [{ name: 'John' }, { name: 'Jane' }] }
      result = described_class.send(:stringify_keys, hash)

      expect(result).to eq({ 'users' => [{ 'name' => 'John' }, { 'name' => 'Jane' }] })
    end

    it 'handles empty hash' do
      result = described_class.send(:stringify_keys, {})

      expect(result).to eq({})
    end
  end
end
