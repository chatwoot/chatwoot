require 'rails_helper'

RSpec.describe 'Super Admin Email Layouts API', type: :request do
  let(:super_admin) { create(:super_admin) }
  let(:account) { create(:account, name: 'Acme Inc') }

  describe 'GET /super_admin/email_layout/edit' do
    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        get '/super_admin/email_layout/edit'
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated super admin' do
      it 'shows the email layout page' do
        allow(ChatwootHub).to receive(:pricing_plan).and_return('enterprise')
        sign_in(super_admin, scope: :super_admin)

        get '/super_admin/email_layout/edit'

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Configure Settings - Email Templates')
        expect(response.body).to include('Create new template')
        expect(response.body).to include('<th class="cell-label cell-label--string" scope="col">Type</th>')
        expect(response.body).to include('<th class="cell-label cell-label--string" scope="col">Template</th>')
      end

      it 'shows the editor when creating a new template override' do
        allow(ChatwootHub).to receive(:pricing_plan).and_return('enterprise')
        sign_in(super_admin, scope: :super_admin)

        get '/super_admin/email_layout/edit', params: { new: 1, template_type: 'layout', template_name: 'base', locale: 'en' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Template details')
        expect(response.body).to include('email-template-selector-form')
        expect(response.body).to include('Type')
        expect(response.body).to include('Language')
        expect(response.body).to include('Inherits default template')
        expect(response.body).to include('Email layout preview')
        expect(response.body).to include('Variables')
        expect(response.body).to include('{{ content_for_layout }}')
        expect(response.body).to include('global_config[&#39;BRAND_NAME&#39;]')
        expect(response.body).to include('global_config[&#39;BRAND_URL&#39;]')
      end

      it 'shows the account email layout page' do
        allow(ChatwootHub).to receive(:pricing_plan).and_return('enterprise')
        sign_in(super_admin, scope: :super_admin)

        get "/super_admin/accounts/#{account.id}/email_layout/edit"

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Configure Settings - Acme Inc Email Templates')
        expect(response.body).to include('Create new template')
        expect(response.body).to include('<th class="cell-label cell-label--string" scope="col">Type</th>')
        expect(response.body).to include('<th class="cell-label cell-label--string" scope="col">Template</th>')
      end

      it 'lists configured account email templates' do
        allow(ChatwootHub).to receive(:pricing_plan).and_return('enterprise')
        create(
          :email_template,
          name: 'agent_notifications/conversation_notifications_mailer/conversation_assignment',
          body: 'Assigned',
          template_type: :content,
          locale: :fr,
          account: account
        )
        sign_in(super_admin, scope: :super_admin)

        get "/super_admin/accounts/#{account.id}/email_layout/edit"

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Create new template')
        expect(response.body).to include('Content')
        expect(response.body).to include('FR')
        expect(response.body).to include('Agent notifications/conversation notifications mailer/conversation assignment')
      end

      it 'shows the account email layout editor when creating a new template override' do
        allow(ChatwootHub).to receive(:pricing_plan).and_return('enterprise')
        sign_in(super_admin, scope: :super_admin)

        get "/super_admin/accounts/#{account.id}/email_layout/edit",
            params: { new: 1, template_type: 'layout', template_name: 'base', locale: 'en' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Template details')
        expect(response.body).to include('Acme Inc')
        expect(response.body).to include('{{ account.name }}')
      end

      it 'shows delete action for configured account email template overrides' do
        allow(ChatwootHub).to receive(:pricing_plan).and_return('enterprise')
        create(:email_template, name: 'base', body: '{{ content_for_layout }}', template_type: :layout, locale: :en, account: account)
        sign_in(super_admin, scope: :super_admin)

        get "/super_admin/accounts/#{account.id}/email_layout/edit", params: { template_type: 'layout', template_name: 'base', locale: 'en' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Destroy')
        expect(response.body).to include('button button--danger')
        expect(response.body).to include('Are you sure?')
      end

      it 'supports selecting content templates by locale' do
        allow(ChatwootHub).to receive(:pricing_plan).and_return('enterprise')
        sign_in(super_admin, scope: :super_admin)

        get "/super_admin/accounts/#{account.id}/email_layout/edit",
            params: {
              template_type: 'content',
              template_name: 'agent_notifications/conversation_notifications_mailer/conversation_assignment',
              locale: 'fr'
            }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Content')
        expect(response.body).to include('conversation assignment')
        expect(response.body).to include('FR')
      end

      it 'blocks access on community plan' do
        allow(ChatwootHub).to receive(:pricing_plan).and_return('community')
        sign_in(super_admin, scope: :super_admin)

        get '/super_admin/email_layout/edit'

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PATCH /super_admin/email_layout' do
    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        patch '/super_admin/email_layout', params: { email_layout: { body: '{{ content_for_layout }}' } }
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated super admin' do
      before do
        allow(ChatwootHub).to receive(:pricing_plan).and_return('enterprise')
        sign_in(super_admin, scope: :super_admin)
      end

      it 'creates a layout override' do
        body = '<html><body>{{ content_for_layout }}</body></html>'

        patch '/super_admin/email_layout', params: { email_layout: { body: body } }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(edit_super_admin_email_layout_path(template_type: 'layout', template_name: 'base', locale: 'en'))

        template = EmailTemplate.find_by(name: 'base', account: nil)
        expect(template).to be_present
        expect(template.template_type).to eq('layout')
        expect(template.body).to eq(body)
      end

      it 'creates an account layout override' do
        body = '<html><body>{{ content_for_layout }} {{ account.name }}</body></html>'

        patch "/super_admin/accounts/#{account.id}/email_layout", params: { email_layout: { body: body } }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(edit_super_admin_account_email_layout_path(account, template_type: 'layout', template_name: 'base',
                                                                                            locale: 'en'))

        template = EmailTemplate.find_by(name: 'base', account: account)
        expect(template).to be_present
        expect(template.template_type).to eq('layout')
        expect(template.body).to eq(body)
      end

      it 'returns validation error when content_for_layout is missing' do
        patch '/super_admin/email_layout', params: { email_layout: { body: '<html><body>No slot</body></html>' } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('Layout must include')
      end

      it 'returns validation error for invalid liquid syntax' do
        patch '/super_admin/email_layout', params: { email_layout: { body: '{{ content_for_layout }} {{ invalid ' } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('Liquid syntax error')
      end
    end
  end

  describe 'DELETE /super_admin/email_layout' do
    context 'when it is an unauthenticated super admin' do
      it 'returns unauthorized' do
        delete '/super_admin/email_layout'
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated super admin' do
      it 'removes custom layout override' do
        allow(ChatwootHub).to receive(:pricing_plan).and_return('enterprise')
        create(:email_template, name: 'base', body: '{{ content_for_layout }}', template_type: :layout, account: nil)
        sign_in(super_admin, scope: :super_admin)

        delete '/super_admin/email_layout'

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(edit_super_admin_email_layout_path)
        expect(EmailTemplate.find_by(name: 'base', account: nil)).to be_nil
      end

      it 'removes account layout override' do
        allow(ChatwootHub).to receive(:pricing_plan).and_return('enterprise')
        create(:email_template, name: 'base', body: '{{ content_for_layout }}', template_type: :layout, account: account)
        sign_in(super_admin, scope: :super_admin)

        delete "/super_admin/accounts/#{account.id}/email_layout"

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(edit_super_admin_account_email_layout_path(account))
        expect(EmailTemplate.find_by(name: 'base', account: account)).to be_nil
      end
    end
  end
end
