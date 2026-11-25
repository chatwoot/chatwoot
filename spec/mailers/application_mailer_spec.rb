# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join 'spec/mailers/administrator_notifications/shared/smtp_config_shared.rb'

RSpec.describe ApplicationMailer do
  include_context 'with smtp config'

  let!(:account) { create(:account) }
  let!(:administrator) { create(:user, :administrator, email: 'admin@example.com', account: account) }
  let!(:inbox) { create(:inbox, account: account) }

  # AdministratorNotifications::BaseMailer picks its recipients off Current.account, so the
  # address list says which account was in Current while the mail rendered.
  def deliver
    AdministratorNotifications::ChannelNotificationsMailer
      .with(account: account)
      .whatsapp_disconnect(inbox)
      .deliver_now
  end

  it 'renders against the account it was parameterized with, not the caller one' do
    Current.account = create(:account)

    expect(deliver.to).to eq([administrator.email])
  end

  it 'gives the caller its Current back once the mail is built' do
    caller_account = create(:account)
    rule = create(:automation_rule, account: caller_account)
    Current.account = caller_account
    Current.executed_by = rule

    deliver

    expect(Current.account).to eq(caller_account)
    expect(Current.executed_by).to eq(rule)
  end

  it 'leaves Current empty for a caller that had nothing set' do
    deliver

    expect(Current.account).to be_nil
  end

  context 'when the account carries its own brand' do
    before do
      InstallationConfig.where(name: 'BRAND_COLOR').first_or_create!(value: '#1F93FF')
      InstallationConfig.where(name: 'BRAND_NAME').first_or_create!(value: 'Chatwoot')
      GlobalConfig.clear_cache
      account.enable_features!('branded_email_templates')
    end

    it 'paints the email with the account brand instead of the installation one' do
      account.update!(brand_color: '#11D135', brand_name: 'Café Exemplo')

      body = deliver.body.decoded

      expect(body).to include 'background-color: #11D135'
      expect(body).to include 'Café Exemplo'
      expect(body).not_to include 'background-color: #1F93FF'
    end

    it 'escapes the account brand name instead of emitting it as markup' do
      account.update!(brand_name: 'Ben & Jerry\'s')

      body = deliver.body.decoded

      expect(body).to include 'Ben &amp; Jerry&#39;s'
      expect(body).not_to include "Ben & Jerry's"
    end

    it 'leaves the installation brand alone for an account that configured nothing' do
      expect(deliver.body.decoded).to include 'background-color: #1F93FF'
    end
  end

  context 'when the mail belongs to the installation rather than to an account' do
    before do
      InstallationConfig.where(name: 'BRAND_NAME').first_or_create!(value: 'Chatwoot')
      GlobalConfig.clear_cache
      account.enable_features!('branded_email_templates')
      account.update!(brand_name: 'Café Exemplo')
    end

    # Parameterized the way User#send_devise_notification does it, which is the only way the
    # account reaches the mailer: with_isolated_current clears Current and restores only
    # params[:account].
    def devise_body(notification)
      user = create(:user, account: account)
      Devise::Mailer.with(account: account).send(notification, user, 'token', {}).body.to_s
    end

    # send_devise_notification falls back to accounts.first, so a user in two workspaces would
    # otherwise see whichever row the database returned on a password email.
    it 'keeps a password reset on the installation brand' do
      body = devise_body(:reset_password_instructions)

      expect(body).to include 'Chatwoot'
      expect(body).not_to include 'Café Exemplo'
    end

    # The same mailer sends the workspace invitation, whose template names the account, the
    # inviter and the workspace, so that one belongs to the account.
    it 'leaves the workspace invitation on the account brand' do
      body = devise_body(:confirmation_instructions)

      expect(body).to include 'Café Exemplo'
      expect(body).not_to include 'Chatwoot'
    end

    # confirmation_instructions doubles as the invitation and as a personal email
    # reconfirmation. The invitation runs inside the account, so Current carries it; the
    # reconfirmation does not, and picking accounts.first there dressed a personal email as an
    # arbitrary workspace.
    it 'falls back to the installation for a user who belongs to more than one account' do
      user = create(:user, account: account)
      create(:account_user, user: user, account: create(:account))

      expect(Devise::Mailer).to receive(:with).with(account: nil).and_call_original

      user.reload.send(:send_devise_notification, :confirmation_instructions)
    end

    it 'still uses the account of a user who belongs to exactly one' do
      user = create(:user, account: account)

      expect(Devise::Mailer).to receive(:with).with(account: account).and_call_original

      user.reload.send(:send_devise_notification, :confirmation_instructions)
    end

    it 'keeps a compliance notice on the installation brand, every action of it' do
      expect(AdministratorNotifications::AccountComplianceMailer.installation_branded_actions).to eq :all
    end

    it 'leaves an ordinary account mailer on the account brand' do
      expect(AdministratorNotifications::ChannelNotificationsMailer.installation_branded_actions).to be_nil
    end
  end

  context 'with the branded layout' do
    before { InstallationConfig.where(name: 'BRAND_COLOR').first_or_create!(value: '#11D135') }

    it 'splits the brand colour by role: raw on the accent bar, darkened on link text' do
      body = deliver.body.decoded

      expect(body).to include 'background-color: #11D135'
      expect(body).to include "color: #{BrandColor.on_light('#11D135')}"
    end

    it 'falls back to LOGO when it is a format email clients render' do
      InstallationConfig.where(name: 'LOGO').first_or_initialize.update!(value: '/brand-assets/logo.png')

      with_modified_env 'FRONTEND_URL' => 'https://atendimento.example.com' do
        expect(deliver.body.decoded).to include 'src="https://atendimento.example.com/brand-assets/logo.png"'
      end
    end

    it 'shows no logo when LOGO is an SVG, which no email client renders' do
      InstallationConfig.where(name: 'LOGO').first_or_initialize.update!(value: '/brand-assets/logo.svg')

      expect(deliver.body.decoded).not_to include '<img'
    end

    it 'prefers LOGO_EMAIL over the LOGO fallback' do
      InstallationConfig.where(name: 'LOGO').first_or_initialize.update!(value: '/brand-assets/logo.png')
      InstallationConfig.where(name: 'LOGO_EMAIL').first_or_initialize.update!(value: 'https://cdn.example.com/email.png')

      expect(deliver.body.decoded).to include 'src="https://cdn.example.com/email.png"'
    end

    it 'resolves a configured logo path against FRONTEND_URL' do
      InstallationConfig.where(name: 'LOGO_EMAIL').first_or_create!(value: '/logo_email.png')

      with_modified_env 'FRONTEND_URL' => 'https://atendimento.example.com' do
        expect(deliver.body.decoded).to include 'src="https://atendimento.example.com/logo_email.png"'
      end
    end

    it 'joins a path-relative logo without doubling or dropping the separator' do
      InstallationConfig.where(name: 'LOGO_EMAIL').first_or_initialize.update!(value: 'brand-assets/logo.png')

      with_modified_env 'FRONTEND_URL' => 'https://atendimento.example.com/' do
        expect(deliver.body.decoded).to include 'src="https://atendimento.example.com/brand-assets/logo.png"'
      end
    end

    it 'leaves a logo already given as a full URL alone' do
      InstallationConfig.where(name: 'LOGO_EMAIL').first_or_create!(value: 'https://cdn.example.com/logo.png')

      expect(deliver.body.decoded).to include 'src="https://cdn.example.com/logo.png"'
    end
  end
end
