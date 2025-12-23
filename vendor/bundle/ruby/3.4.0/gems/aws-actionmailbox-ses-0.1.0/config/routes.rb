# frozen_string_literal: true

Rails.application.routes.draw do
  scope '/rails/action_mailbox', module: 'action_mailbox/ingresses' do
    post '/ses/inbound_emails' => 'ses/inbound_emails#create', as: :rails_ses_inbound_emails
  end
end
