require 'rails_helper'

# The agent restrictions are CE settings, and Enterprise's account form lists only its own
# fields. Whatever form the edit page renders, each restriction has to be there once and be
# submitted with it.
RSpec.describe 'Super admin account agent restrictions', type: :request do
  let(:super_admin) { create(:super_admin) }
  let(:account) { create(:account) }
  let(:restrictions) { %w[hide_agent_unassigned_tab hide_agent_all_tab disable_agent_message_deletion] }

  before { sign_in(super_admin, scope: :super_admin) }

  it 'offers every restriction on the edit page, bound to the account form' do
    get "/super_admin/accounts/#{account.id}/edit"

    expect(response).to have_http_status(:success)
    page = Nokogiri::HTML(response.body)
    form_id = "edit_account_#{account.id}"
    expect(page.at_css("form##{form_id}")).to be_present

    restrictions.each do |name|
      inputs = page.css("input[name='account[#{name}]']")
      check_boxes = inputs.select { |input| input['type'] == 'checkbox' }
      expect(check_boxes.size).to eq(1), "#{name}: #{check_boxes.size} check boxes"
      inputs.each do |input|
        bound = input['form'] == form_id || input.ancestors("form##{form_id}").any?
        expect(bound).to be(true), "#{name} (#{input['type']}) is not submitted with the account form"
      end
    end
  end

  it 'saves them through the account form' do
    patch "/super_admin/accounts/#{account.id}",
          params: { account: { name: account.name, hide_agent_unassigned_tab: '1', disable_agent_message_deletion: '1' } }

    expect(account.reload).to have_attributes(hide_agent_unassigned_tab: true, disable_agent_message_deletion: true)
  end
end
