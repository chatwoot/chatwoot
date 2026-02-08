require 'rails_helper'
require 'rake'

RSpec.describe 'socialwise:setup', type: :task do
  let(:account) { create(:account) }
  
  before do
    Rake.application.rake_require 'tasks/setup_socialwise'
    Rake::Task.define_task(:environment)
  end

  describe 'socialwise:setup' do
    let(:task) { Rake::Task['socialwise:setup'] }
    
    before do
      task.reenable
    end

    context 'when account exists' do
      it 'creates new SocialWise hook when none exists' do
        expect {
          task.invoke(account.id)
        }.to change { account.hooks.where(app_id: 'socialwise_chatwit').count }.from(0).to(1)
        
        hook = account.hooks.find_by(app_id: 'socialwise_chatwit')
        expect(hook.status).to eq('enabled')
        expect(hook.settings['enabled']).to be true
        expect(hook.hook_type).to eq('account')
      end

      it 'updates existing disabled SocialWise hook' do
        existing_hook = create(:integrations_hook, 
                              app_id: 'socialwise_chatwit', 
                              status: 'disabled', 
                              account: account,
                              settings: { 'enabled' => false })
        
        expect {
          task.invoke(account.id)
        }.not_to change { account.hooks.where(app_id: 'socialwise_chatwit').count }
        
        existing_hook.reload
        expect(existing_hook.status).to eq('enabled')
        expect(existing_hook.settings['enabled']).to be true
      end

      it 'updates existing hook with incorrect settings' do
        existing_hook = create(:integrations_hook, 
                              app_id: 'socialwise_chatwit', 
                              status: 'enabled', 
                              account: account,
                              settings: { 'enabled' => false })
        
        expect {
          task.invoke(account.id)
        }.not_to change { account.hooks.where(app_id: 'socialwise_chatwit').count }
        
        existing_hook.reload
        expect(existing_hook.status).to eq('enabled')
        expect(existing_hook.settings['enabled']).to be true
      end

      it 'does not modify correctly configured hook' do
        existing_hook = create(:integrations_hook, 
                              app_id: 'socialwise_chatwit', 
                              status: 'enabled', 
                              account: account,
                              settings: { 'enabled' => true })
        
        original_updated_at = existing_hook.updated_at
        
        task.invoke(account.id)
        
        existing_hook.reload
        expect(existing_hook.updated_at).to eq(original_updated_at)
        expect(existing_hook.status).to eq('enabled')
        expect(existing_hook.settings['enabled']).to be true
      end

      context 'when Dialogflow hook exists' do
        it 'provides informational message about Dialogflow integration' do
          create(:integrations_hook, app_id: 'dialogflow', account: account)
          
          expect { task.invoke(account.id) }.to output(/Hook Dialogflow encontrado.*Socialwise funcionará com Dialogflow/).to_stdout
        end
      end

      context 'when Dialogflow hook does not exist' do
        it 'provides informational message about independent operation' do
          expect { task.invoke(account.id) }.to output(/Hook Dialogflow não encontrado.*Socialwise funcionará independentemente/).to_stdout
        end
      end

      it 'works independently of Dialogflow configuration' do
        # Should not require Dialogflow to be present
        expect {
          task.invoke(account.id)
        }.to change { account.hooks.where(app_id: 'socialwise_chatwit').count }.from(0).to(1)
        
        hook = account.hooks.find_by(app_id: 'socialwise_chatwit')
        expect(hook).to be_present
        expect(hook.status).to eq('enabled')
      end

      it 'displays success message' do
        expect { task.invoke(account.id) }.to output(/Configuração concluída!/).to_stdout
      end

      it 'displays account information' do
        expect { task.invoke(account.id) }.to output(/Configurando para conta: #{account.name} \(ID: #{account.id}\)/).to_stdout
      end
    end

    context 'when account does not exist' do
      it 'displays error message and exits' do
        non_existent_id = 99999
        
        expect { task.invoke(non_existent_id) }.to raise_error(SystemExit)
      end
    end

    context 'when using environment variable for account_id' do
      it 'uses ACCOUNT_ID environment variable when no argument provided' do
        ENV['ACCOUNT_ID'] = account.id.to_s
        
        expect {
          task.invoke
        }.to change { account.hooks.where(app_id: 'socialwise_chatwit').count }.from(0).to(1)
        
        ENV.delete('ACCOUNT_ID')
      end
    end

    context 'when no account_id provided' do
      it 'defaults to account ID 2' do
        default_account = create(:account, id: 2)
        
        expect {
          task.invoke
        }.to change { default_account.hooks.where(app_id: 'socialwise_chatwit').count }.from(0).to(1)
      end
    end
  end

  describe 'socialwise:list' do
    let(:task) { Rake::Task['socialwise:list'] }
    
    before do
      task.reenable
    end

    context 'when no SocialWise hooks exist' do
      it 'displays no hooks found message' do
        expect { task.invoke }.to output(/Nenhum hook Socialwise encontrado/).to_stdout
      end
    end

    context 'when SocialWise hooks exist' do
      let!(:hook1) { create(:integrations_hook, app_id: 'socialwise_chatwit', account: account) }
      let!(:hook2) { create(:integrations_hook, app_id: 'socialwise_chatwit', account: create(:account)) }

      it 'lists all SocialWise hooks' do
        output = capture_stdout { task.invoke }
        
        expect(output).to include("Hook ID: #{hook1.id}")
        expect(output).to include("Hook ID: #{hook2.id}")
        expect(output).to include("Conta: #{hook1.account.name}")
        expect(output).to include("Conta: #{hook2.account.name}")
      end

      it 'displays hook details' do
        output = capture_stdout { task.invoke }
        
        expect(output).to include("Status: #{hook1.status}")
        expect(output).to include("Settings: #{hook1.settings}")
        expect(output).to include("Criado em:")
      end
    end
  end

  private

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end