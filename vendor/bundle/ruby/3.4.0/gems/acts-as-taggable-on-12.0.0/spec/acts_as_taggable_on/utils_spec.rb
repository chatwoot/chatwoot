# -*- encoding : utf-8 -*-
require 'spec_helper'

describe ActsAsTaggableOn::Utils do
  describe '#like_operator' do
    it 'should return \'ILIKE\' when the adapter is PostgreSQL' do
      allow(ActsAsTaggableOn::Utils.connection).to receive(:adapter_name) { 'PostgreSQL' }
      expect(ActsAsTaggableOn::Utils.like_operator).to eq('ILIKE')
    end

    it 'should return \'LIKE\' when the adapter is not PostgreSQL' do
      allow(ActsAsTaggableOn::Utils.connection).to receive(:adapter_name) { 'MySQL' }
      expect(ActsAsTaggableOn::Utils.like_operator).to eq('LIKE')
    end
  end

  describe '#sha_prefix' do
    it 'should return a consistent prefix for a given word' do
      expect(ActsAsTaggableOn::Utils.sha_prefix('kittens')).to eq(ActsAsTaggableOn::Utils.sha_prefix('kittens'))
      expect(ActsAsTaggableOn::Utils.sha_prefix('puppies')).not_to eq(ActsAsTaggableOn::Utils.sha_prefix('kittens'))
    end
  end
end
