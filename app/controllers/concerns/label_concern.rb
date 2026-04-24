module LabelConcern
  def create
    labels = Array(permitted_params[:labels]).map { |l| l.to_s.downcase }.uniq

    if labels.any?
      valid_titles = Current.account.labels.where(title: labels).pluck(:title)
      invalid_labels = labels - valid_titles

      if invalid_labels.any?
        render_could_not_create_error("Invalid labels: #{invalid_labels.join(', ')}. Labels must exist in the account.")
        return
      end
    end

    model.update_labels(labels)
    @labels = model.label_list
  end

  def index
    @labels = model.label_list
  end
end
