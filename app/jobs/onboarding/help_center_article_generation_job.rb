class Onboarding::HelpCenterArticleGenerationJob < ApplicationJob
  queue_as :low

  retry_on Firecrawl::FirecrawlError, wait: :polynomially_longer, attempts: 3 do |job, error|
    account_id, _portal_id, user_id, generation_id = job.arguments
    account = Account.find(account_id)
    user = User.find_by(id: user_id)
    reason = "firecrawl exhausted: #{error.message}"

    Rails.logger.warn "[HelpCenterGenerationJob] gen=#{generation_id} #{reason}"
    Onboarding::HelpCenterGenerationStatus.mark_skipped!(account, generation_id, reason: reason)
    Onboarding::HelpCenterBroadcaster.completed(user: user, generation_id: generation_id, status: 'skipped', skip_reason: reason)
  end

  def perform(account_id, portal_id, user_id, generation_id)
    account = Account.find(account_id)
    return if already_generating_or_terminal?(account, generation_id)

    process(account: account, portal: Portal.find(portal_id), user: User.find(user_id), generation_id: generation_id)
  rescue CustomExceptions::HelpCenter::CurationSkipped => e
    Rails.logger.info "[HelpCenterGenerationJob] gen=#{generation_id} skipped: #{e.message}"
    Onboarding::HelpCenterGenerationStatus.mark_skipped!(account, generation_id, reason: e.message)
    Onboarding::HelpCenterBroadcaster.completed(
      user: User.find_by(id: user_id), generation_id: generation_id, status: 'skipped', skip_reason: e.message
    )
  end

  private

  def process(account:, portal:, user:, generation_id:)
    Onboarding::HelpCenterGenerationStatus.mark_curating!(account, generation_id)

    plan = Onboarding::HelpCenterCurator.new(account: account, portal: portal).perform

    articles = ActiveRecord::Base.transaction do
      categories_by_name = create_categories(portal, plan['categories'])
      stamped_articles = stamp_category_ids(plan['articles'], categories_by_name)

      if stamped_articles.empty?
        raise CustomExceptions::HelpCenter::CurationSkipped,
              'no articles after category stamping (LLM article category_name did not match any curated category)'
      end

      stamped_articles
    end

    Onboarding::HelpCenterGenerationCounter.create!(generation_id, total: articles.size)
    Onboarding::HelpCenterGenerationStatus.mark_generating!(account, generation_id)
    fan_out(
      { account: account, portal: portal, user: user, generation_id: generation_id },
      articles: articles,
      allowed_urls: plan['allowed_urls']
    )
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

  def stamp_category_ids(articles, categories_by_name)
    Array(articles).filter_map do |article|
      category_id = categories_by_name[article['category_name'].to_s]&.id
      next if category_id.nil?

      article.merge('category_id' => category_id)
    end
  end

  def fan_out(context, articles:, allowed_urls:)
    articles.each do |article|
      Onboarding::HelpCenterArticleWriterJob.perform_later(
        context[:account].id,
        context[:portal].id,
        context[:user].id,
        context[:generation_id],
        { article: article, allowed_urls: allowed_urls }
      )
    end
  end

  def already_generating_or_terminal?(account, generation_id)
    state = Onboarding::HelpCenterGenerationStatus.current(account)
    return false if state.blank? || state['id'] != generation_id

    %w[generating completed skipped].include?(state['status'])
  end
end
