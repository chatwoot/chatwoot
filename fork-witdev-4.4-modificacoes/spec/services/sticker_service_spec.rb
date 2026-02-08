require 'rails_helper'

RSpec.describe StickerService, type: :service do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account) }

  describe '#initialize' do
    it 'sets the account' do
      expect(service.send(:account)).to eq(account)
    end

    it 'raises InvalidAccountError when account is nil' do
      expect { described_class.new(nil) }.to raise_error(StickerService::InvalidAccountError, 'Account is required')
    end
  end

  describe '#custom_stickers' do
    let!(:custom_sticker1) do
      create(:attachment,
             account: account,
             file_type: :image,
             meta: { 'sticker_type' => 'custom', 'sticker_pack' => 'Company' })
    end

    let!(:custom_sticker2) do
      create(:attachment,
             account: account,
             file_type: :image,
             meta: { 'sticker_type' => 'custom', 'sticker_pack' => 'Fun' })
    end

    let!(:regular_attachment) do
      create(:attachment,
             account: account,
             file_type: :image,
             meta: { 'type' => 'regular' })
    end

    let!(:other_account_sticker) do
      create(:attachment,
             account: create(:account),
             file_type: :image,
             meta: { 'sticker_type' => 'custom', 'sticker_pack' => 'Other' })
    end

    before do
      Rails.cache.clear
    end

    context 'without pack_name filter' do
      it 'returns all custom stickers for the account' do
        stickers = service.custom_stickers

        expect(stickers.length).to eq(2)
        expect(stickers.map { |s| s[:id] }).to contain_exactly(custom_sticker1.id, custom_sticker2.id)
        expect(stickers.first[:provider]).to eq('custom')
        expect(stickers.first[:url]).to be_present
      end

      it 'caches results with proper TTL' do
        expect(Rails.cache).to receive(:fetch)
          .with(anything, expires_in: described_class::CUSTOM_STICKERS_CACHE_TTL)
          .and_call_original

        service.custom_stickers
      end

      it 'tracks cache hits and misses' do
        # First call should be a miss
        service.custom_stickers
        expect(Rails.cache.read('sticker_service_cache_miss')).to eq(1)

        # Second call should be a hit
        service.custom_stickers
        expect(Rails.cache.read('sticker_service_cache_hit')).to eq(1)
      end
    end

    context 'with pack_name filter' do
      it 'returns only stickers from the specified pack' do
        stickers = service.custom_stickers('Company')

        expect(stickers.length).to eq(1)
        expect(stickers.first[:id]).to eq(custom_sticker1.id)
        expect(stickers.first[:alt]).to eq('Company')
      end

      it 'returns empty array for non-existent pack' do
        stickers = service.custom_stickers('NonExistent')

        expect(stickers).to be_empty
      end

      it 'uses different cache keys for different packs' do
        key1 = service.send(:generate_stickers_cache_key, 'Company')
        key2 = service.send(:generate_stickers_cache_key, 'Fun')
        key3 = service.send(:generate_stickers_cache_key, nil)

        expect(key1).not_to eq(key2)
        expect(key1).not_to eq(key3)
        expect(key2).not_to eq(key3)
      end
    end

    context 'cache error handling' do
      it 'tracks cache errors and returns empty array' do
        allow(Rails.cache).to receive(:fetch).and_raise(StandardError.new('Cache error'))
        
        stickers = service.custom_stickers
        expect(stickers).to eq([])
        expect(Rails.cache.read('sticker_service_cache_error')).to eq(1)
      end
    end

    it 'does not include regular attachments' do
      stickers = service.custom_stickers

      expect(stickers.map { |s| s[:id] }).not_to include(regular_attachment.id)
    end

    it 'does not include stickers from other accounts' do
      stickers = service.custom_stickers

      expect(stickers.map { |s| s[:id] }).not_to include(other_account_sticker.id)
    end
  end

  describe '#custom_sticker_packs' do
    let!(:pack1_sticker1) do
      create(:attachment,
             account: account,
             file_type: :image,
             meta: { 'sticker_type' => 'custom', 'sticker_pack' => 'Company' })
    end

    let!(:pack1_sticker2) do
      create(:attachment,
             account: account,
             file_type: :image,
             meta: { 'sticker_type' => 'custom', 'sticker_pack' => 'Company' })
    end

    let!(:pack2_sticker) do
      create(:attachment,
             account: account,
             file_type: :image,
             meta: { 'sticker_type' => 'custom', 'sticker_pack' => 'Fun' })
    end

    before do
      Rails.cache.clear
    end

    it 'returns unique pack names sorted alphabetically' do
      packs = service.custom_sticker_packs

      expect(packs.length).to eq(2)
      expect(packs.map { |p| p[:name] }).to eq(['Company', 'Fun'])
      expect(packs.map { |p| p[:id] }).to eq(['Company', 'Fun'])
    end

    it 'caches results with proper TTL' do
      expect(Rails.cache).to receive(:fetch)
        .with(anything, expires_in: described_class::STICKER_PACKS_CACHE_TTL)
        .and_call_original

      service.custom_sticker_packs
    end

    it 'tracks cache hits and misses for packs' do
      # First call should be a miss
      service.custom_sticker_packs
      expect(Rails.cache.read('sticker_service_cache_packs_miss')).to eq(1)

      # Second call should be a hit
      service.custom_sticker_packs
      expect(Rails.cache.read('sticker_service_cache_packs_hit')).to eq(1)
    end

    it 'returns empty array when no custom stickers exist' do
      Attachment.where(account: account).destroy_all
      Rails.cache.clear

      packs = service.custom_sticker_packs

      expect(packs).to be_empty
    end

    context 'cache error handling' do
      it 'tracks cache errors and returns empty array' do
        allow(Rails.cache).to receive(:fetch).and_raise(StandardError.new('Cache error'))
        
        packs = service.custom_sticker_packs
        expect(packs).to eq([])
        expect(Rails.cache.read('sticker_service_cache_packs_error')).to eq(1)
      end
    end
  end

  describe '#create_custom_sticker' do
    let(:pack_name) { 'Test Pack' }
    let(:tags) { ['test', 'sample'] }
    let(:mock_file) { double('file') }
    let(:mock_uploader) { instance_double(StickerUploader) }
    let(:mock_attachment) { create(:attachment, account: account) }

    before do
      allow(StickerUploader).to receive(:new).and_return(mock_uploader)
    end

    context 'validation errors' do
      it 'returns validation error when pack_name is blank' do
        result = service.create_custom_sticker('', mock_file, tags)

        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('VALIDATION_ERROR')
        expect(result[:user_message]).to eq('Please check your sticker file and try again.')
      end

      it 'returns validation error when file is nil' do
        result = service.create_custom_sticker(pack_name, nil, tags)

        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('VALIDATION_ERROR')
      end

      it 'returns validation error when pack_name is too long' do
        long_name = 'a' * 51
        result = service.create_custom_sticker(long_name, mock_file, tags)

        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('VALIDATION_ERROR')
      end

      it 'returns validation error when pack_name has invalid characters' do
        invalid_name = 'Test Pack @#$%'
        result = service.create_custom_sticker(invalid_name, mock_file, tags)

        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('VALIDATION_ERROR')
      end

      it 'returns validation error when file is not file-like' do
        invalid_file = 'not a file'
        result = service.create_custom_sticker(pack_name, invalid_file, tags)

        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('VALIDATION_ERROR')
      end
    end

    context 'when upload processing succeeds' do
      before do
        processed_file = double('processed_file')
        allow(processed_file).to receive(:close)
        allow(processed_file).to receive(:unlink)
        
        allow(mock_uploader).to receive(:process_and_validate).and_return(true)
        allow(mock_uploader).to receive(:pack_name).and_return(pack_name)
        allow(mock_uploader).to receive(:tags).and_return(tags)
        allow(mock_uploader).to receive(:processed_file).and_return(processed_file)
        allow(mock_uploader).to receive(:processed_filename).and_return('sticker_123.webp')
        allow(service).to receive(:create_attachment_with_processed_file).and_return(mock_attachment)
        allow(mock_attachment).to receive(:download_url).and_return('http://example.com/sticker.webp')
        allow(mock_attachment).to receive(:meta).and_return({ 'sticker_type' => 'custom' })
      end

      it 'creates a custom sticker successfully' do
        result = service.create_custom_sticker(pack_name, mock_file, tags)

        expect(result[:success]).to be true
        expect(result[:sticker][:id]).to eq(mock_attachment.id)
        expect(result[:sticker][:provider]).to eq('custom')
        expect(result[:sticker][:alt]).to eq(pack_name)
      end

      it 'initializes StickerUploader with correct parameters' do
        service.create_custom_sticker(pack_name, mock_file, tags)

        expect(StickerUploader).to have_received(:new).with(
          file: mock_file,
          pack_name: pack_name,
          tags: tags
        )
      end

      it 'cleans up temporary file' do
        processed_file = double('processed_file')
        allow(mock_uploader).to receive(:processed_file).and_return(processed_file)
        allow(processed_file).to receive(:close)
        allow(processed_file).to receive(:unlink)

        service.create_custom_sticker(pack_name, mock_file, tags)

        expect(processed_file).to have_received(:close)
        expect(processed_file).to have_received(:unlink)
      end
    end

    context 'when upload processing fails' do
      let(:error_messages) { ['File is too large', 'Invalid format'] }

      before do
        allow(mock_uploader).to receive(:process_and_validate).and_return(false)
        allow(mock_uploader).to receive(:errors).and_return(error_messages)
      end

      it 'returns failure with error messages' do
        result = service.create_custom_sticker(pack_name, mock_file, tags)

        expect(result[:success]).to be false
        expect(result[:errors]).to eq(error_messages)
        expect(result[:error_code]).to eq('VALIDATION_ERROR')
        expect(result[:user_message]).to eq('Please check your sticker file and try again.')
      end
    end

    context 'when attachment creation fails' do
      before do
        processed_file = double('processed_file')
        allow(processed_file).to receive(:close)
        allow(processed_file).to receive(:unlink)
        
        allow(mock_uploader).to receive(:process_and_validate).and_return(true)
        allow(mock_uploader).to receive(:processed_file).and_return(processed_file)
        allow(service).to receive(:create_attachment_with_processed_file).and_raise(StickerService::StorageError.new('Database error'))
      end

      it 'returns failure with error message' do
        result = service.create_custom_sticker(pack_name, mock_file, tags)

        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('STORAGE_ERROR')
        expect(result[:user_message]).to eq('Failed to save sticker. Please try again.')
      end

      it 'logs the error' do
        allow(Rails.logger).to receive(:error)

        service.create_custom_sticker(pack_name, mock_file, tags)

        expect(Rails.logger).to have_received(:error).with(/StickerService storage error/)
      end
    end

    context 'when unexpected error occurs' do
      before do
        allow(mock_uploader).to receive(:process_and_validate).and_raise(StandardError.new('Unexpected error'))
      end

      it 'returns failure with generic error message' do
        result = service.create_custom_sticker(pack_name, mock_file, tags)

        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('UNKNOWN_ERROR')
        expect(result[:user_message]).to eq('An error occurred. Please try again.')
      end

      it 'logs the error with backtrace' do
        expect(Rails.logger).to receive(:error).with(/StickerService unexpected error.*Unexpected error/m)

        service.create_custom_sticker(pack_name, mock_file, tags)
      end
    end
  end

  describe '#delete_custom_sticker' do
    let!(:custom_sticker) do
      create(:attachment,
             account: account,
             file_type: :image,
             meta: { 'sticker_type' => 'custom', 'sticker_pack' => 'Test' })
    end

    let!(:regular_attachment) do
      create(:attachment,
             account: account,
             file_type: :image,
             meta: { 'type' => 'regular' })
    end

    context 'validation errors' do
      it 'returns validation error for blank sticker_id' do
        result = service.delete_custom_sticker('')

        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('VALIDATION_ERROR')
        expect(result[:user_message]).to eq('Invalid sticker data. Please check your input and try again.')
      end

      it 'returns validation error for invalid sticker_id format' do
        result = service.delete_custom_sticker('invalid_id')

        expect(result[:success]).to be false
        expect(result[:error_code]).to eq('VALIDATION_ERROR')
      end
    end

    it 'deletes a custom sticker successfully' do
      result = service.delete_custom_sticker(custom_sticker.id)

      expect(result[:success]).to be true
      expect { custom_sticker.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'returns error for non-existent sticker' do
      result = service.delete_custom_sticker(999999)

      expect(result[:success]).to be false
      expect(result[:error_code]).to eq('STICKER_NOT_FOUND')
      expect(result[:user_message]).to eq('Sticker not found. It may have been deleted already.')
    end

    it 'returns error for non-custom sticker' do
      result = service.delete_custom_sticker(regular_attachment.id)

      expect(result[:success]).to be false
      expect(result[:error_code]).to eq('STICKER_NOT_FOUND')
    end

    it 'handles deletion errors gracefully' do
      allow(custom_sticker).to receive(:destroy!).and_raise(StandardError.new('Deletion failed'))
      allow(service).to receive(:find_custom_sticker).and_return(custom_sticker)

      result = service.delete_custom_sticker(custom_sticker.id)

      expect(result[:success]).to be false
      expect(result[:error_code]).to eq('DELETE_ERROR')
      expect(result[:user_message]).to eq('Failed to delete sticker. Please try again.')
    end
  end

  describe '#update_sticker_pack' do
    let!(:custom_sticker) do
      create(:attachment,
             account: account,
             file_type: :image,
             meta: { 'sticker_type' => 'custom', 'sticker_pack' => 'Old Pack' })
    end

    let(:new_pack_name) { 'New Pack' }

    it 'updates sticker pack successfully' do
      result = service.update_sticker_pack(custom_sticker.id, new_pack_name)

      expect(result[:success]).to be true
      expect(custom_sticker.reload.meta['sticker_pack']).to eq(new_pack_name)
    end

    it 'returns error for non-existent sticker' do
      result = service.update_sticker_pack(999999, new_pack_name)

      expect(result[:success]).to be false
      expect(result[:error]).to eq('Sticker not found')
    end

    it 'returns error for non-custom sticker' do
      regular_attachment = create(:attachment, account: account, file_type: :image)
      result = service.update_sticker_pack(regular_attachment.id, new_pack_name)

      expect(result[:success]).to be false
      expect(result[:error]).to eq('Not a custom sticker')
    end

    it 'handles update errors gracefully' do
      allow(custom_sticker).to receive(:update!).and_raise(StandardError.new('Update failed'))
      allow(Attachment).to receive(:find_by).and_return(custom_sticker)

      result = service.update_sticker_pack(custom_sticker.id, new_pack_name)

      expect(result[:success]).to be false
      expect(result[:error]).to eq('Failed to update sticker pack')
    end
  end

  describe 'cache invalidation' do
    let!(:custom_sticker) do
      create(:attachment,
             account: account,
             file_type: :image,
             meta: { 'sticker_type' => 'custom', 'sticker_pack' => 'Test Pack' })
    end

    before do
      Rails.cache.clear
      # Pre-populate cache
      service.custom_stickers
      service.custom_stickers('Test Pack')
      service.custom_sticker_packs
    end

    describe '#create_custom_sticker' do
      let(:mock_uploader) { instance_double(StickerUploader) }
      let(:mock_attachment) { create(:attachment, account: account) }

      before do
        allow(StickerUploader).to receive(:new).and_return(mock_uploader)
        allow(mock_uploader).to receive(:process_and_validate).and_return(true)
        allow(mock_uploader).to receive(:pack_name).and_return('Test Pack')
        allow(mock_uploader).to receive(:tags).and_return([])
        allow(mock_uploader).to receive(:processed_file).and_return(double(close: nil, unlink: nil))
        allow(mock_uploader).to receive(:processed_filename).and_return('test.webp')
        allow(service).to receive(:create_attachment_with_processed_file).and_return(mock_attachment)
        allow(mock_attachment).to receive(:download_url).and_return('http://example.com/test.webp')
        allow(mock_attachment).to receive(:meta).and_return({ 'sticker_type' => 'custom' })
      end

      it 'invalidates relevant caches after creating sticker' do
        all_cache_key = service.send(:generate_stickers_cache_key, nil)
        pack_cache_key = service.send(:generate_stickers_cache_key, 'Test Pack')
        packs_cache_key = service.send(:generate_packs_cache_key)

        # Verify caches exist
        expect(Rails.cache.exist?(all_cache_key)).to be true
        expect(Rails.cache.exist?(pack_cache_key)).to be true
        expect(Rails.cache.exist?(packs_cache_key)).to be true

        service.create_custom_sticker('Test Pack', double('file'))

        # Verify caches are invalidated
        expect(Rails.cache.exist?(all_cache_key)).to be false
        expect(Rails.cache.exist?(pack_cache_key)).to be false
        expect(Rails.cache.exist?(packs_cache_key)).to be false
      end
    end

    describe '#delete_custom_sticker' do
      it 'invalidates relevant caches after deleting sticker' do
        all_cache_key = service.send(:generate_stickers_cache_key, nil)
        pack_cache_key = service.send(:generate_stickers_cache_key, 'Test Pack')
        packs_cache_key = service.send(:generate_packs_cache_key)

        # Verify caches exist
        expect(Rails.cache.exist?(all_cache_key)).to be true
        expect(Rails.cache.exist?(pack_cache_key)).to be true
        expect(Rails.cache.exist?(packs_cache_key)).to be true

        service.delete_custom_sticker(custom_sticker.id)

        # Verify caches are invalidated
        expect(Rails.cache.exist?(all_cache_key)).to be false
        expect(Rails.cache.exist?(pack_cache_key)).to be false
        expect(Rails.cache.exist?(packs_cache_key)).to be false
      end
    end

    describe '#update_sticker_pack' do
      it 'invalidates caches for both old and new pack names' do
        all_cache_key = service.send(:generate_stickers_cache_key, nil)
        old_pack_cache_key = service.send(:generate_stickers_cache_key, 'Test Pack')
        new_pack_cache_key = service.send(:generate_stickers_cache_key, 'New Pack')
        packs_cache_key = service.send(:generate_packs_cache_key)

        # Pre-populate new pack cache
        service.custom_stickers('New Pack')

        # Verify caches exist
        expect(Rails.cache.exist?(all_cache_key)).to be true
        expect(Rails.cache.exist?(old_pack_cache_key)).to be true
        expect(Rails.cache.exist?(new_pack_cache_key)).to be true
        expect(Rails.cache.exist?(packs_cache_key)).to be true

        service.update_sticker_pack(custom_sticker.id, 'New Pack')

        # Verify all relevant caches are invalidated
        expect(Rails.cache.exist?(all_cache_key)).to be false
        expect(Rails.cache.exist?(old_pack_cache_key)).to be false
        expect(Rails.cache.exist?(new_pack_cache_key)).to be false
        expect(Rails.cache.exist?(packs_cache_key)).to be false
      end
    end

    describe '#invalidate_all_caches' do
      it 'removes all sticker-related caches for the account' do
        expect(Rails.cache).to receive(:delete_matched)
          .with("#{described_class::CACHE_PREFIX}:#{account.id}:*")

        service.invalidate_all_caches
      end
    end
  end
end