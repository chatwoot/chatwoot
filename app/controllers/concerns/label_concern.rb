module LabelConcern
  def create
    model.update_labels(valid_labels)
    @labels = model.label_list
  end

  def index
    @labels = model.label_list
  end

  private

  def valid_labels
    posted = Array(permitted_params[:labels]).map { |title| title.to_s.downcase }
    return [] if posted.blank?

    model.account.labels.where(title: posted).pluck(:title)
  end
end
