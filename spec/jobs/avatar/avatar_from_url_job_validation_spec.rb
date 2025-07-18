require 'rails_helper'

RSpec.describe Avatar::AvatarFromUrlJob, '#validation_and_rate_limiting' do
  let(:avatarable) { create(:contact) }
  let(:user_avatarable) { create(:user) }
  let(:valid_avatar_url) { 'https://example.com/avatar.png' }
  let(:invalid_avatar_url) { 'not-a-url' }
  let(:http_url) { 'http://example.com/avatar.png' }

  describe '#valid_url?' do
    it 'returns true for valid HTTPS URLs' do
      job = described_class.new
      expect(job.send(:valid_url?, valid_avatar_url)).to be true
    end

    it 'returns true for valid HTTP URLs' do
      job = described_class.new
      expect(job.send(:valid_url?, http_url)).to be true
    end

    it 'returns false for invalid URLs' do
      job = described_class.new
      expect(job.send(:valid_url?, invalid_avatar_url)).to be false
    end

    it 'returns false for blank URLs' do
      job = described_class.new
      expect(job.send(:valid_url?, '')).to be false
      expect(job.send(:valid_url?, nil)).to be false
    end
  end

  describe '#should_sync_avatar?' do
    let(:job) { described_class.new }

    it 'returns true when no previous sync exists' do
      expect(job.send(:should_sync_avatar?, avatarable, valid_avatar_url)).to be true
    end

    it 'returns false when synced within 30 minutes' do
      avatarable.update(additional_attributes: { 'last_avatar_sync_at' => 15.minutes.ago.iso8601 })
      expect(job.send(:should_sync_avatar?, avatarable, valid_avatar_url)).to be false
    end

    it 'returns true when synced more than 30 minutes ago' do
      avatarable.update(additional_attributes: { 'last_avatar_sync_at' => 31.minutes.ago.iso8601 })
      expect(job.send(:should_sync_avatar?, avatarable, valid_avatar_url)).to be true
    end

    it 'returns false when URL hash is the same' do
      url_hash = Digest::SHA256.hexdigest(valid_avatar_url)
      avatarable.update(additional_attributes: { 'avatar_url_hash' => url_hash })
      expect(job.send(:should_sync_avatar?, avatarable, valid_avatar_url)).to be false
    end

    it 'returns true when URL hash is different' do
      different_url_hash = Digest::SHA256.hexdigest('https://different.com/avatar.png')
      avatarable.update(additional_attributes: { 'avatar_url_hash' => different_url_hash })
      expect(job.send(:should_sync_avatar?, avatarable, valid_avatar_url)).to be true
    end
  end

  describe '#generate_url_hash' do
    it 'generates consistent hash for same URL' do
      job = described_class.new
      hash1 = job.send(:generate_url_hash, valid_avatar_url)
      hash2 = job.send(:generate_url_hash, valid_avatar_url)
      expect(hash1).to eq(hash2)
    end

    it 'generates different hash for different URLs' do
      job = described_class.new
      hash1 = job.send(:generate_url_hash, valid_avatar_url)
      hash2 = job.send(:generate_url_hash, 'https://different.com/avatar.png')
      expect(hash1).not_to eq(hash2)
    end
  end

  describe '#update_avatar_sync_attributes' do
    it 'updates last_avatar_sync_at and avatar_url_hash' do
      job = described_class.new

      job.send(:update_avatar_sync_attributes, avatarable, valid_avatar_url)
      avatarable.reload

      expect(avatarable.additional_attributes['last_avatar_sync_at']).to be_present
      expect(avatarable.additional_attributes['avatar_url_hash']).to eq(Digest::SHA256.hexdigest(valid_avatar_url))
    end

    it 'preserves existing additional_attributes' do
      avatarable.update(additional_attributes: { 'existing_key' => 'existing_value' })
      job = described_class.new

      job.send(:update_avatar_sync_attributes, avatarable, valid_avatar_url)
      avatarable.reload

      expect(avatarable.additional_attributes['existing_key']).to eq('existing_value')
      expect(avatarable.additional_attributes['last_avatar_sync_at']).to be_present
      expect(avatarable.additional_attributes['avatar_url_hash']).to be_present
    end
  end

  describe '#perform' do
    it 'skips invalid URLs' do
      expect(Down).not_to receive(:download)
      described_class.perform_now(avatarable, invalid_avatar_url)
      expect(avatarable.avatar).not_to be_attached
    end

    it 'skips when rate limited' do
      avatarable.update(additional_attributes: { 'last_avatar_sync_at' => 15.minutes.ago.iso8601 })
      expect(Down).not_to receive(:download)
      described_class.perform_now(avatarable, valid_avatar_url)
      expect(avatarable.avatar).not_to be_attached
    end

    it 'skips when URL hash is the same' do
      url_hash = Digest::SHA256.hexdigest(valid_avatar_url)
      avatarable.update(additional_attributes: { 'avatar_url_hash' => url_hash })
      expect(Down).not_to receive(:download)
      described_class.perform_now(avatarable, valid_avatar_url)
      expect(avatarable.avatar).not_to be_attached
    end

    it 'processes when conditions are met and updates sync attributes' do
      expect(Down).to receive(:download).with(valid_avatar_url, max_size: 15 * 1024 * 1024)
                                        .and_return(fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png'))

      described_class.perform_now(avatarable, valid_avatar_url)
      avatarable.reload

      expect(avatarable.avatar).to be_attached
      expect(avatarable.additional_attributes['last_avatar_sync_at']).to be_present
      expect(avatarable.additional_attributes['avatar_url_hash']).to eq(Digest::SHA256.hexdigest(valid_avatar_url))
    end
  end

  describe 'non-contact avatarable objects' do
    describe '#should_sync_avatar?' do
      let(:job) { described_class.new }

      it 'returns true for User (no rate limiting)' do
        expect(job.send(:should_sync_avatar?, user_avatarable, valid_avatar_url)).to be true
      end

      it 'always returns true for User regardless of repeated calls' do
        job.send(:should_sync_avatar?, user_avatarable, valid_avatar_url)
        expect(job.send(:should_sync_avatar?, user_avatarable, valid_avatar_url)).to be true
      end
    end

    describe '#update_avatar_sync_attributes' do
      it 'does not update attributes for User' do
        job = described_class.new
        expect { job.send(:update_avatar_sync_attributes, user_avatarable, valid_avatar_url) }.not_to raise_error
        user_avatarable.reload
        expect(user_avatarable).not_to respond_to(:additional_attributes)
      end
    end

    describe '#perform' do
      it 'processes valid URLs for User without rate limiting' do
        expect(Down).to receive(:download).with(valid_avatar_url, max_size: 15 * 1024 * 1024)
                                          .and_return(fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png'))

        described_class.perform_now(user_avatarable, valid_avatar_url)
        expect(user_avatarable.avatar).to be_attached
      end

      it 'skips invalid URLs for User' do
        expect(Down).not_to receive(:download)
        described_class.perform_now(user_avatarable, invalid_avatar_url)
        expect(user_avatarable.avatar).not_to be_attached
      end

      it 'processes same URL multiple times for User (no hash comparison)' do
        # First call
        expect(Down).to receive(:download).with(valid_avatar_url, max_size: 15 * 1024 * 1024)
                                          .and_return(fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png'))

        described_class.perform_now(user_avatarable, valid_avatar_url)
        expect(user_avatarable.avatar).to be_attached

        # Clear the attached avatar to allow second attachment
        user_avatarable.avatar.purge

        # Second call - should process again since there's no rate limiting or hash comparison for User
        expect(Down).to receive(:download).with(valid_avatar_url, max_size: 15 * 1024 * 1024)
                                          .and_return(fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png'))

        described_class.perform_now(user_avatarable, valid_avatar_url)
        expect(user_avatarable.avatar).to be_attached
      end
    end
  end
end
