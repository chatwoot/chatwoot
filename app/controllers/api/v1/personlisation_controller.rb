class Api::V1::PersonlisationController < Api::BaseController
  include HTTParty
  def personalise_variables
    return render json: { personalisedVariables: {} } if params[:templateFallbacks].blank? && params[:templateMetaData].blank?

    aws_response = HTTParty.post(
      'https://8fa6w81hm2.execute-api.us-east-1.amazonaws.com/contactVariables',
      body: params.to_json,
      headers: {
        'Content-Type' => 'application/json'
      }
    )

    if aws_response.success?
      render json: aws_response.parsed_response
    else
      render json: { error: 'Failed to process variables' }, status: :unprocessable_entity
    end
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
