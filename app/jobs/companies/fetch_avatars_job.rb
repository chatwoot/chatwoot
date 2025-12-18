class Companies::FetchAvatarsJob < ApplicationJob
  queue_as :low

  def perform(account_id, force_refresh: false)
    account = Account.find(account_id)
    companies = account.companies.where.not(domain: [nil, ''])

    unless force_refresh
      companies = companies.left_joins(:avatar_attachment)
                           .where(active_storage_attachments: { id: nil })
    end

    companies.find_each do |company|
      company.avatar.purge if force_refresh && company.avatar.attached?
      Avatar::AvatarFromFaviconJob.perform_later(company)
    end

    Rails.logger.info "Queued #{companies.count} companies from account #{account_id} for favicon fetch"
  end
end
