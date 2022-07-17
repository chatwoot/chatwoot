# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContactInbox do
  describe 'pubsub_token' do
    let(:contact_inbox) { create(:contact_inbox) }

    it 'gets created on object create' do
      obj = contact_inbox
      expect(obj.pubsub_token).not_to be_nil
    end

    it 'does not get updated on object update' do
      obj = contact_inbox
      old_token = obj.pubsub_token
      obj.update(source_id: '234234323')
      expect(obj.pubsub_token).to eq(old_token)
    end

    it 'backfills pubsub_token on call for older objects' do
      obj = create(:contact_inbox)
      # to replicate an object with out pubsub_token
      # rubocop:disable Rails/SkipsModelValidations
      obj.update_column(:pubsub_token, nil)
      # rubocop:enable Rails/SkipsModelValidations

      obj.reload

      # ensure the column is nil in database
      results = ActiveRecord::Base.connection.execute('Select * from contact_inboxes;')
      expect(results.first['pubsub_token']).to be_nil

      new_token = obj.pubsub_token
      obj.update(source_id: '234234323')
      # the generated token shoul be persisted in db
      expect(obj.pubsub_token).to eq(new_token)
    end
  end
end
