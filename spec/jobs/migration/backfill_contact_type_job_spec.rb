require 'rails_helper'

RSpec.describe Migration::BackfillContactTypeJob do
  let(:account) { create(:account) }

  it 'marks visitors with identifying details as leads and leaves the rest' do
    with_email = create(:contact, account: account, email: 'visitor@example.com')
    with_social = create(:contact, account: account, email: nil, additional_attributes: { 'social_instagram_user_name' => 'visitor' })
    anonymous = create(:contact, account: account, email: nil, phone_number: nil, identifier: nil)
    customer = create(:contact, account: account, email: 'customer@example.com')
    # rubocop:disable Rails/SkipsModelValidations
    Contact.where(id: [with_email.id, with_social.id]).update_all(contact_type: Contact.contact_types[:visitor])
    customer.update_column(:contact_type, Contact.contact_types[:customer])
    # rubocop:enable Rails/SkipsModelValidations

    described_class.perform_now

    expect(with_email.reload).to be_lead
    expect(with_social.reload).to be_lead
    expect(anonymous.reload).to be_visitor
    expect(customer.reload).to be_customer
  end
end
