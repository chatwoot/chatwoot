module Enterprise::CloudflareCleanupJob
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def perform
    return unless ChatwootApp.chatwoot_cloud?

    Rails.logger.info 'Starting Cloudflare custom hostname cleanup'

    result = Cloudflare::ListCustomHostnamesService.new.perform

    if result[:errors].present?
      Rails.logger.error "Failed to fetch custom hostnames from Cloudflare: #{result[:errors]}"
      return
    end

    cloudflare_hostnames = result[:data] || []
    existing_domains = Portal.where.not(custom_domain: [nil, '']).pluck(:custom_domain)

    orphaned_hostnames = cloudflare_hostnames.reject do |hostname|
      existing_domains.include?(hostname['hostname'])
    end

    Rails.logger.info "Found #{orphaned_hostnames.size} orphaned custom hostnames to cleanup"

    orphaned_hostnames.each do |hostname|
      cleanup_result = Cloudflare::DeleteCustomHostnameService.new(
        hostname_id: hostname['id']
      ).perform

      if cleanup_result[:errors].present?
        Rails.logger.error "Failed to delete hostname #{hostname['hostname']}: #{cleanup_result[:errors]}"
      else
        Rails.logger.info "Successfully deleted orphaned hostname: #{hostname['hostname']}"
      end
    end

    Rails.logger.info 'Completed Cloudflare custom hostname cleanup'
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
end
