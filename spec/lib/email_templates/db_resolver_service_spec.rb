require 'rails_helper'

describe ::EmailTemplates::DbResolverService do
  subject(:resolver) { described_class.using(EmailTemplate, {}) }

  describe '#find_templates' do
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
        Current.account = nil
      end

      it 'return installation template when  current account dont have template' do
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
        Current.account = nil
      end
    end
  end
end
