class InfluencerSearch < ApplicationRecord
  belongs_to :account

  validates :query_params, presence: true
  validates :query_signature, presence: true
  validates :page_size, numericality: { greater_than: 0 }

  def page_results(page)
    Array(results).slice(page_offset(page), page_size) || []
  end

  def page_cached?(page)
    return true if results_count.to_i.zero? && pages_fetched.to_i.positive? && page.to_i == 1

    start_index = page_offset(page)
    cached_results = page_results(page)

    return true if cached_results.size == page_size
    return false if start_index >= results_count.to_i

    last_page = (start_index + page_size) >= results_count.to_i
    last_page && cached_results.present?
  end

  def append_page_results(page_results)
    self.results = Array(results) + Array(page_results)
  end

  def loaded_count
    Array(results).size
  end

  private

  def page_offset(page)
    ([page.to_i, 1].max - 1) * page_size
  end
end
