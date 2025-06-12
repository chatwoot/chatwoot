require 'rails_helper'

shared_examples_for 'reauthorizable' do
  let(:model) { described_class } # the class that includes the concern
  let(:obj) { FactoryBot.create(model.to_s.underscore.tr('/', '_').to_sym) }

  it 'authorization_error!' do
    expect(obj.authorization_error_count).to eq 0

    obj.authorization_error!

    expect(obj.authorization_error_count).to eq 1
  end

  it 'prompts reauthorization when error threshold is passed' do
    expect(obj.reauthorization_required?).to be false

    obj.class::AUTHORIZATION_ERROR_THRESHOLD.times do
      obj.authorization_error!
    end

    expect(obj.reauthorization_required?).to be true
  end

  # Helper methods to set up mailer mocks
  def setup_automation_rule_mailer(_obj)
    account_mailer = instance_double(AdministratorNotifications::AccountNotificationMailer)
    automation_mailer_response = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
    allow(AdministratorNotifications::AccountNotificationMailer).to receive(:with).and_return(account_mailer)
    allow(account_mailer).to receive(:automation_rule_disabled).and_return(automation_mailer_response)
  end

  def setup_integrations_hook_mailer(obj)
    integrations_mailer = instance_double(AdministratorNotifications::IntegrationsNotificationMailer)
    slack_mailer_response = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
    dialogflow_mailer_response = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
    allow(AdministratorNotifications::IntegrationsNotificationMailer).to receive(:with).and_return(integrations_mailer)
    allow(integrations_mailer).to receive(:slack_disconnect).and_return(slack_mailer_response)
    allow(integrations_mailer).to receive(:dialogflow_disconnect).and_return(dialogflow_mailer_response)

    # Allow the model to respond to slack? and dialogflow? methods
    allow(obj).to receive(:slack?).and_return(true)
    allow(obj).to receive(:dialogflow?).and_return(false)
  end

  def setup_channel_mailer(_obj)
    channel_mailer = instance_double(AdministratorNotifications::ChannelNotificationsMailer)
    facebook_mailer_response = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
    whatsapp_mailer_response = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
    email_mailer_response = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
    instagram_mailer_response = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
    allow(AdministratorNotifications::ChannelNotificationsMailer).to receive(:with).and_return(channel_mailer)
    allow(channel_mailer).to receive(:facebook_disconnect).and_return(facebook_mailer_response)
    allow(channel_mailer).to receive(:whatsapp_disconnect).and_return(whatsapp_mailer_response)
    allow(channel_mailer).to receive(:email_disconnect).and_return(email_mailer_response)
    allow(channel_mailer).to receive(:instagram_disconnect).and_return(instagram_mailer_response)
  end

  describe 'prompt_reauthorization!' do
    before do
      # Setup mailer mocks based on model type
      if model.to_s == 'AutomationRule'
        setup_automation_rule_mailer(obj)
      elsif model.to_s == 'Integrations::Hook'
        setup_integrations_hook_mailer(obj)
      else
        setup_channel_mailer(obj)
      end
    end

    it 'sets reauthorization required flag' do
      expect(obj.reauthorization_required?).to be false
      obj.prompt_reauthorization!
      expect(obj.reauthorization_required?).to be true
    end

    it 'calls the correct mailer based on model type' do
      obj.prompt_reauthorization!

      if model.to_s == 'AutomationRule'
        expect(AdministratorNotifications::AccountNotificationMailer).to have_received(:with).with(account: obj.account)
      elsif model.to_s == 'Integrations::Hook'
        expect(AdministratorNotifications::IntegrationsNotificationMailer).to have_received(:with).with(account: obj.account)
      else
        expect(AdministratorNotifications::ChannelNotificationsMailer).to have_received(:with).with(account: obj.account)
      end
    end
  end

  it 'reauthorized!' do
    # setting up the object with the errors to validate its cleared on action
    obj.authorization_error!
    obj.prompt_reauthorization!
    expect(obj.reauthorization_required?).to be true
    expect(obj.authorization_error_count).not_to eq 0

    obj.reauthorized!

    # authorization errors are reset
    expect(obj.authorization_error_count).to eq 0
    expect(obj.reauthorization_required?).to be false
  end
end
