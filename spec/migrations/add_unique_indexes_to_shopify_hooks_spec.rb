require 'rails_helper'
require Rails.root.join('db/migrate/20260729090000_add_unique_indexes_to_shopify_hooks').to_s

RSpec.describe AddUniqueIndexesToShopifyHooks do
  def hook(id:, account_id:, domain:, priority:)
    {
      'id' => id,
      'account_id' => account_id,
      'reference_id' => domain,
      'normalized_reference_id' => domain.downcase,
      'updated_at_epoch' => priority
    }
  end

  it 'resolves overlapping account and store duplicates in one pass' do
    hooks = [
      hook(id: 1, account_id: 1, domain: 'x.myshopify.com', priority: 2),
      hook(id: 2, account_id: 2, domain: 'x.myshopify.com', priority: 1),
      hook(id: 3, account_id: 1, domain: 'y.myshopify.com', priority: 3)
    ]

    expect(described_class.new.send(:retained_hook_ids, hooks)).to contain_exactly(2, 3)
  end

  it 'uses an augmenting path to preserve the largest valid hook set' do
    hooks = [
      hook(id: 1, account_id: 1, domain: 'x.myshopify.com', priority: 4),
      hook(id: 2, account_id: 1, domain: 'y.myshopify.com', priority: 3),
      hook(id: 3, account_id: 2, domain: 'x.myshopify.com', priority: 2)
    ]

    expect(described_class.new.send(:retained_hook_ids, hooks)).to contain_exactly(2, 3)
  end

  it 'retains the newest hook when an account and store pair is duplicated' do
    hooks = [
      hook(id: 1, account_id: 1, domain: 'x.myshopify.com', priority: 1),
      hook(id: 2, account_id: 1, domain: 'X.myshopify.com', priority: 2)
    ]

    expect(described_class.new.send(:retained_hook_ids, hooks)).to contain_exactly(2)
  end
end
