class Onboarding::HelpCenterArticleGenerationJob < ApplicationJob
  queue_as :low

  retry_on Firecrawl::FirecrawlError, wait: :polynomially_longer, attempts: 3 do |job, error|
    _account_id, _portal_id, user_id, generation_id = job.arguments
    reason = "firecrawl exhausted: #{error.message}"
    Rails.logger.warn "[HelpCenterGenerationJob] gen=#{generation_id} #{reason}"
    job.send(:skip_and_broadcast, user: User.find_by(id: user_id), generation_id: generation_id, reason: reason)
  end

  def perform(account_id, portal_id, user_id, generation_id)
    return if Onboarding::HelpCenterGenerationState.current(generation_id).present?

    process(
      account: Account.find(account_id),
      portal: Portal.find(portal_id),
      user: User.find(user_id),
      generation_id: generation_id
    )
  rescue Onboarding::HelpCenterErrors::CurationSkipped => e
    Rails.logger.info "[HelpCenterGenerationJob] gen=#{generation_id} skipped: #{e.message}"
    skip_and_broadcast(user: User.find_by(id: user_id), generation_id: generation_id, reason: e.message)
  end

  private

  def process(account:, portal:, user:, generation_id:)
    plan = Onboarding::HelpCenterCurator.new(account: account).perform
    articles = create_categories_and_build_article_payloads(portal, plan)

    Onboarding::HelpCenterGenerationState.start(generation_id, total: articles.size)
    enqueue_writer_jobs(
      account_id: account.id,
      portal_id: portal.id,
      user_id: user.id,
      generation_id: generation_id,
      articles: articles
    )
  end

  def create_categories_and_build_article_payloads(portal, plan)
    ActiveRecord::Base.transaction do
      categories_by_name = create_categories(portal, plan['categories'])
      articles = build_article_payloads(
        plan['articles'],
        categories_by_name,
        plan['allowed_urls']
      )

      if articles.empty?
        raise Onboarding::HelpCenterErrors::CurationSkipped,
              'no articles after category or URL filtering'
      end

      articles
    end
  end

  def create_categories(portal, categories)
    locale = portal.default_locale
    Array(categories).each_with_index.with_object({}) do |(cat, idx), acc|
      name = cat['name'].to_s.strip
      next if name.blank?

      record = portal.categories.create!(
        name: name,
        description: cat['description'].to_s.strip.presence,
        slug: "#{name.parameterize}-#{SecureRandom.hex(3)}",
        locale: locale,
        position: (idx + 1) * 10
      )
      acc[name] = record
    end
  end

  def build_article_payloads(articles, categories_by_name, allowed_urls)
    allowed_urls = Array(allowed_urls).to_set
    Array(articles).filter_map do |article|
      category_id = categories_by_name[article['category_name'].to_s]&.id
      next if category_id.nil?

      urls = Array(article['urls']).select { |url| allowed_urls.include?(url) }
      next if urls.empty?

      article.merge('category_id' => category_id, 'urls' => urls)
    end
  end

  def enqueue_writer_jobs(account_id:, portal_id:, user_id:, generation_id:, articles:)
    articles.each do |article|
      Onboarding::HelpCenterArticleWriterJob.perform_later(
        account_id, portal_id, user_id, generation_id, { article: article }
      )
    end
  end

  def skip_and_broadcast(user:, generation_id:, reason:)
    Onboarding::HelpCenterGenerationState.skip(generation_id, reason: reason)
    Onboarding::HelpCenterBroadcaster.completed(
      user: user, generation_id: generation_id, status: 'skipped', skip_reason: reason
    )
  end
end
