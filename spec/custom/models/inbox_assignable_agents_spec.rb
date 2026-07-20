require 'rails_helper'

# Fork: platform-managed infrastructure users must never be offered as the
# assignee of a customer conversation. Assigning one parks the conversation with
# an identity no human reads.
#
# Backlog 13 Problem 1 scoped the agent LIST and the quota count, but assignee
# pickers are built from `account.administrators` — and the provisioned service
# admin is an administrator — so it kept leaking there.
RSpec.describe 'Assignable agents exclude platform-managed users' do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }

  # A real vendor admin, of the kind that SHOULD be assignable.
  let!(:vendor_admin) { create(:user, account: account, role: :administrator) }

  # Provisioned infrastructure: an administrator flagged platform_managed.
  let!(:service_admin) do
    user = create(:user, account: account, role: :administrator)
    user.account_users.find_by(account: account).update!(platform_managed: true)
    user
  end

  describe 'Inbox#assignable_agents' do
    it 'offers the vendor admin but not the platform service admin' do
      agents = inbox.assignable_agents

      expect(agents).to include(vendor_admin)
      expect(agents).not_to include(service_admin)
    end

    it 'still offers an inbox member who is a plain agent' do
      agent = create(:user, account: account, role: :agent)
      create(:inbox_member, inbox: inbox, user: agent)

      expect(inbox.assignable_agents).to include(agent)
    end

    it 'is unaffected when the account has no platform-managed users' do
      clean_account = create(:account)
      clean_inbox = create(:inbox, account: clean_account)
      admin = create(:user, account: clean_account, role: :administrator)

      expect(clean_inbox.assignable_agents).to include(admin)
    end
  end

  # The dashboard's own endpoint does NOT delegate to this method — it rebuilds
  # the list — so it is covered separately in
  # spec/custom/controllers/api/v1/accounts/assignable_agents_controller_spec.rb.
  # Without that, this spec would pass while the visible dropdown stayed wrong.
end
