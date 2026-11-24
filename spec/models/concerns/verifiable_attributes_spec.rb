require 'rails_helper'

RSpec.describe VerifiableAttributes do
  let(:contact) { create(:contact, name: 'Visitor', email: 'visitor@example.com', phone_number: '+919999888877') }

  def verify(attributes)
    contact.assign_verified_attributes(attributes, source: 'jwt')
    contact.save!
    contact.reload
  end

  it 'has no verified attributes by default' do
    expect(contact.attribute_verified?(:email)).to be(false)
    expect(contact.verified_attributes).to eq({})
  end

  describe '#assign_verified_attributes' do
    it 'writes the values and records the source of each' do
      verify(name: 'Priya', email: 'priya@example.com', phone_number: '+919999000011')

      expect(contact).to have_attributes(name: 'Priya', email: 'priya@example.com', phone_number: '+919999000011')
      expect(contact.verified_attributes).to eq('name' => 'jwt', 'email' => 'jwt', 'phone_number' => 'jwt')
      expect(contact.attribute_verified?(:email)).to be(true)
    end

    it 'marks a value that is already stored' do
      verify(email: 'visitor@example.com')

      expect(contact.verified_attributes).to eq('email' => 'jwt')
    end

    it 'keeps the mark when a verified value is replaced' do
      verify(email: 'priya@example.com')
      verify(email: 'priya.new@example.com')

      expect(contact.email).to eq('priya.new@example.com')
      expect(contact.verified_attributes).to eq('email' => 'jwt')
    end

    it 'stores an email in lower case and marks it' do
      verify(email: 'Priya@Example.com')

      expect(contact.email).to eq('priya@example.com')
      expect(contact.verified_attributes).to eq('email' => 'jwt')
    end

    it 'ignores attributes that cannot be verified' do
      verify(identifier: 'user-1', custom_attributes: { plan: 'pro' })

      expect(contact.identifier).to be_nil
      expect(contact.custom_attributes).to eq({})
      expect(contact.verified_attributes).to eq({})
    end

    it 'ignores blank values' do
      verify(email: '', name: nil)

      expect(contact).to have_attributes(name: 'Visitor', email: 'visitor@example.com')
      expect(contact.verified_attributes).to eq({})
    end

    it 'does not mark a value that was discarded as invalid' do
      contact.assign_verified_attributes({ email: 'not-an-email', name: 'Priya' }, source: 'jwt')
      contact.discard_invalid_attrs
      contact.save!

      expect(contact.reload.email).to eq('visitor@example.com')
      expect(contact.verified_attributes).to eq('name' => 'jwt')
    end

    it 'rejects a source it does not know' do
      expect { contact.assign_verified_attributes({ email: 'priya@example.com' }, source: 'visitor') }.to raise_error(ArgumentError)
    end
  end

  describe '#verification_to_store?' do
    it 'is true when a trusted source sends a value that is stored but not marked' do
      contact.assign_verified_attributes({ email: 'visitor@example.com' }, source: 'jwt')

      expect(contact.changed?).to be(false)
      expect(contact.verification_to_store?).to be(true)
    end

    it 'is false when the value is already marked with that source' do
      verify(email: 'visitor@example.com')
      contact.assign_verified_attributes({ email: 'visitor@example.com' }, source: 'jwt')

      expect(contact.verification_to_store?).to be(false)
    end

    it 'is false without a trusted write' do
      contact.name = 'Someone Else'

      expect(contact.verification_to_store?).to be(false)
    end
  end

  describe 'a write without a trusted source' do
    before { verify(name: 'Priya', email: 'priya@example.com') }

    it 'clears the mark of a value it changes and keeps the others' do
      contact.update!(email: 'someone.else@example.com')

      expect(contact.reload.verified_attributes).to eq('name' => 'jwt')
    end

    it 'keeps the mark when the value stays the same' do
      contact.update!(email: 'priya@example.com', name: 'Priya')

      expect(contact.reload.verified_attributes).to eq('name' => 'jwt', 'email' => 'jwt')
    end

    it 'keeps the mark when an email differs only in case' do
      contact.update!(email: 'PRIYA@example.com')

      expect(contact.reload.verified_attributes).to eq('name' => 'jwt', 'email' => 'jwt')
    end

    it 'keeps the marks when another attribute changes' do
      contact.update!(custom_attributes: { plan: 'pro' })

      expect(contact.reload.verified_attributes).to eq('name' => 'jwt', 'email' => 'jwt')
    end
  end

  describe 'validation' do
    it 'does not accept a mark on an attribute that cannot be verified' do
      contact.verified_attributes = { 'identifier' => 'jwt' }

      expect(contact).not_to be_valid
      expect(contact.errors[:verified_attributes]).to be_present
    end

    it 'does not accept a source it does not know' do
      contact.verified_attributes = { 'email' => 'visitor' }

      expect(contact).not_to be_valid
    end
  end
end
