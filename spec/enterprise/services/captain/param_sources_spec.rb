require 'rails_helper'

RSpec.describe Captain::ParamSources do
  let(:properties) { { 'email' => { 'type' => 'string' }, 'limit' => { 'type' => 'integer' } } }

  def errors_for(entries)
    described_class.validate(entries, properties: properties, tool_name: 'list_invoices')
  end

  describe '.validate' do
    it 'accepts a verified email on a string parameter and a fixed value' do
      expect(errors_for({ 'email' => { 'source' => 'verified.email' }, 'limit' => { 'source' => 'fixed', 'value' => '20' } })).to be_empty
    end

    it 'rejects entries that are not an object' do
      expect(errors_for([])).to eq(['list_invoices parameter sources must be an object'])
    end

    it 'rejects a parameter the tool does not have' do
      expect(errors_for({ 'nope' => { 'source' => 'verified.email' } })).to eq(['list_invoices has no parameters named nope'])
    end

    it 'rejects an unknown source, an extra key and a value of the wrong type' do
      [{ 'source' => 'verified.phone' }, { 'source' => 'verified.email', 'value' => 'x' }, { 'source' => 'fixed', 'value' => 20 }, 'fixed']
        .each do |entry|
          expect(errors_for({ 'limit' => entry })).to eq(['list_invoices parameter limit has an invalid source'])
        end
    end

    it 'rejects a blank fixed value' do
      expect(errors_for({ 'limit' => { 'source' => 'fixed', 'value' => ' ' } })).to eq(['list_invoices parameter limit needs a fixed value'])
    end

    it 'rejects a verified email on a parameter that is not a string' do
      expect(errors_for({ 'limit' => { 'source' => 'verified.email' } }))
        .to eq(['list_invoices parameter limit must be a string to take the verified email'])
    end

    it 'rejects a second verified email' do
      properties['backup_email'] = { 'type' => 'string' }

      expect(errors_for({ 'email' => { 'source' => 'verified.email' }, 'backup_email' => { 'source' => 'verified.email' } }))
        .to eq(['list_invoices can have one verified email parameter only'])
    end
  end

  describe '.resolve' do
    let(:conversation) { create(:conversation) }

    it 'returns a fixed value as stored' do
      expect(described_class.resolve({ 'source' => 'fixed', 'value' => '20' }, conversation)).to eq('20')
    end

    it 'reads the email the customer verified' do
      allow(Captain::EmailVerification).to receive(:new).with(conversation)
                                                        .and_return(instance_double(Captain::EmailVerification, verified_email: 'jane@example.com'))

      expect(described_class.resolve({ 'source' => 'verified.email' }, conversation)).to eq('jane@example.com')
    end

    it 'raises with a message for the model when the customer has not verified an email' do
      allow(Captain::EmailVerification).to receive(:new).and_return(instance_double(Captain::EmailVerification, verified_email: nil))

      expect { described_class.resolve({ 'source' => 'verified.email' }, conversation) }
        .to raise_error(Captain::ParamSources::Unavailable, described_class::UNVERIFIED)
    end
  end
end
