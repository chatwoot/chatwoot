require 'rails_helper'
require 'nokogiri'

describe Synapseos::SchemaFormHelper do
  def fragment(html)
    Nokogiri::HTML.fragment(html)
  end

  def render(schema, **opts)
    helper.synapseos_schema_form(schema: schema, values: opts.delete(:values) || {}, **opts)
  end

  describe 'string + pattern' do
    let(:schema) do
      {
        'type' => 'object',
        'properties' => {
          'slug' => { 'type' => 'string', 'pattern' => '^[a-z][a-z0-9_]{1,39}$' }
        },
        'required' => ['slug']
      }
    end

    it 'renders a text input with the regex pattern as a code hint' do
      doc = fragment(render(schema, values: { 'slug' => 'acme' }))
      input = doc.at_css('input[name="client[slug]"]')
      expect(input['type']).to eq('text')
      expect(input['value']).to eq('acme')
      expect(doc.at_css('code').text).to eq('^[a-z][a-z0-9_]{1,39}$')
    end

    it 'marks required fields with asterisk' do
      doc = fragment(render(schema))
      expect(doc.at_css('label').text).to include('*')
    end
  end

  describe 'password / secret detection' do
    it 'uses password input for fields named password / secret / token' do
      schema = {
        'type' => 'object',
        'properties' => {
          'api_token' => { 'type' => 'string' },
          'password' => { 'type' => 'string' },
          'app_secret' => { 'type' => 'string' }
        }
      }
      doc = fragment(render(schema))
      expect(doc.at_css('input[name="client[api_token]"]')['type']).to eq('password')
      expect(doc.at_css('input[name="client[password]"]')['type']).to eq('password')
      expect(doc.at_css('input[name="client[app_secret]"]')['type']).to eq('password')
    end

    it 'uses password input when format is password' do
      schema = {
        'type' => 'object',
        'properties' => { 'value' => { 'type' => 'string', 'format' => 'password' } }
      }
      doc = fragment(render(schema))
      expect(doc.at_css('input[name="client[value]"]')['type']).to eq('password')
    end
  end

  describe 'enum select' do
    it 'renders a select with each enum value as option' do
      schema = {
        'type' => 'object',
        'properties' => {
          'env' => { 'type' => 'string', 'enum' => %w[dev staging prod] }
        }
      }
      doc = fragment(render(schema, values: { 'env' => 'prod' }))
      options = doc.css('select[name="client[env]"] option').map { |o| [o['value'], o['selected']] }
      expect(options).to include(['dev', nil], ['staging', nil], %w[prod selected])
    end
  end

  describe 'integer with bounds' do
    it 'renders number input with min/max from schema' do
      schema = {
        'type' => 'object',
        'properties' => {
          'chatwoot_account_id' => { 'type' => 'integer', 'minimum' => 1, 'maximum' => 9999 }
        }
      }
      doc = fragment(render(schema, values: { 'chatwoot_account_id' => 42 }))
      input = doc.at_css('input[name="client[chatwoot_account_id]"]')
      expect(input['type']).to eq('number')
      expect(input['min']).to eq('1')
      expect(input['max']).to eq('9999')
      expect(input['value']).to eq('42')
    end
  end

  describe 'boolean checkbox' do
    let(:schema) do
      {
        'type' => 'object',
        'properties' => { 'enabled' => { 'type' => 'boolean', 'default' => true } }
      }
    end

    it 'renders a hidden false + checkbox pair' do
      doc = fragment(render(schema, values: { 'enabled' => true }))
      hidden = doc.at_css('input[type="hidden"][name="client[enabled]"]')
      checkbox = doc.at_css('input[type="checkbox"][name="client[enabled]"]')
      expect(hidden['value']).to eq('false')
      expect(checkbox['value']).to eq('true')
      expect(checkbox['checked']).to eq('checked')
    end

    it 'leaves checkbox unchecked when value is falsy' do
      doc = fragment(render(schema, values: { 'enabled' => false }))
      checkbox = doc.at_css('input[type="checkbox"][name="client[enabled]"]')
      expect(checkbox['checked']).to be_nil
    end
  end

  describe '$ref to CredentialRef' do
    let(:schema) do
      {
        '$defs' => {
          'CredentialRef' => {
            'type' => 'object',
            'properties' => { 'id' => { 'type' => 'string' }, 'name' => { 'type' => 'string' } },
            'required' => %w[id name]
          }
        },
        'type' => 'object',
        'properties' => {
          'openai' => { '$ref' => '#/$defs/CredentialRef' }
        }
      }
    end

    it 'renders a select + hidden when credentials are populated' do
      creds = [
        { id: 'cred-1', name: 'OpenAI Prod', type: 'openAiApi' },
        { id: 'cred-2', name: 'Postgres Main', type: 'postgres' }
      ]
      doc = fragment(render(schema, credentials: creds, values: { 'openai' => { 'id' => 'cred-1', 'name' => 'OpenAI Prod' } }))
      select = doc.at_css('select[name="client[openai][id]"]')
      expect(select).not_to be_nil
      selected = select.css('option[selected]').first
      expect(selected['value']).to eq('cred-1')
      hidden = doc.at_css('input[type="hidden"][name="client[openai][name]"]')
      expect(hidden['value']).to eq('OpenAI Prod')
    end

    it 'falls back to two text inputs and a banner when credentials list is empty' do
      doc = fragment(render(schema, credentials: [], values: { 'openai' => { 'id' => 'cred-1', 'name' => 'OpenAI Prod' } }))
      expect(doc.css('select[name="client[openai][id]"]')).to be_empty
      expect(doc.at_css('input[type="text"][name="client[openai][id]"]')['value']).to eq('cred-1')
      expect(doc.at_css('input[type="text"][name="client[openai][name]"]')['value']).to eq('OpenAI Prod')
      expect(doc.text).to include('Credentials list unavailable')
    end
  end

  describe 'additionalProperties string (dict editor)' do
    let(:schema) do
      {
        'type' => 'object',
        'properties' => {
          'extra_placeholders' => {
            'type' => 'object',
            'additionalProperties' => { 'type' => 'string' }
          }
        }
      }
    end

    it 'renders a row per key/value pair plus an Add button' do
      values = { 'extra_placeholders' => { 'company' => 'Acme', 'city' => 'SP' } }
      doc = fragment(render(schema, values: values))
      keys = doc.css('input[data-dict-key]').map { |i| i['value'] }
      vals = doc.css('input[data-dict-value]').map { |i| i['value'] }
      expect(keys).to contain_exactly('company', 'city')
      expect(vals).to contain_exactly('Acme', 'SP')
      expect(doc.at_css('button[data-dict-add]').text).to eq('+ Add')
    end

    it 'renders a single empty row when value is empty' do
      doc = fragment(render(schema, values: {}))
      expect(doc.css('[data-dict-row]').length).to eq(1)
    end
  end

  describe 'additionalProperties $ref (agents map)' do
    let(:schema) do
      {
        '$defs' => {
          'AgentConfig' => {
            'type' => 'object',
            'properties' => {
              'enabled' => { 'type' => 'boolean', 'default' => true },
              'persona_short' => { 'type' => 'string' }
            }
          }
        },
        'type' => 'object',
        'properties' => {
          'agents' => {
            'type' => 'object',
            'additionalProperties' => { '$ref' => '#/$defs/AgentConfig' }
          }
        }
      }
    end

    it 'renders a <details> per agent slug from agents_meta with display name and role chip' do
      meta = {
        'sales' => { display_name: 'Sales Bot', role_tag: 'CLOSER' },
        'support' => { display_name: 'Support Bot', role_tag: 'CARE' }
      }
      doc = fragment(render(schema, agents_meta: meta, values: { 'agents' => { 'sales' => { 'enabled' => false, 'persona_short' => 'hey' } } }))
      details = doc.css('details[data-agent-slug]')
      slugs = details.map { |d| d['data-agent-slug'] }
      expect(slugs).to contain_exactly('sales', 'support')
      expect(doc.text).to include('Sales Bot')
      expect(doc.text).to include('CLOSER')
    end

    it 'uses AgentConfig defaults when an agents_meta slug is absent from values' do
      meta = { 'support' => { display_name: 'Support Bot', role_tag: 'CARE' } }
      doc = fragment(render(schema, agents_meta: meta, values: { 'agents' => {} }))
      checkbox = doc.at_css('input[type="checkbox"][name="client[agents][support][enabled]"]')
      expect(checkbox['checked']).to eq('checked')
    end
  end

  describe 'WhatsappConfig provider toggle' do
    let(:schema) do
      {
        '$defs' => {
          'WhatsappConfig' => {
            'type' => 'object',
            'properties' => {
              'provider' => { 'type' => 'string', 'enum' => %w[avisa waba hyperflow] },
              'avisa' => { 'type' => 'object', 'properties' => { 'instance_id' => { 'type' => 'string' } } },
              'waba' => { 'type' => 'object', 'properties' => { 'phone_number_id' => { 'type' => 'string' } } },
              'hyperflow' => { 'type' => 'object', 'properties' => { 'workspace_id' => { 'type' => 'string' } } }
            }
          }
        },
        'type' => 'object',
        'properties' => {
          'whatsapp' => { 'anyOf' => [{ '$ref' => '#/$defs/WhatsappConfig' }, { 'type' => 'null' }] }
        }
      }
    end

    it 'renders a provider select and one provider-target div per sub-config' do
      doc = fragment(render(schema, values: { 'whatsapp' => { 'provider' => 'avisa', 'avisa' => { 'instance_id' => 'abc' } } }))
      provider_select = doc.at_css('select[name="client[whatsapp][provider]"]')
      expect(provider_select).not_to be_nil
      targets = doc.css('[data-provider-target]').map { |d| d['data-provider-target'] }
      expect(targets).to contain_exactly('avisa', 'waba', 'hyperflow')
      expect(doc.at_css('input[name="client[whatsapp][avisa][instance_id]"]')['value']).to eq('abc')
    end

    it 'embeds the runtime script that wires provider toggling' do
      doc = fragment(render(schema))
      script = doc.at_css('script[data-synapseos-form-runtime]')
      expect(script).not_to be_nil
      expect(script.text).to include('data-whatsapp-config')
      expect(script.text).to include('data-dict-editor')
    end
  end

  describe 'errors' do
    let(:schema) do
      {
        '$defs' => {
          'CredentialRef' => {
            'type' => 'object',
            'properties' => { 'id' => { 'type' => 'string' }, 'name' => { 'type' => 'string' } }
          }
        },
        'type' => 'object',
        'properties' => {
          'slug' => { 'type' => 'string' },
          'postgres' => { '$ref' => '#/$defs/CredentialRef' }
        }
      }
    end

    it 'renders the error message under the right field by dot-notation path' do
      errors = {
        'slug' => 'must be lowercase',
        'postgres.id' => 'credential not found'
      }
      doc = fragment(render(schema, credentials: [], errors: errors))
      slug_err = doc.at_css('p[data-error-for="slug"]')
      pg_err = doc.at_css('p[data-error-for="postgres.id"]')
      expect(slug_err.text).to eq('must be lowercase')
      expect(pg_err.text).to eq('credential not found')
    end
  end
end
