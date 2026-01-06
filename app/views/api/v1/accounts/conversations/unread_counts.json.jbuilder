json.by_inbox @unread_counts[:by_inbox]
json.by_label @unread_counts[:by_label]
json.by_status do
  json.all @unread_counts[:by_status][:all]
  json.mine @unread_counts[:by_status][:mine]
  json.unassigned @unread_counts[:by_status][:unassigned]
end
json.total @unread_counts[:total]
