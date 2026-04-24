module LabelConcern
  def create
    requested_labels = permitted_params[:labels]
    if requested_labels.present?
      valid_labels = requested_labels.select { |label| label.is_a?(String) && label.present? }
      existing_label_titles = model.account.labels.where(title: valid_labels.map(&:downcase)).pluck(:title)
      invalid_labels = valid_labels.reject { |label| existing_label_titles.include?(label.downcase) }
      if invalid_labels.present?
        render_could_not_create_error("Labels do not exist: #{invalid_labels.join(', ')}")
        return
      end
    end
    model.update_labels(requested_labels)
    @labels = model.label_list
  end

  def index
    @labels = model.label_list
  end
end
