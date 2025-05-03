class Digitaltolk::SaveQualityScoreService
  attr_accessor :message, :params

  def initialize(message, params)
    @message = message
    @params = params
  end

  def perform
    return unless message
    return if quality_score.blank?

    save_quality_scores
  rescue StandardError => e
    Rails.logger.error("Error saving quality scores: #{e.message}")
  end

  private

  def save_quality_scores
    message_quality_score.scores = score_data
    message_quality_score.save!
  end

  def message_quality_score
    @message_quality_score ||= MessageQualityScore.find_or_initialize_by(message_id: message.id)
  end

  def quality_score
    params.permit!.to_h
  end

  def score_data
    quality_score.dig(:quality_score, :qualityCheckResponse, :checks) || {}
  end
end
