require 'rails_helper'

RSpec.describe ContactIpLookupJob do
  subject(:job) { described_class.perform_later(contact) }

  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account, additional_attributes: { 'created_at_ip' => '1.1.1.1' }) }
  # Not an `instance_double`: `Geocoder::Result::Base` builds its readers at runtime, so the
  # verifying double refuses methods the real object answers.
  let(:geocoder_result) { Struct.new(:city, :country, :country_code).new('Sao Paulo', 'Brazil', 'BR') }
  let(:ip_lookup) { instance_double(IpLookupService) }

  before { allow(IpLookupService).to receive(:new).and_return(ip_lookup) }

  # The lookup is a network call, and the job holds a copy of `additional_attributes` read before
  # it. Anything another writer puts in the column during that call is in the row and not in the
  # copy, so writing the copy back erases it. No threads: the copy is simply old.
  describe 'a writer that lands during the lookup' do
    it 'does not erase what the other writer stored' do
      allow(ip_lookup).to receive(:perform) do
        Contact.find(contact.id).update!(
          additional_attributes: contact.additional_attributes.merge('company_name' => 'fazer.ai')
        )
        geocoder_result
      end

      described_class.perform_now(contact)

      expect(contact.reload.additional_attributes).to include('company_name' => 'fazer.ai', 'city' => 'Sao Paulo')
    end

    it 'does not resurrect a key the other writer removed' do
      contact.update!(additional_attributes: contact.additional_attributes.merge('company_name' => 'fazer.ai'))
      allow(ip_lookup).to receive(:perform) do
        Contact.find(contact.id).update!(additional_attributes: { 'created_at_ip' => '1.1.1.1' })
        geocoder_result
      end

      described_class.perform_now(contact)

      expect(contact.reload.additional_attributes).not_to have_key('company_name')
    end
  end

  # The write has to keep firing what a write fires. `before_save :sync_contact_attributes` is what
  # copies `additional_attributes['city']` into the `location` column, so a fix that reached for
  # `update_columns` would leave the column empty and say nothing.
  describe 'the columns the write is supposed to feed' do
    it 'still fills location and country_code' do
      allow(ip_lookup).to receive(:perform).and_return(geocoder_result)

      described_class.perform_now(contact)

      expect(contact.reload.location).to eq('Sao Paulo')
      expect(contact.additional_attributes).to include('country' => 'Brazil', 'country_code' => 'BR')
    end
  end
end
