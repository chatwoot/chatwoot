class Companies::FetchAvatarsJob < ApplicationJob
  queue_as :low

  def perform(account_id, force_refresh: false)
    account = Account.find(account_id)
    companies = account.companies.where.not(domain: [nil, ''])

    unless force_refresh
      companies = companies.left_joins(:avatar_attachment)
                           .where(active_storage_attachments: { id: nil })
    end

    total_companies = companies.count
    companies.find_each do |company|
      Avatar::AvatarFromFaviconJob.perform_later(company, force_refresh: force_refresh)
    end

    Rails.logger.info "Queued #{total_companies} companies from account #{account_id} for favicon fetch"
  end
end
