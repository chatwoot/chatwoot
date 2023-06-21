module HmacConcern
  def hmac_verified?
    ActiveModel::Type::Boolean.new.cast(params[:hmac_verified]).present?
  end
end
