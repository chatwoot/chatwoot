require 'rails_helper'

RSpec.describe Microsoft::RefreshOauthTokenService do
  let!(:microsoft_channel) { create(:channel_email, :microsoft_email) }
  let!(:microsoft_channel_with_expired_token) do
    create(
      :channel_email, :microsoft_email, provider_config: {
        expires_on: Time.zone.now - 3600,
        access_token: SecureRandom.hex,
        refresh_token: SecureRandom.hex
      }
    )
  end

  let(:new_tokens) do
    {
      access_token: SecureRandom.hex,
      refresh_token: SecureRandom.hex,
      expires_at: (Time.zone.now + 3600).to_i,
      token_type: 'bearer'
    }
  end

  context 'when token is not expired' do
    it 'returns the existing access token' do
      service = described_class.new(channel: microsoft_channel)

      expect(service.access_token).to eq(microsoft_channel.provider_config['access_token'])
      expect(microsoft_channel.reload.provider_config['refresh_token']).to eq(microsoft_channel.provider_config['refresh_token'])
    end
  end

  # Os dois exemplos abaixo cobram o VALOR que o refresh devolve, nao a diferenca em relacao ao
  # token velho. `not_to eq(o token velho)` passa com nil, e passava: `refresh_tokens` devolvia a
  # coluna crua, de chaves String, para um leitor que pede `[:access_token]`. Quem consome esse
  # retorno e `Imap::MicrosoftFetchEmailService#imap_password`, ou seja a senha do IMAP era nil
  # sempre que o token tinha expirado.
  describe 'on expired token or invalid expiry' do
    before do
      stub_request(:post, 'https://login.microsoftonline.com/common/oauth2/v2.0/token').with(
        body: { 'grant_type' => 'refresh_token', 'refresh_token' => microsoft_channel_with_expired_token.provider_config['refresh_token'] }
      ).to_return(status: 200, body: new_tokens.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    context 'when token is invalid' do
      it 'fetches new access token and refresh tokens' do
        with_modified_env AZURE_APP_ID: SecureRandom.uuid, AZURE_APP_SECRET: SecureRandom.hex do
          service = described_class.new(channel: microsoft_channel_with_expired_token)
          expect(service.access_token).to eq(new_tokens[:access_token])

          new_provider_config = microsoft_channel_with_expired_token.reload.provider_config
          expect(new_provider_config['access_token']).to eq(new_tokens[:access_token])
          expect(new_provider_config['refresh_token']).to eq(new_tokens[:refresh_token])
          expect(new_provider_config['expires_on']).to eq(Time.at(new_tokens[:expires_at]).utc.to_s)
        end
      end
    end

    context 'when expiry time is missing' do
      it 'fetches new access token and refresh tokens' do
        with_modified_env AZURE_APP_ID: SecureRandom.uuid, AZURE_APP_SECRET: SecureRandom.hex do
          microsoft_channel_with_expired_token.provider_config['expires_on'] = nil
          microsoft_channel_with_expired_token.save!
          service = described_class.new(channel: microsoft_channel_with_expired_token)
          expect(service.access_token).to eq(new_tokens[:access_token])

          new_provider_config = microsoft_channel_with_expired_token.reload.provider_config
          expect(new_provider_config['access_token']).to eq(new_tokens[:access_token])
          expect(new_provider_config['refresh_token']).to eq(new_tokens[:refresh_token])
          expect(new_provider_config['expires_on']).to eq(Time.at(new_tokens[:expires_at]).utc.to_s)
        end
      end
    end
  end

  context 'when refresh token is not present in provider config and access token is expired' do
    it 'throws an error' do
      with_modified_env AZURE_APP_ID: SecureRandom.uuid, AZURE_APP_SECRET: SecureRandom.hex do
        microsoft_channel.update!(
          provider_config: {
            access_token: SecureRandom.hex,
            expires_on: Time.zone.now - 3600
          }
        )

        expect do
          described_class.new(channel: microsoft_channel).access_token
        end.to raise_error(RuntimeError, 'A refresh_token is not available')
      end
    end
  end

  # A escrita de terceiro que entra DURANTE a chamada de rede. Sem thread: a copia em memoria
  # ja esta velha quando volta para a linha, e e por isso que o defeito reproduz com um stub.
  describe 'when another writer lands on provider_config during the refresh' do
    let(:channel) do
      create(:channel_email, :microsoft_email, provider_config: {
               expires_on: Time.zone.now - 3600,
               access_token: SecureRandom.hex,
               refresh_token: SecureRandom.hex,
               imap_login_hint: 'someone@example.com'
             })
    end

    before do
      stub_request(:post, 'https://login.microsoftonline.com/common/oauth2/v2.0/token').to_return do
        # Uma chave que nenhum dos dois lados do refresh escreve, gravada direto na linha para
        # simular o outro escritor: a API de migracao de canal de e-mail (que aceita
        # `provider_config` como hash aberto) e o unico caminho por onde ela chega hoje.
        Channel::Email.where(id: channel.id)
                      .update_all("provider_config = provider_config || '{\"migrated_by\":\"platform-api\"}'::jsonb")  # rubocop:disable Rails/SkipsModelValidations
        { status: 200, body: new_tokens.to_json, headers: { 'Content-Type' => 'application/json' } }
      end
    end

    it 'keeps the key that landed while the provider was answering' do
      with_modified_env AZURE_APP_ID: SecureRandom.uuid, AZURE_APP_SECRET: SecureRandom.hex do
        described_class.new(channel: channel).access_token
      end

      expect(channel.reload.provider_config['migrated_by']).to eq('platform-api')
    end

    it 'keeps the keys the refresh does not own' do
      with_modified_env AZURE_APP_ID: SecureRandom.uuid, AZURE_APP_SECRET: SecureRandom.hex do
        described_class.new(channel: channel).access_token
      end

      expect(channel.reload.provider_config['imap_login_hint']).to eq('someone@example.com')
    end

    it 'still writes the three keys it does own' do
      with_modified_env AZURE_APP_ID: SecureRandom.uuid, AZURE_APP_SECRET: SecureRandom.hex do
        described_class.new(channel: channel).access_token
      end

      config = channel.reload.provider_config
      expect(config['access_token']).to eq(new_tokens[:access_token])
      expect(config['refresh_token']).to eq(new_tokens[:refresh_token])
      expect(config['expires_on']).to eq(Time.at(new_tokens[:expires_at]).utc.to_s)
    end
  end

  # O outro eixo, e o que o merge nao alcanca: o outro escritor e outro refresh, entao as chaves que
  # ele escreveu sao as mesmas que este vai escrever. Os dois trocaram o MESMO refresh token antes de
  # qualquer um gravar, e um provedor que rota o refresh token invalida o antigo, logo so um dos dois
  # pares e vivo. Gravar por cima deixa a linha com um token que o provedor ja nao honra, e o canal
  # para de buscar e-mail ate alguem reconectar a mao (issue #557, que nomeia o conserto: quem perdeu
  # tem que perceber, em vez de sobrescrever).
  describe 'when another refresh of the same channel rotated the token during this one' do
    let(:winner) do
      { access_token: 'AT_WINNER', refresh_token: 'RT_WINNER', expires_on: (Time.zone.now + 7200).utc.to_s }
    end

    let(:channel) do
      create(:channel_email, :microsoft_email, provider_config: {
               expires_on: Time.zone.now - 3600,
               access_token: SecureRandom.hex,
               refresh_token: SecureRandom.hex
             })
    end

    before do
      allow(Rails.logger).to receive(:warn)
      stub_request(:post, 'https://login.microsoftonline.com/common/oauth2/v2.0/token').to_return do
        Channel::Email.where(id: channel.id)
                      .update_all(['provider_config = provider_config || ?::jsonb', winner.to_json])  # rubocop:disable Rails/SkipsModelValidations
        { status: 200, body: new_tokens.to_json, headers: { 'Content-Type' => 'application/json' } }
      end
    end

    it 'leaves the row with the token set that won' do
      with_modified_env AZURE_APP_ID: SecureRandom.uuid, AZURE_APP_SECRET: SecureRandom.hex do
        described_class.new(channel: channel).access_token
      end

      config = channel.reload.provider_config
      expect(config['refresh_token']).to eq('RT_WINNER')
      expect(config['access_token']).to eq('AT_WINNER')
    end

    it 'hands the caller the token that is in the row, not the one it could not store' do
      token = with_modified_env AZURE_APP_ID: SecureRandom.uuid, AZURE_APP_SECRET: SecureRandom.hex do
        described_class.new(channel: channel).access_token
      end

      expect(token).to eq('AT_WINNER')
    end

    # Perceber e o requisito, e uma rotacao gasta e depois descartada e justamente o evento que
    # ninguem reconstroi depois: o provedor viu um token que esta linha nunca teve.
    it 'says the rotation it spent was not stored' do
      with_modified_env AZURE_APP_ID: SecureRandom.uuid, AZURE_APP_SECRET: SecureRandom.hex do
        described_class.new(channel: channel).access_token
      end

      expect(Rails.logger).to have_received(:warn).with(/refresh token this call spent/)
    end
  end
end
