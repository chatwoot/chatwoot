class AddUniqueIndexesToShopifyHooks < ActiveRecord::Migration[7.1]
  ACCOUNT_INDEX = 'index_shopify_hooks_on_account_id'.freeze
  DOMAIN_INDEX = 'index_shopify_hooks_on_lower_reference_id'.freeze

  def up
    execute 'LOCK TABLE integrations_hooks IN SHARE MODE'
    remove_shopify_indexes
    remove_duplicate_shopify_hooks!
    add_unique_shopify_indexes
  end

  def down
    remove_shopify_indexes
  end

  private

  def remove_shopify_indexes
    remove_index :integrations_hooks, name: DOMAIN_INDEX, if_exists: true
    remove_index :integrations_hooks, name: ACCOUNT_INDEX, if_exists: true
  end

  def add_unique_shopify_indexes
    add_index :integrations_hooks,
              :account_id,
              unique: true,
              where: "app_id = 'shopify'",
              name: ACCOUNT_INDEX
    add_index :integrations_hooks,
              'LOWER(reference_id)',
              unique: true,
              where: "app_id = 'shopify'",
              name: DOMAIN_INDEX
  end

  def remove_duplicate_shopify_hooks!
    hooks = select_all(<<~SQL.squish).to_a
      SELECT id,
             account_id,
             reference_id,
             LOWER(reference_id) AS normalized_reference_id,
             EXTRACT(EPOCH FROM updated_at) AS updated_at_epoch
      FROM integrations_hooks
      WHERE app_id = 'shopify'
      ORDER BY updated_at DESC, id DESC
    SQL
    retained_ids = retained_hook_ids(hooks)
    duplicate_hooks = hooks.reject { |hook| retained_ids.include?(hook['id'].to_i) }
    return if duplicate_hooks.empty?

    say "Removing #{duplicate_hooks.count} duplicate Shopify hooks while preserving the largest valid account/store set"
    duplicate_hooks.each do |hook|
      say "Removing hook #{hook['id']} from account #{hook['account_id']} for #{hook['reference_id']}"
    end
    execute "DELETE FROM integrations_hooks WHERE id IN (#{duplicate_hooks.pluck('id').map(&:to_i).join(',')})"
  end

  def retained_hook_ids(hooks)
    adjacency = distinct_edges(hooks).group_by { |hook| account_key(hook) }
    adjacency.each_value { |account_hooks| account_hooks.sort_by! { |hook| hook_priority(hook) }.reverse! }

    domain_matches = {}
    accounts_by_priority(adjacency).each do |account_id|
      assign_account(account_id, adjacency, domain_matches, {})
    end
    domain_matches.values.map { |hook| hook['id'].to_i }
  end

  def distinct_edges(hooks)
    hooks
      .group_by { |hook| [account_key(hook), domain_key(hook)] }
      .values
      .map { |duplicates| duplicates.max_by { |hook| hook_priority(hook) } }
  end

  def accounts_by_priority(adjacency)
    adjacency.keys.sort_by { |account_id| hook_priority(adjacency.fetch(account_id).first) }.reverse
  end

  def assign_account(account_id, adjacency, domain_matches, visited_domains)
    adjacency.fetch(account_id, []).each do |hook|
      domain = domain_key(hook)
      next if visited_domains[domain]

      visited_domains[domain] = true
      previous_hook = domain_matches[domain]
      next unless previous_hook.nil? || assign_account(account_key(previous_hook), adjacency, domain_matches, visited_domains)

      domain_matches[domain] = hook
      return true
    end
    false
  end

  def hook_priority(hook)
    [hook['updated_at_epoch'].to_f, hook['id'].to_i]
  end

  def account_key(hook)
    hook['account_id'] || "hook-#{hook['id']}"
  end

  def domain_key(hook)
    hook['normalized_reference_id'] || "hook-#{hook['id']}"
  end
end
