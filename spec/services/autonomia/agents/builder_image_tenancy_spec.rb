require 'rails_helper'

# D3 — signed_id de blob é global (find_signed não conhece conta): o Builder só pode
# resolver imagens cujo blob foi criado no contexto da MESMA conta (metadata gravado
# no upload). Blob de outra conta (ou sem metadata) é descartado com warn.
RSpec.describe Autonomia::Agents::Builder do
  let(:account) { create(:account) }
  let(:other_account) { create(:account) }
  let(:thread) { Autonomia::Agents::BuildThread.create!(account: account) }
  let(:builder) { described_class.new(account: account, build_thread: thread) }

  let(:png_bytes) { "\x89PNG\r\n\x1a\n".b }

  def create_image_blob(owner_account_id)
    metadata = owner_account_id ? { autonomia_account_id: owner_account_id } : {}
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(png_bytes), filename: 'test.png', content_type: 'image/png',
      identify: false, metadata: metadata
    )
  end

  def signed_id_for(blob)
    blob.signed_id(purpose: :autonomia_builder_image, expires_in: 1.day)
  end

  describe '#image_part tenancy check' do
    it 'resolves a blob uploaded in the same account' do
      # Arrange
      blob = create_image_blob(account.id)

      # Act
      part = builder.send(:image_part, signed_id_for(blob))

      # Assert
      expect(part).to include(type: 'input_image')
      expect(part[:image_url]).to start_with('data:image/png;base64,')
    end

    it 'discards a blob uploaded in another account' do
      # Arrange
      blob = create_image_blob(other_account.id)
      allow(Rails.logger).to receive(:warn)

      # Act
      part = builder.send(:image_part, signed_id_for(blob))

      # Assert
      expect(part).to be_nil
      expect(Rails.logger).to have_received(:warn).with(/not owned by account #{account.id}/)
    end

    it 'discards a blob without account metadata' do
      # Arrange
      blob = create_image_blob(nil)

      # Act
      part = builder.send(:image_part, signed_id_for(blob))

      # Assert
      expect(part).to be_nil
    end
  end
end
