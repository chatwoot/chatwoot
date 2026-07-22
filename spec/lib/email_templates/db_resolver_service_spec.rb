require 'rails_helper'

describe EmailTemplates::DbResolverService do
  subject(:resolver) { described_class.using(EmailTemplate, {}) }

  describe '#find_templates' do
    after do
      Current.reset
    end

    context 'when template does not exist in db' do
      it 'return empty array' do
        expect(resolver.find_templates('test', '', false, [])).to eq([])
      end
    end

    context 'when installation template exist in db' do
      it 'return installation template' do
        email_template = create(:email_template, name: 'test', body: 'test')
        handler = ActionView::Template.registered_template_handler(:liquid)
        template_details = {
          locals: [],
          format: Mime['html'].to_sym,
          virtual_path: 'test'
        }

        expect(
          resolver.find_templates('test', '', false, []).first.inspect
        ).to eq(
          ActionView::Template.new(
            email_template.body,
            "DB Template - #{email_template.id}", handler, **template_details
          ).inspect
        )
      end
    end

    context 'when account template exists in db' do
      let(:account) { create(:account) }
      let!(:installation_template) { create(:email_template, name: 'test', body: 'test') }
      let!(:account_template) { create(:email_template, name: 'test', body: 'test2', account: account) }

      it 'return account template for current account' do
        Current.account = account
        handler = ActionView::Template.registered_template_handler(:liquid)
        template_details = {
          locals: [],
          format: Mime['html'].to_sym,
          virtual_path: 'test'
        }

        expect(
          resolver.find_templates('test', '', false, []).first.inspect
        ).to eq(
          ActionView::Template.new(
            account_template.body,
            "DB Template - #{account_template.id}", handler, **template_details
          ).inspect
        )
      end

      it 'return installation template when current account dont have template' do
        Current.account = create(:account)
        handler = ActionView::Template.registered_template_handler(:liquid)
        template_details = {
          locals: [],
          format: Mime['html'].to_sym,
          virtual_path: 'test'
        }

        expect(
          resolver.find_templates('test', '', false, []).first.inspect
        ).to eq(
          ActionView::Template.new(
            installation_template.body,
            "DB Template - #{installation_template.id}", handler, **template_details
          ).inspect
        )
      end
    end

    context 'when inbox template exists in db' do
      let(:account) { create(:account) }
      let(:inbox) { create(:inbox, :with_email, account: account) }
      let!(:inbox_template) { create(:email_template, :layout, account: account, inbox: inbox, body: 'inbox {{ content_for_layout }}') }
      let!(:installation_template) { create(:email_template, :layout, body: 'global {{ content_for_layout }}') }

      it 'returns inbox template when branded email templates feature is enabled' do
        account.enable_features!(:branded_email_templates)
        Current.account = account
        Current.inbox = inbox

        expect(resolver.find_templates('base', 'layouts/mailer', false, { locale: [:en] }).first.source).to eq(inbox_template.body)
      end

      it 'skips account template when branded email templates feature is disabled' do
        account_template = create(:email_template, :layout, account: account, body: 'account {{ content_for_layout }}')
        Current.account = account
        Current.inbox = inbox

        resolved_template = resolver.find_templates('base', 'layouts/mailer', false, { locale: [:en] }).first
        expect(resolved_template.source).to eq(installation_template.body)
        expect(resolved_template.source).not_to eq(account_template.body)
      end

      it 'returns account template when current inbox is not email and feature is enabled' do
        account_template = create(:email_template, :layout, account: account, body: 'account {{ content_for_layout }}')
        account.enable_features!(:branded_email_templates)
        Current.account = account
        Current.inbox = create(:inbox, account: account)

        resolved_template = resolver.find_templates('base', 'layouts/mailer', false, { locale: [:en] }).first
        expect(resolved_template.source).to eq(account_template.body)
        expect(resolved_template.source).not_to eq(installation_template.body)
      end

      it 'skips account template when current inbox is not email and feature is disabled' do
        account_template = create(:email_template, :layout, account: account, body: 'account {{ content_for_layout }}')
        Current.account = account
        Current.inbox = create(:inbox, account: account)

        resolved_template = resolver.find_templates('base', 'layouts/mailer', false, { locale: [:en] }).first
        expect(resolved_template.source).to eq(installation_template.body)
        expect(resolved_template.source).not_to eq(account_template.body)
      end

      it 'skips account template without an inbox when feature is disabled' do
        account_template = create(:email_template, :layout, account: account, body: 'account {{ content_for_layout }}')
        Current.account = account

        resolved_template = resolver.find_templates('base', 'layouts/mailer', false, { locale: [:en] }).first
        expect(resolved_template.source).to eq(installation_template.body)
        expect(resolved_template.source).not_to eq(account_template.body)
      end

      it 'falls back to english when requested locale does not have a template' do
        account.enable_features!(:branded_email_templates)
        Current.account = account
        Current.inbox = inbox

        expect(resolver.find_templates('base', 'layouts/mailer', false, { locale: [:fr] }).first.source).to eq(inbox_template.body)
      end
    end
  end
end
