require 'rails_helper'

RSpec.describe Captain::AudienceMatcher do
  let(:account) { create(:account) }
  let(:contact) do
    create(:contact, :with_email, :with_phone_number, account: account,
                                                      additional_attributes: { 'country_code' => 'US', 'city' => 'Boston', 'company_name' => 'Acme' },
                                                      custom_attributes: { 'plan_tier' => 'paid' })
  end
  let(:conversation) do
    create(:conversation, account: account, contact: contact,
                          additional_attributes: { 'browser_language' => 'en' })
  end

  def leaf(attribute_key, filter_operator, values = nil)
    { 'attribute_key' => attribute_key, 'filter_operator' => filter_operator, 'values' => Array(values) }
  end

  def matches?(audience)
    described_class.new(audience).matches?(contact, conversation)
  end

  describe '#matches?' do
    it 'returns true when the audience is blank' do
      expect(matches?(nil)).to be(true)
      expect(matches?({})).to be(true)
    end

    context 'with contact attribute leaves' do
      it 'matches additional_attributes case-insensitively for country_code' do
        expect(matches?(leaf('country_code', 'equal_to', 'us'))).to be(true)
        expect(matches?(leaf('country_code', 'equal_to', 'ca'))).to be(false)
      end

      it 'matches custom attributes' do
        expect(matches?(leaf('plan_tier', 'equal_to', 'paid'))).to be(true)
        expect(matches?(leaf('plan_tier', 'not_equal_to', 'free'))).to be(true)
      end

      it 'compares numeric custom attribute values with UI strings' do
        create(:custom_attribute_definition, account: account, attribute_model: :contact_attribute,
                                             attribute_display_type: :number, attribute_key: 'annual_spend')
        contact.update!(custom_attributes: contact.custom_attributes.merge('annual_spend' => 120.5))

        expect(matches?(leaf('annual_spend', 'equal_to', '120.5'))).to be(true)
        expect(matches?(leaf('annual_spend', 'equal_to', '120.6'))).to be(false)

        contact.update!(custom_attributes: contact.custom_attributes.merge('annual_spend' => '120.50'))

        expect(matches?(leaf('annual_spend', 'equal_to', '120.5'))).to be(true)
        expect(matches?(leaf('annual_spend', 'not_equal_to', '120.5'))).to be(false)
      end

      it 'does not include missing standard and additional attributes in negative matches' do
        contact.update!(email: 'person@chatwoot.com', identifier: nil,
                        additional_attributes: contact.additional_attributes.except('country_code'))

        expect(matches?(leaf('identifier', 'not_equal_to', 'known'))).to be(false)
        expect(matches?(leaf('country_code', 'not_equal_to', 'US'))).to be(false)
        expect(matches?(leaf('email', 'does_not_contain', 'example.com'))).to be(true)
        expect(matches?(leaf('identifier', 'does_not_contain', 'known'))).to be(false)
      end

      it 'preserves custom attribute null semantics from contact filters' do
        create(:custom_attribute_definition, account: account, attribute_model: :contact_attribute,
                                             attribute_display_type: :text, attribute_key: 'missing_custom_attribute')
        expect(matches?(leaf('missing_custom_attribute', 'not_equal_to', 'known'))).to be(true)
        expect(matches?(leaf('missing_custom_attribute', 'does_not_contain', 'known'))).to be(false)
      end

      it 'matches checkbox custom attributes' do
        contact.update!(custom_attributes: contact.custom_attributes.merge('newsletter_opt_in' => true))
        expect(matches?(leaf('newsletter_opt_in', 'equal_to', 'true'))).to be(true)
        expect(matches?(leaf('newsletter_opt_in', 'equal_to', 'false'))).to be(false)
      end

      it 'treats a missing checkbox attribute as false' do
        create(:custom_attribute_definition, account: account, attribute_key: 'newsletter_opt_in',
                                             attribute_model: 'contact_attribute', attribute_display_type: 'checkbox')

        expect(matches?(leaf('newsletter_opt_in', 'equal_to', 'false'))).to be(true)
        expect(matches?(leaf('newsletter_opt_in', 'equal_to', 'true'))).to be(false)
        expect(matches?(leaf('newsletter_opt_in', 'not_equal_to', 'true'))).to be(true)
        expect(matches?(leaf('newsletter_opt_in', 'not_equal_to', 'false'))).to be(false)
      end

      it 'supports contains / starts_with on text' do
        expect(matches?(leaf('email', 'contains', contact.email[2..5]))).to be(true)
        expect(matches?(leaf('city', 'starts_with', 'Bos'))).to be(true)
      end

      it 'normalizes phone numbers' do
        expect(matches?(leaf('phone_number', 'equal_to', contact.phone_number.delete('+')))).to be(true)
      end

      it 'supports presence checks' do
        expect(matches?(leaf('email', 'is_present'))).to be(true)
        expect(matches?(leaf('identifier', 'is_not_present'))).to be(true)
      end

      it 'matches blocked boolean' do
        contact.update!(blocked: true)
        expect(matches?(leaf('blocked', 'equal_to', 'true'))).to be(true)
      end

      it 'supports days_before on created_at' do
        contact.update!(created_at: 40.days.ago)
        expect(matches?(leaf('created_at', 'days_before', '30'))).to be(true)
        expect(matches?(leaf('created_at', 'days_before', '60'))).to be(false)
      end

      it 'compares date custom attributes stored as ISO strings' do
        contact.update!(custom_attributes: contact.custom_attributes.merge('signed_up_on' => '2024-01-15'))
        expect(matches?(leaf('signed_up_on', 'is_greater_than', '2024-01-01'))).to be(true)
        expect(matches?(leaf('signed_up_on', 'is_less_than', '2024-01-01'))).to be(false)
        expect(matches?(leaf('signed_up_on', 'is_less_than', '2024-02-01'))).to be(true)
      end
    end

    context 'with labels' do
      before { contact.update_labels(%w[vip]) }

      it 'matches has-tag semantics' do
        expect(matches?(leaf('labels', 'equal_to', 'vip'))).to be(true)
        expect(matches?(leaf('labels', 'equal_to', 'enterprise'))).to be(false)
      end

      it 'matches any of multiple selected labels' do
        expect(matches?(leaf('labels', 'equal_to', %w[enterprise vip]))).to be(true)
        expect(matches?(leaf('labels', 'equal_to', %w[enterprise smb]))).to be(false)
      end

      it 'not_equal_to rejects contacts carrying any selected label' do
        expect(matches?(leaf('labels', 'not_equal_to', %w[enterprise vip]))).to be(false)
        expect(matches?(leaf('labels', 'not_equal_to', %w[enterprise smb]))).to be(true)
      end
    end

    context 'with browser language' do
      it 'resolves browser_language from the conversation' do
        expect(matches?(leaf('browser_language', 'equal_to', 'en'))).to be(true)
      end
    end

    context 'with the logged-in (hmac_verified) flag' do
      it 'matches a verified contact inbox' do
        conversation.contact_inbox.update!(hmac_verified: true)
        expect(matches?(leaf('hmac_verified', 'equal_to', 'true'))).to be(true)
        expect(matches?(leaf('hmac_verified', 'equal_to', 'false'))).to be(false)
      end

      it 'treats an unverified contact inbox as not logged in' do
        conversation.contact_inbox.update!(hmac_verified: false)
        expect(matches?(leaf('hmac_verified', 'equal_to', 'false'))).to be(true)
        expect(matches?(leaf('hmac_verified', 'equal_to', 'true'))).to be(false)
      end
    end

    context 'with nested groups' do
      let(:audience) do
        {
          'operator' => 'and',
          'conditions' => [
            leaf('country_code', 'equal_to', 'US'),
            {
              'operator' => 'or',
              'conditions' => [
                leaf('created_at', 'days_before', '3650'),
                leaf('plan_tier', 'equal_to', 'paid')
              ]
            }
          ]
        }
      end

      it 'evaluates OR inside AND with correct precedence' do
        expect(matches?(audience)).to be(true)
      end

      it 'fails the AND when the top-level condition is false' do
        audience['conditions'][0] = leaf('country_code', 'equal_to', 'CA')
        expect(matches?(audience)).to be(false)
      end

      it 'fails when neither OR branch matches' do
        audience['conditions'][1]['conditions'] = [
          leaf('created_at', 'days_before', '3650'),
          leaf('plan_tier', 'equal_to', 'free')
        ]
        expect(matches?(audience)).to be(false)
      end
    end
  end
end
