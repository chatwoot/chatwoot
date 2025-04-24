class TestData::LabelGenerator
  TOTAL_LABELS = 50

  def initialize(account)
    @account = account
    @labels = []
  end

  # rubocop:disable Rails/SkipsModelValidations
  def generate!
    Rails.logger.info { "Creating #{TOTAL_LABELS} labels for account ##{@account.id}" }
    start_time = Time.current

    # Build labels data with guaranteed unique titles
    labels_data = Array.new(TOTAL_LABELS) do |i|
      {
        account_id: @account.id,
        title: "Label-#{i + 1}-#{SecureRandom.hex(4)}",
        description: Faker::Company.catch_phrase,
        color: Faker::Color.hex_color,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    # Use bulk insert for better performance
    Label.insert_all!(labels_data) if labels_data.any?

    # Fetch the created labels
    @labels = Label.where(account_id: @account.id)
                   .where(title: labels_data.pluck(:title))
                   .order(:created_at)

    Rails.logger.info { "Created #{@labels.size} labels in #{Time.current - start_time}s" }
    @labels
  end
  # rubocop:enable Rails/SkipsModelValidations
end
