class Onboarding::HelpCenterArticleGenerationJob < ApplicationJob
  queue_as :low

  retry_on Firecrawl::FirecrawlError, wait: :polynomially_longer, attempts: 3 do |job, error|
    generation = job.arguments.first
    Rails.logger.warn "[HelpCenterGenerationJob] gen=#{generation.id} firecrawl exhausted: #{error.message}"
    generation.update!(status: :skipped, skip_reason: "firecrawl exhausted: #{error.message}", finished_at: Time.current)
    Onboarding::HelpCenterBroadcaster.completed(generation)
  end

  def perform(generation)
    generation.reload
    return if generation.terminal? || generation.generating?

    process(generation)
  rescue CustomExceptions::HelpCenter::CurationSkipped => e
    Rails.logger.info "[HelpCenterGenerationJob] gen=#{generation.id} skipped: #{e.message}"
    generation.update!(status: :skipped, skip_reason: e.message, finished_at: Time.current)
    Onboarding::HelpCenterBroadcaster.completed(generation)
  end

  private

  def process(generation)
    generation.update!(status: :curating, started_at: Time.current) if generation.pending?

    plan = Onboarding::HelpCenterCurator.new(account: generation.account, portal: generation.portal).perform
    categories_by_name = create_categories(generation.portal, plan['categories'])
    enriched = plan.merge('articles' => stamp_category_ids(plan['articles'], categories_by_name))

    if enriched['articles'].empty?
      raise CustomExceptions::HelpCenter::CurationSkipped,
            'no articles after category stamping (LLM article category_name did not match any curated category)'
    end

    generation.update!(plan: enriched, status: :generating)
    fan_out(generation)
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

  def fan_out(generation)
    generation.plan['articles'].each_with_index do |_spec, index|
      Onboarding::HelpCenterArticleWriterJob.perform_later(generation, index)
    end
  end
end
