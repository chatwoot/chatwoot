# ACCOUNT_ID=2 CONFIG_PATH=/private/store-routing.json APPLY=true bundle exec rails runner script/configure_store_routing.rb
# Input: {"inbox_ids":[20],"ledger_inbox_ids":[20],"stores":{"psd":{"team_name":"pq. são domingos","member_ids":[18,10,40]},...}}
account = Account.find(ENV.fetch('ACCOUNT_ID'))
input = JSON.parse(File.read(ENV.fetch('CONFIG_PATH')))
raise 'Expected PSD, LAP and TAT stores' unless input.fetch('stores').keys.sort == %w[lap psd tat]

inboxes = input.fetch('inbox_ids').map { |id| account.inboxes.find(id) }
raise 'At least one inbox is required' if inboxes.empty?

role_ids = inboxes.map { |inbox| inbox.assignment_policy&.eligible_custom_role_id }.uniq
unless role_ids.one? && role_ids.first && inboxes.all?(&:auto_assignment_v2_enabled?)
  raise 'All inboxes must use the same seller role and Assignment V2'
end

members = input.fetch('stores').values.flat_map { |store| store.fetch('member_ids') }
raise 'Each seller must belong to exactly one store' unless members.uniq == members
unless (members - account.account_users.where(custom_role_id: role_ids.first).pluck(:user_id)).empty?
  raise 'Only sellers from this account may participate'
end

inboxes.each { |inbox| raise "Seller missing from inbox #{inbox.id}" unless (members - inbox.members.ids).empty? }
input.fetch('ledger_inbox_ids').each { |id| account.inboxes.find(id) }

preview = input.fetch('stores').transform_values do |store|
  team = account.teams.find_by(name: store.fetch('team_name').downcase)
  { team_id: team&.id, team_name: store.fetch('team_name'), current_members: team&.member_ids, seller_ids: store.fetch('member_ids') }
end
puts({ account_id: account.id, routing_inboxes: inboxes.map(&:id), teams: preview, apply: ENV['APPLY'] == 'true' }.to_json)
exit unless ENV['APPLY'] == 'true'

Account.transaction do
  account.lock!
  stores = input.fetch('stores').transform_values do |store|
    team = account.teams.find_or_initialize_by(name: store.fetch('team_name').downcase)
    team.update!(allow_auto_assign: true)
    # Keep managers' manual access; only replace the seller membership proposed in the preview.
    seller_ids = account.account_users.where(custom_role_id: role_ids.first).pluck(:user_id)
    team.remove_members((team.member_ids & seller_ids) - store.fetch('member_ids'))
    team.add_members(store.fetch('member_ids') - team.member_ids)
    { 'team_id' => team.id }
  end
  stores.each do |code, store|
    store['label'] = "loja-#{code}"
  end
  (stores.values.map { |store| store.fetch('label') } + %w[loja-indefinida origem-site origem-meta origem-google origem-direto]).each do |title|
    account.labels.find_or_create_by!(title: title)
  end
  account.custom_attribute_definitions.find_or_create_by!(attribute_key: 'campanha', attribute_model: 'conversation_attribute') do |attribute|
    attribute.attribute_display_name = 'Campaign'
    attribute.attribute_display_type = 'text'
  end
  account.internal_attributes['store_routing'] = { 'inbox_ids' => inboxes.map(&:id), 'stores' => stores }
  account.internal_attributes['assignment_ledger'] = { 'inbox_ids' => input.fetch('ledger_inbox_ids') }
  account.save!
end
puts({ configured: true, routing: account.internal_attributes.fetch('store_routing') }.to_json)
