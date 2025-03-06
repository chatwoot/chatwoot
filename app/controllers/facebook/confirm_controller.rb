class Facebook::ConfirmController < ApplicationController
  include FacebookConcern

  def show
    if deletion_processed?(params[:id])
      render plain: 'Data Deleted Successfully', status: :ok
    else
      render plain: 'Processing. If there is an issue, please contact support', status: :ok
    end
  end
end
