module BspdAccessHelper
  CACHE_TTL = 30.minutes

  def billing_status(active_account_id)
    cache_key = "bspd:billing_status:#{active_account_id}"

    cached_result = Redis::Alfred.get(cache_key)
    return cached_result == 'true' if cached_result

    # api call to bitespeed to check billing status
    # get api call to localhost:3001/csdb/auth/verify with accountId as query param
    # if api call is successful, return true
    # else return false
    result = false

    begin
      response = HTTParty.get("https://ufg5p259v2.execute-api.us-east-1.amazonaws.com/prod/csdb/auth/verify?accountId=#{active_account_id}")
      Rails.logger.info "BSPD Access Helper: Billing status response - #{response}"

      result = response.success?
    rescue StandardError => e
      Rails.logger.error "BSPD Access Helper: Error checking billing status - #{e.message}"
      result = false
    end

    Redis::Alfred.setex(cache_key, result.to_s, CACHE_TTL)
    result
  end

  def clear_cache(active_account_id)
    cache_key = "bspd:billing_status:#{active_account_id}"
    Redis::Alfred.delete(cache_key)
  end
end
