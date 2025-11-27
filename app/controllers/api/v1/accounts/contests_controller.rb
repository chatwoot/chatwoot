class Api::V1::Accounts::ContestsController < Api::V1::Accounts::BaseController
  def index
    render json: { data: contest_client.list }
  end

  def create
    contest = contest_client.create(contest_params.to_h)
    render json: { data: contest }, status: :created
  end

  def update
    contest = contest_client.update(params[:id], contest_params.to_h)
    render json: { data: contest }
  end

  def destroy
    contest_client.delete(params[:id])
    head :ok
  end

  private

  def contest_client
    dealership_id = params[:dealership_id].presence || current_account&.dealership_id
    @contest_client ||= ::Contests::ContestService.new(dealership_id:)
  end

  def contest_params
    params.require(:contest).permit(
      :name,
      :start_date,
      :end_date,
      :description,
      :terms_and_condition,
      trigger_words: [],
      questionnaire: %i[question description]
    )
  end
end

