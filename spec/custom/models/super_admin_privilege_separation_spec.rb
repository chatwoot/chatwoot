require 'rails_helper'

# Fork regression guard: the platform operator console and tenant workspaces must
# stay separate populations of `users`.
#
# `SuperAdmin` is STI on the SAME `users` table as tenant agents (`type` column),
# and the /super_admin console is password-only with no MFA — so a tenant user
# that acquired `type: 'SuperAdmin'` would hold cross-tenant control of every
# account on the installation, reachable with nothing but a leaked vendor
# password. Nothing in the schema prevents it; only the provisioning paths do.
# docs/fork/SUPER_ADMIN.md states this invariant three times but never asserted it.
#
# This spec exists to fail loudly if a future provisioning change, a permitted-param
# widening, or a seed makes the two populations overlap.
RSpec.describe 'Super Admin privilege separation' do
  let!(:account) { create(:account) }

  describe 'the tenant population' do
    it 'never produces a SuperAdmin through normal account membership' do
      user = create(:user, account: account, role: :administrator)

      expect(user.type).to be_nil
      expect(SuperAdmin.exists?(user.id)).to be(false)
    end

    it 'holds no SuperAdmin among any account_user, for any role' do
      create(:user, account: account, role: :administrator)
      create(:user, account: account, role: :agent)

      tenant_super_admins = User.where(type: 'SuperAdmin')
                                .where(id: AccountUser.select(:user_id))

      expect(tenant_super_admins).to be_empty
    end
  end

  describe 'the operator population' do
    it 'is not a member of any tenant account' do
      SuperAdmin.create!(
        name: 'Platform Operator',
        email: 'separation-check@platform.test',
        password: 'Str0ng!Pass1'
      )

      # The whole installation, not just the record above: a seed or an earlier
      # migration could have left an overlapping row behind.
      overlapping = SuperAdmin.where(id: AccountUser.select(:user_id))

      expect(overlapping).to be_empty
    end
  end
end
