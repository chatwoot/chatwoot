require 'rails_helper'

RSpec.describe 'Super Admin accounts API', type: :request do
  include ActiveJob::TestHelper

  let!(:super_admin) { create(:super_admin) }
  let!(:account) { create(:account) }

  describe 'GET /super_admin/accounts' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get '/super_admin/accounts'
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated user' do
      it 'shows the list of accounts' do
        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/accounts'
        expect(response).to have_http_status(:success)
        expect(response.body).to include('New account')
        expect(response.body).to include(account.name)
      end
    end
  end

  describe 'GET /super_admin/accounts/{account_id}' do
    context 'when it is an authenticated user' do
      it 'shows effective Captain model routing', if: ChatwootApp.enterprise? do
        account.update!(captain_models: { 'editor' => 'gpt-4.1', 'conversation_completion' => 'gpt-5.2' })
        sign_in(super_admin, scope: :super_admin)

        get "/super_admin/accounts/#{account.id}"
        document = Nokogiri::HTML(response.body)
        summaries = document.css('details summary').map { |summary| summary.text.squish }
        routing_panel = document.at_css('#captain_models').parent.at_css('details')
        completion_card = routing_panel.css('.rounded-md').find { |card| card.text.include?('conversation_completion') }

        expect(response).to have_http_status(:success)
        expect(document.at_css('#captain_models').text.squish).to eq('Captain models')
        expect(summaries).to include('View model routing')
        expect(summaries).not_to include('All features', 'Captain models')
        expect(routing_panel.text.squish).to include('Customer features', 'Internal features')
        expect(completion_card.text.squish).to include('Inactive conversation completion evaluator', 'GPT-5.2', 'Account override')
        expect(response.body).to include('Editor', 'OpenAI', 'openai', 'gpt-4.1', 'Help center query translation', 'Default')
      end

      it 'shows the installation model for internal routing on self-hosted Enterprise', if: ChatwootApp.enterprise? do
        allow(ChatwootApp).to receive(:self_hosted_paid?).and_return(true)
        InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_MODEL').update!(value: 'gpt-5.1')
        sign_in(super_admin, scope: :super_admin)

        get "/super_admin/accounts/#{account.id}"
        document = Nokogiri::HTML(response.body)
        routing_panel = document.at_css('#captain_models').parent.at_css('details')
        completion_card = routing_panel.css('.rounded-md').find { |card| card.text.include?('conversation_completion') }

        expect(response).to have_http_status(:success)
        expect(completion_card.text.squish).to include(
          'Inactive conversation completion evaluator',
          'GPT-5.1',
          'Installation setting'
        )
      end
    end
  end

  describe 'GET /super_admin/accounts/{account_id}/edit' do
    context 'when it is an authenticated user' do
      it 'renders separate Captain model selectors for customer and internal AI features', if: ChatwootApp.enterprise? do
        allow(ChatwootApp).to receive(:self_hosted_paid?).and_return(true)
        InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_MODEL').update!(value: 'gpt-5.1')
        account.update!(captain_models: { 'editor' => 'gpt-4.1' })
        sign_in(super_admin, scope: :super_admin)

        get "/super_admin/accounts/#{account.id}/edit"

        expect(response).to have_http_status(:success)
        Llm::Models.feature_keys.each do |feature_key|
          expect(response.body).to include("account[captain_models][#{feature_key}]")
        end
        Llm::Models.internal_feature_keys.each do |feature_key|
          expect(response.body).to include("account[captain_models][#{feature_key}]")
        end

        document = Nokogiri::HTML(response.body)
        editor_select = document.at_css('select[name="account[captain_models][editor]"]')
        completion_select = document.at_css('select[name="account[captain_models][conversation_completion]"]')
        default_model_id = Llm::Models.default_model_for('editor')
        default_model = Llm::Models.model_config(default_model_id)['display_name']

        expect(response.body).to include('Customer features', 'Internal features')
        expect(editor_select.at_css('option[value=""]').text.squish).to eq("Use default: #{default_model} (#{default_model_id})")
        expect(completion_select.at_css('option[value=""]').text.squish).to eq('Use installation model: GPT-5.1 (gpt-5.1)')
        expect(completion_select.css('option').pluck('value')).to eq([''] + Llm::Models.models_for('conversation_completion'))
      end

      it 'shows the Captain V2 assistant default in the model selector', if: ChatwootApp.enterprise? do
        account.enable_features!('captain_integration')
        sign_in(super_admin, scope: :super_admin)

        get "/super_admin/accounts/#{account.id}/edit"

        document = Nokogiri::HTML(response.body)
        assistant_select = document.at_css('select[name="account[captain_models][assistant]"]')
        default_model_id = Llm::FeatureRouter::CAPTAIN_V2_ASSISTANT_MODEL
        default_model = Llm::Models.model_config(default_model_id)['display_name']

        expect(response).to have_http_status(:success)
        expect(assistant_select.at_css('option[value=""]').text.squish).to eq("Use default: #{default_model} (#{default_model_id})")
      end
    end
  end

  describe 'PATCH /super_admin/accounts/{account_id}' do
    context 'when it is an authenticated user' do
      it 'saves supported Assistant and Copilot model and effort overrides', if: ChatwootApp.enterprise? do
        account.enable_features!('captain_integration')
        account.update!(keep_pending_on_bot_failure: true)
        sign_in(super_admin, scope: :super_admin)

        patch "/super_admin/accounts/#{account.id}", params: {
          account: {
            name: account.name, locale: account.locale, status: account.status,
            captain_models: { assistant: 'gpt-6-astra', copilot: 'gpt-6-luna' },
            captain_reasoning_efforts: { assistant: 'high', copilot: 'none' }
          }
        }

        expect(response).to have_http_status(:redirect)
        expect(account.reload.keep_pending_on_bot_failure).to be true
        routes = %w[assistant copilot].map do |feature|
          Llm::FeatureRouter.resolve(feature: feature, account: account).slice(:model, :reasoning_effort)
        end
        expect(routes).to eq(
          [{ model: 'gpt-6-astra', reasoning_effort: :high }, { model: 'gpt-6-luna', reasoning_effort: :none }]
        )
        expect(account.captain_reasoning_efforts).to eq('assistant' => 'high', 'copilot' => 'none')

        get "/super_admin/accounts/#{account.id}/edit"
        document = Nokogiri::HTML(response.body)
        expect(document.css('select[data-captain-effort] option[selected]').pluck('value')).to eq(%w[high none])

        patch "/super_admin/accounts/#{account.id}", params: {
          account: {
            captain_reasoning_efforts: { assistant: '', copilot: '' }
          }
        }

        expect(response).to have_http_status(:redirect)
        default_effort = Llm::FeatureRouter.resolve(feature: 'assistant', account: account.reload)[:reasoning_effort]
        expect([account.captain_reasoning_efforts, default_effort]).to eq([nil, :low])
      end

      it 'rejects unsupported efforts without saving model changes', if: ChatwootApp.enterprise? do
        account.update!(captain_models: { 'assistant' => 'gpt-5.2' })
        sign_in(super_admin, scope: :super_admin)

        patch "/super_admin/accounts/#{account.id}", params: {
          account: {
            captain_models: { assistant: 'gpt-6-astra' },
            captain_reasoning_efforts: { assistant: 'none' }
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(account.reload.captain_models).to eq('assistant' => 'gpt-5.2')
        expect(account.captain_reasoning_efforts).to be_nil
      end

      it 'saves model and effort controls for every text feature', if: ChatwootApp.enterprise? do
        sign_in(super_admin, scope: :super_admin)
        features = Llm::FeatureRouter::REASONING_FEATURES
        patch "/super_admin/accounts/#{account.id}", params: {
          account: { captain_models: features.index_with { 'gpt-5.2' }, captain_reasoning_efforts: features.index_with { 'medium' } }
        }

        expect(response).to have_http_status(:redirect)
        features.each do |feature|
          expect(Llm::FeatureRouter.resolve(feature: feature, account: account.reload)).to include(model: 'gpt-5.2', reasoning_effort: :medium)
        end
        expect(account.captain_reasoning_efforts).not_to have_key('audio_transcription')
        expect(account.captain_reasoning_efforts).not_to have_key('help_center_search')
      end

      it 'updates Captain model overrides without changing unrelated settings' do
        account.update!(
          captain_models: { 'editor' => 'gpt-4.1' },
          keep_pending_on_bot_failure: true
        )
        sign_in(super_admin, scope: :super_admin)

        patch "/super_admin/accounts/#{account.id}",
              params: {
                account: {
                  name: account.name,
                  locale: account.locale,
                  status: account.status,
                  captain_models: {
                    editor: '',
                    assistant: 'gpt-5.2',
                    conversation_completion: 'gpt-5.2'
                  }
                }
              }

        expect(response).to have_http_status(:redirect)
        expect(account.reload.captain_models).to eq(
          'assistant' => 'gpt-5.2',
          'conversation_completion' => 'gpt-5.2'
        )
        expect(account.keep_pending_on_bot_failure).to be true
      end

      it 'rejects invalid Captain model overrides' do
        sign_in(super_admin, scope: :super_admin)
        existing_captain_models = account.captain_models

        patch "/super_admin/accounts/#{account.id}",
              params: {
                account: {
                  name: account.name,
                  locale: account.locale,
                  status: account.status,
                  captain_models: {
                    help_center_query_translation: 'unknown-model'
                  }
                }
              }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('not a valid model for help_center_query_translation')
        expect(account.reload.captain_models).to eq(existing_captain_models)
      end
    end
  end

  describe 'POST /super_admin/accounts/{account_id}/reset_cache' do
    before do
      create(:label, account: account)
      create(:inbox, account: account)
      create(:team, account: account)
    end

    after do
      Conversations::UnreadCounts::Store.clear_account!(account.id)
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/super_admin/accounts/#{account.id}/reset_cache"
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated user' do
      it 'shows the list of accounts' do
        expect(account.cache_keys.keys).to contain_exactly(:inbox, :label, :team, :canned_response)
        sign_in(super_admin, scope: :super_admin)

        now_timestamp = Time.now.utc.to_i
        post "/super_admin/accounts/#{account.id}/reset_cache"
        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to eq('Cache keys cleared')

        range = now_timestamp..(now_timestamp + 10)
        expect(account.reload.cache_keys.values.all? { |v| range.cover?(v.to_i) }).to be(true)
      end

      it 'clears conversation unread count cache' do
        inbox = account.inboxes.first
        store = Conversations::UnreadCounts::Store
        inbox_key = store.inbox_key(account.id, inbox.id)
        store.mark_base_ready!(account.id)
        store.add_base_membership(account_id: account.id, inbox_id: inbox.id, label_ids: [], conversation_id: 1)

        sign_in(super_admin, scope: :super_admin)
        post "/super_admin/accounts/#{account.id}/reset_cache"

        expect(response).to have_http_status(:redirect)
        expect(store.base_ready?(account.id)).to be(false)
        expect(store.counts_for_keys([inbox_key])).to eq(inbox_key => 0)
      end
    end
  end

  describe 'DELETE /super_admin/accounts/{account_id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/super_admin/accounts/#{account.id}"
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when it is an authenticated user' do
      it 'Deletes the account' do
        total_accounts = Account.count
        sign_in(super_admin, scope: :super_admin)

        perform_enqueued_jobs(only: DeleteObjectJob) do
          delete "/super_admin/accounts/#{account.id}"
        end

        expect(Account.count).to eq(total_accounts - 1)
      end
    end
  end
end
