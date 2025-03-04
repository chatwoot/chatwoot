class Facebook::ConfirmController < ApplicationController
  include FacebookConcern

  def show
    @id_to_process = params[:id]

    if deleting?
      render plain: 'Processing', status: :ok
    else
      render plain: 'Data Deleted Successfully', status: :ok
    end
  end
end
