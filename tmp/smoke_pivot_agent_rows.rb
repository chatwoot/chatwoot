# frozen_string_literal: true

# Smoke: pivot agent rows must not collapse vs flat agent summary,
# and identity columns must keep real names/ranks (B-NEW-19).
# Usage (Docker):
#   docker cp tmp/smoke_pivot_agent_rows.rb chatwoot-chatwoot-rails-1:/tmp/smoke_pivot_agent_rows.rb
#   docker exec chatwoot-chatwoot-rails-1 bundle exec rails runner /tmp/smoke_pivot_agent_rows.rb

panel = Account.first.saved_report_panels.find_by(name: 'Demo Agentes × Ventas')
raise 'Missing demo panel — run tmp/seed_report_panels_demo.rb first' unless panel

user = panel.account.administrators.first || panel.account.users.first
svc = Reports::PanelRunnerService.new(panel: panel, account: panel.account, user: user, timezone_offset: -5)
result = svc.perform
since_t = Time.zone.at(result[:since])
until_t = Time.zone.at(result[:until])

widget = panel.widgets.find { |w| (w['id'] || w[:id]).to_s == 'w_demo_agent_table' }.with_indifferent_access

flat_widget = widget.deep_dup
flat_widget[:pivot] = { 'column_attribute' => '', 'column_values' => [], 'show_row_totals' => true }
flat = svc.send(:build_table_widget, flat_widget, since_t, until_t)

pivot = svc.send(:build_table_widget, widget, since_t, until_t)

subset = widget.deep_dup
subset[:pivot] = {
  'column_attribute' => 'ca:producto',
  'column_values' => ['Plan Básico'],
  'show_row_totals' => true
}
subset_result = svc.send(:build_table_widget, subset, since_t, until_t)

flat_n = flat[:rows].size
pivot_n = pivot[:rows].size
subset_n = subset_result[:rows].size

puts "flat_agents=#{flat_n} pivot_agents=#{pivot_n} subset_pivot_agents=#{subset_n}"

ok = pivot_n >= flat_n && subset_n >= flat_n
raise "FAIL: pivot rows collapsed (flat=#{flat_n} pivot=#{pivot_n} subset=#{subset_n})" unless ok

# Spot-check zeros exist for agents without Plan Básico in subset columns
zero_ok = subset_result[:rows].any? do |row|
  row.any? { |k, v| k.to_s.include?('__pv__') && v == 0 }
end
raise 'FAIL: expected some zero pivot cells' unless zero_ok

# B-NEW-19: name/rank must not be clobbered to 0
identity_ok = pivot[:rows].all? do |row|
  r = row.with_indifferent_access
  name = r[:name].to_s
  rank = r[:rank].to_i
  name.present? && name != '0' && rank >= 1
end
raise 'FAIL: pivot name/rank clobbered to 0 (B-NEW-19)' unless identity_ok

unassigned = flat[:rows].find { |row| row.with_indifferent_access[:id] == Reports::PanelRunnerService::UNASSIGNED_AGENT_ID }
raise 'FAIL: missing Sin asignar / Unassigned row on flat agent summary' if unassigned.blank?

puts 'OK — pivot agent count >= flat; identity columns intact; unassigned row present'
