class Facebook::ConfirmController < ApplicationController
  class InvalidDigestError < StandardError; end

  def show
    @id_to_process = params[:id]

    if processing?
      render json: { status: 'Processing' }, status: :ok
    else
      render json: { status: 'Data Deleted Successfully' }, status: :ok
    end
  end

  private

  def processing?
    key = format(::Redis::Alfred::META_DELETE_PROCESSING, id: @id_to_process)
    ::Redis::Alfred.get(key).present?
  end
end
