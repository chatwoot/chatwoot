class Facebook::ConfirmController < ApplicationController
  include FacebookConcern

  def show
    if deleting?(params[:id])
      render plain: 'Processing', status: :ok
    else
      render plain: 'Data Deleted Successfully', status: :ok
    end
  end
end
