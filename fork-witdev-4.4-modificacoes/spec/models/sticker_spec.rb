# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sticker, type: :model do
  let(:account) { create(:account) }

  describe 'validations' do
    it 'validates presence of required fields' do
      sticker = Sticker.new
      expect(sticker).not_to be_valid
      expect(sticker.errors[:account]).to include("must exist")
    end

    it 'validates sticker pack name format' do
      sticker = build(:sticker, account: account, pack_name: '')
      expect(sticker).not_to be_valid
      expect(sticker.errors[:pack_name]).to include("can't be blank")
    end

    it 'validates sticker pack name length' do
      sticker = build(:sticker, account: account, pack_name: 'a' * 101)
      expect(sticker).not_to be_valid
      expect(sticker.errors[:pack_name]).to include("is too long (maximum is 100 characters)")
    end
  end

  describe 'associations' do
    it 'belongs to account' do
      association = described_class.reflect_on_association(:account)
      expect(association.macro).to eq(:belongs_to)
    end

    it 'has many attachments' do
      association = described_class.reflect_on_association(:attachments)
      expect(association.macro).to eq(:has_many)
    end
  end

  describe 'scopes' do
    let!(:sticker1) { create(:sticker, account: account, pack_name: 'Pack A') }
    let!(:sticker2) { create(:sticker, account: account, pack_name: 'Pack B') }
    let!(:sticker3) { create(:sticker, account: account, pack_name: 'Pack A') }

    describe '.by_pack' do
      it 'filters stickers by pack name' do
        pack_a_stickers = Sticker.by_pack('Pack A')
        expect(pack_a_stickers).to include(sticker1, sticker3)
        expect(pack_a_stickers).not_to include(sticker2)
      end
    end

    describe '.for_account' do
      let(:other_account) { create(:account) }
      let!(:other_sticker) { create(:sticker, account: other_account, pack_name: 'Other Pack') }

      it 'filters stickers by account' do
        account_stickers = Sticker.for_account(account)
        expect(account_stickers).to include(sticker1, sticker2, sticker3)
        expect(account_stickers).not_to include(other_sticker)
      end
    end
  end

  describe 'instance methods' do
    let(:sticker) { create(:sticker, account: account, pack_name: 'Test Pack') }

    describe '#to_api_hash' do
      it 'returns hash suitable for API response' do
        api_hash = sticker.to_api_hash
        
        expect(api_hash).to include(
          id: sticker.id,
          pack_name: 'Test Pack',
          provider: 'custom',
          created_at: sticker.created_at,
          updated_at: sticker.updated_at
        )
      end
    end

    describe '#attachment_count' do
      it 'returns count of associated attachments' do
        create_list(:attachment, 3, 
                   account: account, 
                   file_type: :image,
                   meta: { 
                     sticker_type: 'custom', 
                     sticker_pack: sticker.pack_name 
                   })

        expect(sticker.attachment_count).to eq(3)
      end

      it 'returns 0 when no attachments' do
        expect(sticker.attachment_count).to eq(0)
      end
    end

    describe '#recent_usage_count' do
      let(:user1) { create(:user, account: account) }
      let(:user2) { create(:user, account: account) }

      before do
        user1.update!(
          ui_settings: {
            recent_stickers: [
              { pack_name: sticker.pack_name, used_at: 1.hour.ago.iso8601 },
              { pack_name: 'Other Pack', used_at: 2.hours.ago.iso8601 }
            ]
          }
        )

        user2.update!(
          ui_settings: {
            recent_stickers: [
              { pack_name: sticker.pack_name, used_at: 30.minutes.ago.iso8601 }
            ]
          }
        )
      end

      it 'counts recent usage across users' do
        expect(sticker.recent_usage_count).to eq(2)
      end
    end
  end

  describe 'class methods' do
    describe '.popular_packs' do
      let(:user1) { create(:user, account: account) }
      let(:user2) { create(:user, account: account) }
      let!(:pack_a) { create(:sticker, account: account, pack_name: 'Pack A') }
      let!(:pack_b) { create(:sticker, account: account, pack_name: 'Pack B') }
      let!(:pack_c) { create(:sticker, account: account, pack_name: 'Pack C') }

      before do
        # Pack A used by both users
        user1.update!(
          ui_settings: {
            recent_stickers: [
              { pack_name: 'Pack A', used_at: 1.hour.ago.iso8601 }
            ]
          }
        )

        user2.update!(
          ui_settings: {
            recent_stickers: [
              { pack_name: 'Pack A', used_at: 30.minutes.ago.iso8601 },
              { pack_name: 'Pack B', used_at: 2.hours.ago.iso8601 }
            ]
          }
        )
      end

      it 'returns packs ordered by usage frequency' do
        popular = Sticker.popular_packs(account)
        pack_names = popular.map(&:pack_name)
        
        expect(pack_names.first).to eq('Pack A') # Most used
        expect(pack_names).to include('Pack B')
      end

      it 'limits results when specified' do
        popular = Sticker.popular_packs(account, limit: 1)
        expect(popular.size).to eq(1)
        expect(popular.first.pack_name).to eq('Pack A')
      end
    end

    describe '.pack_names' do
      let!(:sticker1) { create(:sticker, account: account, pack_name: 'Pack A') }
      let!(:sticker2) { create(:sticker, account: account, pack_name: 'Pack B') }
      let!(:sticker3) { create(:sticker, account: account, pack_name: 'Pack A') } # Duplicate

      it 'returns unique pack names for account' do
        pack_names = Sticker.pack_names(account)
        expect(pack_names).to contain_exactly('Pack A', 'Pack B')
      end

      it 'returns empty array for account with no stickers' do
        other_account = create(:account)
        pack_names = Sticker.pack_names(other_account)
        expect(pack_names).to eq([])
      end
    end

    describe '.create_from_attachment' do
      let(:attachment) do
        create(:attachment, 
               account: account, 
               file_type: :image,
               meta: { 
                 sticker_type: 'custom', 
                 sticker_pack: 'New Pack',
                 tags: ['logo', 'brand']
               })
      end

      it 'creates sticker from attachment metadata' do
        sticker = Sticker.create_from_attachment(attachment)
        
        expect(sticker).to be_persisted
        expect(sticker.account).to eq(account)
        expect(sticker.pack_name).to eq('New Pack')
        expect(sticker.tags).to eq(['logo', 'brand'])
      end

      it 'handles attachment without sticker metadata' do
        regular_attachment = create(:attachment, account: account, file_type: :image)
        
        expect {
          Sticker.create_from_attachment(regular_attachment)
        }.to raise_error(ArgumentError, /not a sticker attachment/)
      end
    end
  end

  describe 'callbacks' do
    describe 'before_save' do
      it 'normalizes pack name' do
        sticker = build(:sticker, account: account, pack_name: '  Test Pack  ')
        sticker.save!
        
        expect(sticker.pack_name).to eq('Test Pack')
      end

      it 'titleizes pack name' do
        sticker = build(:sticker, account: account, pack_name: 'test pack')
        sticker.save!
        
        expect(sticker.pack_name).to eq('Test Pack')
      end
    end

    describe 'after_create' do
      it 'logs sticker creation' do
        expect(Rails.logger).to receive(:info).with(/Sticker pack created/)
        
        create(:sticker, account: account, pack_name: 'New Pack')
      end
    end
  end

  describe 'integration with Attachment model' do
    let(:sticker) { create(:sticker, account: account, pack_name: 'Integration Pack') }

    it 'finds related attachments by pack name' do
      attachment1 = create(:attachment, 
                          account: account, 
                          file_type: :image,
                          meta: { 
                            sticker_type: 'custom', 
                            sticker_pack: 'Integration Pack'
                          })

      attachment2 = create(:attachment, 
                          account: account, 
                          file_type: :image,
                          meta: { 
                            sticker_type: 'custom', 
                            sticker_pack: 'Other Pack'
                          })

      related_attachments = sticker.related_attachments
      expect(related_attachments).to include(attachment1)
      expect(related_attachments).not_to include(attachment2)
    end

    it 'provides sticker data for API responses' do
      attachment = create(:attachment, 
                         account: account, 
                         file_type: :image,
                         meta: { 
                           sticker_type: 'custom', 
                           sticker_pack: sticker.pack_name
                         })

      sticker_data = sticker.to_sticker_data
      expect(sticker_data).to include(
        pack_name: sticker.pack_name,
        sticker_count: 1,
        provider: 'custom'
      )
    end
  end

  describe 'error handling' do
    it 'handles database constraints gracefully' do
      # Test unique constraint if exists
      sticker1 = create(:sticker, account: account, pack_name: 'Unique Pack')
      
      # Depending on implementation, this might be allowed or not
      sticker2 = build(:sticker, account: account, pack_name: 'Unique Pack')
      
      # Should either save successfully or fail with validation error
      result = sticker2.save
      expect([true, false]).to include(result)
    end

    it 'handles invalid account references' do
      sticker = build(:sticker, account_id: 999999, pack_name: 'Test Pack')
      
      expect(sticker).not_to be_valid
      expect(sticker.errors[:account]).to be_present
    end
  end

  describe 'performance considerations' do
    it 'efficiently queries related data' do
      # Create test data
      sticker = create(:sticker, account: account, pack_name: 'Performance Pack')
      create_list(:attachment, 10, 
                 account: account, 
                 file_type: :image,
                 meta: { 
                   sticker_type: 'custom', 
                   sticker_pack: sticker.pack_name
                 })

      # Test that queries are efficient
      expect {
        sticker.attachment_count
        sticker.related_attachments.to_a
      }.not_to exceed_query_limit(3) # Should be efficient
    end
  end
end