json.payload do
  json.array! @inbox_members do |inbox_member|
    next if inbox_member.user.blank?

    json.id inbox_member.user.id
    json.name inbox_member.user.available_name
    json.avatar_url inbox_member.user.avatar_url
    # account_users is preloaded; find_by would query once per member
    account_user = inbox_member.user.account_users.find { |record| record.account_id == @current_account.id }
    json.availability_status account_user&.availability_status
  end
end
