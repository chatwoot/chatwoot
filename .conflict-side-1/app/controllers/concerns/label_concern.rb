module LabelConcern
  def create
    model.update_labels(permitted_params[:labels])
    @labels = model.label_list
  end

  def index
    @labels = model.label_list
  end
end
