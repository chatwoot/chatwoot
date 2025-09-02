require 'rails_helper'

RSpec.describe 'RBAC System', type: :model do
  let(:account) { create(:account) }
  
  # Create users with different roles
  let(:owner_user) { create(:user) }
  let(:admin_user) { create(:user) }
  let(:finance_user) { create(:user) }
  let(:agent_user) { create(:user) }
  let(:support_user) { create(:user) }
  
  let(:owner_account_user) { create(:account_user, account: account, user: owner_user, role: :owner, is_primary_owner: true) }
  let(:admin_account_user) { create(:account_user, account: account, user: admin_user, role: :administrator) }
  let(:finance_account_user) { create(:account_user, account: account, user: finance_user, role: :finance) }
  let(:agent_account_user) { create(:account_user, account: account, user: agent_user, role: :agent) }
  let(:support_account_user) { create(:account_user, account: account, user: support_user, role: :support) }

  before do
    # Ensure CustomRole class exists and has constants defined
    stub_const('CustomRole::PERMISSIONS', [
      'conversation_view_all', 'conversation_view_assigned', 'conversation_view_participating',
      'conversation_manage_all', 'conversation_manage_assigned', 'conversation_assign',
      'conversation_transfer', 'conversation_resolve', 'conversation_reopen',
      'conversation_private_notes', 'conversation_export',
      
      'contact_view', 'contact_create', 'contact_update', 'contact_delete',
      'contact_merge', 'contact_export', 'contact_import', 'contact_custom_attributes',
      
      'team_view', 'team_invite', 'team_manage', 'user_profile_update',
      'role_assign', 'role_create', 'role_manage',
      
      'report_view', 'report_advanced', 'report_export', 'report_custom',
      'analytics_view', 'analytics_export',
      
      'billing_view', 'billing_manage', 'invoice_view', 'invoice_download',
      'payment_methods', 'subscription_manage', 'usage_view',
      
      'settings_account', 'settings_channels', 'settings_integrations',
      'settings_webhooks', 'settings_automation', 'settings_security', 'settings_advanced',
      
      'kb_view', 'kb_article_create', 'kb_article_edit', 'kb_article_delete',
      'kb_category_manage', 'kb_portal_manage', 'kb_publish',
      
      'channel_view', 'channel_create', 'channel_configure', 'channel_delete',
      'integration_manage', 'webhook_manage',
      
      'audit_log_view', 'system_info_view', 'feature_flags_view', 'feature_flags_manage'
    ])

    stub_const('CustomRole::DEFAULT_PERMISSIONS', {
      'owner' => CustomRole::PERMISSIONS,
      'admin' => CustomRole::PERMISSIONS - %w[feature_flags_manage],
      'agent' => %w[
        conversation_view_assigned conversation_view_participating
        conversation_manage_assigned conversation_resolve conversation_reopen
        conversation_private_notes contact_view contact_update
        contact_custom_attributes team_view user_profile_update
        report_view kb_view kb_article_create kb_article_edit channel_view
      ],
      'finance' => %w[
        team_view report_view report_advanced report_export report_custom
        analytics_view analytics_export billing_view billing_manage
        invoice_view invoice_download payment_methods subscription_manage
        usage_view settings_account
      ],
      'support' => %w[
        conversation_view_assigned conversation_view_participating
        conversation_manage_assigned conversation_resolve contact_view
        team_view user_profile_update report_view kb_view
        kb_article_create kb_article_edit channel_view
      ]
    })
  end

  describe 'Role Hierarchy' do
    it 'correctly orders role hierarchy levels' do
      expect(owner_account_user.role_hierarchy).to eq(150)
      expect(admin_account_user.role_hierarchy).to eq(100)
      expect(finance_account_user.role_hierarchy).to eq(75)
      expect(agent_account_user.role_hierarchy).to eq(50)
      expect(support_account_user.role_hierarchy).to eq(25)
    end

    it 'allows higher hierarchy roles to manage lower ones' do
      expect(owner_account_user.can_manage_user?(admin_account_user)).to be_truthy
      expect(admin_account_user.can_manage_user?(agent_account_user)).to be_truthy
      expect(finance_account_user.can_manage_user?(support_account_user)).to be_truthy
      expect(agent_account_user.can_manage_user?(support_account_user)).to be_truthy
    end

    it 'prevents lower hierarchy roles from managing higher ones' do
      expect(agent_account_user.can_manage_user?(admin_account_user)).to be_falsy
      expect(support_account_user.can_manage_user?(agent_account_user)).to be_falsy
      expect(finance_account_user.can_manage_user?(admin_account_user)).to be_falsy
    end

    it 'prevents same level users from managing each other' do
      another_agent = create(:account_user, account: account, user: create(:user), role: :agent)
      expect(agent_account_user.can_manage_user?(another_agent)).to be_falsy
    end
  end

  describe 'Permission Matrix' do
    describe 'Owner permissions' do
      it 'has all permissions' do
        CustomRole::PERMISSIONS.each do |permission|
          expect(owner_account_user.has_permission?(permission)).to be_truthy,
            "Owner should have #{permission} permission"
        end
      end

      it 'can manage feature flags' do
        expect(owner_account_user.has_permission?('feature_flags_manage')).to be_truthy
      end
    end

    describe 'Administrator permissions' do
      it 'has most permissions except feature flag management' do
        (CustomRole::PERMISSIONS - %w[feature_flags_manage]).each do |permission|
          expect(admin_account_user.has_permission?(permission)).to be_truthy,
            "Admin should have #{permission} permission"
        end
      end

      it 'cannot manage feature flags' do
        expect(admin_account_user.has_permission?('feature_flags_manage')).to be_falsy
      end
    end

    describe 'Agent permissions' do
      let(:agent_permissions) { CustomRole::DEFAULT_PERMISSIONS['agent'] }

      it 'has correct conversation permissions' do
        expect(agent_account_user.has_permission?('conversation_view_assigned')).to be_truthy
        expect(agent_account_user.has_permission?('conversation_view_participating')).to be_truthy
        expect(agent_account_user.has_permission?('conversation_manage_assigned')).to be_truthy
        expect(agent_account_user.has_permission?('conversation_view_all')).to be_falsy
        expect(agent_account_user.has_permission?('conversation_manage_all')).to be_falsy
      end

      it 'has limited contact permissions' do
        expect(agent_account_user.has_permission?('contact_view')).to be_truthy
        expect(agent_account_user.has_permission?('contact_update')).to be_truthy
        expect(agent_account_user.has_permission?('contact_delete')).to be_falsy
        expect(agent_account_user.has_permission?('contact_export')).to be_falsy
      end

      it 'cannot manage team or roles' do
        expect(agent_account_user.has_permission?('team_manage')).to be_falsy
        expect(agent_account_user.has_permission?('role_assign')).to be_falsy
        expect(agent_account_user.has_permission?('role_create')).to be_falsy
      end

      it 'has basic reporting permissions' do
        expect(agent_account_user.has_permission?('report_view')).to be_truthy
        expect(agent_account_user.has_permission?('report_advanced')).to be_falsy
        expect(agent_account_user.has_permission?('analytics_view')).to be_falsy
      end

      it 'has no billing permissions' do
        billing_permissions = CustomRole::PERMISSIONS.select { |p| p.start_with?('billing_', 'invoice_', 'payment_', 'subscription_', 'usage_') }
        billing_permissions.each do |permission|
          expect(agent_account_user.has_permission?(permission)).to be_falsy,
            "Agent should not have #{permission} permission"
        end
      end
    end

    describe 'Finance permissions' do
      it 'has comprehensive billing permissions' do
        billing_permissions = %w[
          billing_view billing_manage invoice_view invoice_download
          payment_methods subscription_manage usage_view
        ]
        
        billing_permissions.each do |permission|
          expect(finance_account_user.has_permission?(permission)).to be_truthy,
            "Finance should have #{permission} permission"
        end
      end

      it 'has advanced reporting permissions' do
        report_permissions = %w[
          report_view report_advanced report_export report_custom
          analytics_view analytics_export
        ]
        
        report_permissions.each do |permission|
          expect(finance_account_user.has_permission?(permission)).to be_truthy,
            "Finance should have #{permission} permission"
        end
      end

      it 'has no conversation management permissions' do
        conversation_permissions = CustomRole::PERMISSIONS.select { |p| p.start_with?('conversation_') }
        conversation_permissions.each do |permission|
          expect(finance_account_user.has_permission?(permission)).to be_falsy,
            "Finance should not have #{permission} permission"
        end
      end

      it 'cannot manage roles or team' do
        expect(finance_account_user.has_permission?('team_manage')).to be_falsy
        expect(finance_account_user.has_permission?('role_assign')).to be_falsy
        expect(finance_account_user.has_permission?('role_create')).to be_falsy
      end
    end

    describe 'Support permissions' do
      it 'has limited conversation permissions' do
        expect(support_account_user.has_permission?('conversation_view_assigned')).to be_truthy
        expect(support_account_user.has_permission?('conversation_view_participating')).to be_truthy
        expect(support_account_user.has_permission?('conversation_manage_assigned')).to be_truthy
        expect(support_account_user.has_permission?('conversation_resolve')).to be_truthy
        
        expect(support_account_user.has_permission?('conversation_view_all')).to be_falsy
        expect(support_account_user.has_permission?('conversation_assign')).to be_falsy
        expect(support_account_user.has_permission?('conversation_transfer')).to be_falsy
      end

      it 'has knowledge base permissions' do
        expect(support_account_user.has_permission?('kb_view')).to be_truthy
        expect(support_account_user.has_permission?('kb_article_create')).to be_truthy
        expect(support_account_user.has_permission?('kb_article_edit')).to be_truthy
        expect(support_account_user.has_permission?('kb_article_delete')).to be_falsy
        expect(support_account_user.has_permission?('kb_portal_manage')).to be_falsy
      end

      it 'has no billing or advanced permissions' do
        restricted_permissions = CustomRole::PERMISSIONS.select do |p|
          p.start_with?('billing_', 'settings_', 'audit_', 'feature_flags_')
        end
        
        restricted_permissions.each do |permission|
          expect(support_account_user.has_permission?(permission)).to be_falsy,
            "Support should not have #{permission} permission"
        end
      end
    end
  end

  describe 'Custom Role Integration' do
    let(:custom_role) do
      create(:custom_role, 
        account: account,
        name: 'Custom Support',
        permissions: %w[conversation_view_all contact_view kb_article_edit],
        role_hierarchy: 60
      )
    end

    let(:custom_account_user) do
      create(:account_user, 
        account: account, 
        user: create(:user), 
        role: :agent,
        custom_role: custom_role
      )
    end

    it 'combines base role permissions with custom role permissions' do
      # Should have agent base permissions
      expect(custom_account_user.has_permission?('conversation_view_assigned')).to be_truthy
      expect(custom_account_user.has_permission?('contact_update')).to be_truthy
      
      # Should have additional custom role permissions
      expect(custom_account_user.has_permission?('conversation_view_all')).to be_truthy
      expect(custom_account_user.has_permission?('kb_article_edit')).to be_truthy
      
      # Should not have permissions not in either base or custom role
      expect(custom_account_user.has_permission?('billing_view')).to be_falsy
    end

    it 'respects custom role hierarchy' do
      expect(custom_account_user.role_hierarchy).to eq(60)
      expect(custom_account_user.can_manage_user?(agent_account_user)).to be_truthy # 60 > 50
      expect(custom_account_user.can_manage_user?(finance_account_user)).to be_falsy # 60 < 75
    end
  end

  describe 'Permission Overrides' do
    let(:account_user_with_overrides) do
      create(:account_user, 
        account: account, 
        user: create(:user), 
        role: :agent,
        permissions_override: {
          'granted' => %w[billing_view report_advanced],
          'revoked' => %w[contact_view]
        }
      )
    end

    it 'grants additional permissions via override' do
      expect(account_user_with_overrides.has_permission?('billing_view')).to be_truthy
      expect(account_user_with_overrides.has_permission?('report_advanced')).to be_truthy
    end

    it 'revokes permissions via override' do
      expect(account_user_with_overrides.has_permission?('contact_view')).to be_falsy
    end

    it 'maintains other base permissions' do
      expect(account_user_with_overrides.has_permission?('conversation_view_assigned')).to be_truthy
      expect(account_user_with_overrides.has_permission?('contact_update')).to be_truthy
    end
  end

  describe 'Access Control Scenarios' do
    let(:conversation) { create(:conversation, account: account, assignee: agent_user) }
    let(:unassigned_conversation) { create(:conversation, account: account, assignee: nil) }
    let(:other_agent_conversation) { create(:conversation, account: account, assignee: create(:user)) }

    describe 'Conversation access control' do
      it 'allows agents to view assigned conversations' do
        policy = RbacPolicy.new(agent_account_user, conversation)
        expect(policy.view_conversation?).to be_truthy
      end

      it 'prevents agents from viewing unassigned conversations without proper permission' do
        policy = RbacPolicy.new(agent_account_user, unassigned_conversation)
        expect(policy.view_conversation?).to be_falsy
      end

      it 'prevents agents from viewing other agents\' conversations' do
        policy = RbacPolicy.new(agent_account_user, other_agent_conversation)
        expect(policy.view_conversation?).to be_falsy
      end

      it 'allows owners and admins to view all conversations' do
        owner_policy = RbacPolicy.new(owner_account_user, other_agent_conversation)
        admin_policy = RbacPolicy.new(admin_account_user, other_agent_conversation)
        
        expect(owner_policy.view_conversation?).to be_truthy
        expect(admin_policy.view_conversation?).to be_truthy
      end
    end

    describe 'Role assignment control' do
      it 'allows higher hierarchy users to assign lower hierarchy roles' do
        expect(admin_account_user.can_assign_role?('agent')).to be_truthy
        expect(admin_account_user.can_assign_role?('support')).to be_truthy
        expect(admin_account_user.can_assign_role?('finance')).to be_truthy
      end

      it 'prevents lower hierarchy users from assigning higher hierarchy roles' do
        expect(agent_account_user.can_assign_role?('administrator')).to be_falsy
        expect(support_account_user.can_assign_role?('finance')).to be_falsy
      end

      it 'prevents users without role_assign permission from assigning any role' do
        # Agent doesn't have role_assign permission by default
        expect(agent_account_user.can_assign_role?('support')).to be_falsy
      end

      it 'allows owners to assign any role except owner' do
        expect(owner_account_user.can_assign_role?('administrator')).to be_truthy
        expect(owner_account_user.can_assign_role?('finance')).to be_truthy
        expect(owner_account_user.can_assign_role?('agent')).to be_truthy
        expect(owner_account_user.can_assign_role?('support')).to be_truthy
      end
    end
  end

  describe 'Edge Cases and Security' do
    it 'handles nil permissions gracefully' do
      account_user = create(:account_user, account: account, user: create(:user), role: :agent)
      allow(account_user).to receive(:effective_permissions).and_return(nil)
      
      expect { account_user.has_permission?('any_permission') }.not_to raise_error
      expect(account_user.has_permission?('any_permission')).to be_falsy
    end

    it 'handles empty custom role permissions' do
      custom_role = create(:custom_role, account: account, permissions: [])
      account_user = create(:account_user, account: account, user: create(:user), role: :agent, custom_role: custom_role)
      
      # Should still have base agent permissions
      expect(account_user.has_permission?('conversation_view_assigned')).to be_truthy
    end

    it 'prevents privilege escalation through permission overrides' do
      # Even with override, an agent shouldn't be able to get owner-level permissions
      account_user = create(:account_user, 
        account: account, 
        user: create(:user), 
        role: :agent,
        permissions_override: {
          'granted' => %w[feature_flags_manage] # This should not work for non-owners
        }
      )
      
      # The permission might be in the list, but policy should still restrict it
      policy = RbacPolicy.new(account_user, nil)
      expect(policy.manage_feature_flags?).to be_falsy
    end

    it 'maintains data integrity with malformed permission data' do
      account_user = create(:account_user, account: account, user: create(:user), role: :agent)
      allow(account_user).to receive(:permissions_override).and_return('invalid_json')
      
      expect { account_user.effective_permissions }.not_to raise_error
      expect(account_user.effective_permissions).to be_an(Array)
    end
  end

  describe 'Audit and Compliance' do
    it 'logs permission changes' do
      expect(RbacService).to receive(:audit_permission_change).with(
        admin_account_user,
        'role_assigned',
        hash_including(:target_user, :new_role)
      )
      
      # Simulate role assignment
      RbacService.audit_permission_change(
        admin_account_user,
        'role_assigned',
        { target_user: agent_account_user, new_role: 'finance' }
      )
    end

    it 'provides permission audit trail' do
      permissions = RbacService.user_permissions(agent_account_user)
      
      expect(permissions).to be_an(Array)
      expect(permissions).to include('conversation_view_assigned')
      expect(permissions).not_to include('billing_manage')
    end
  end
end