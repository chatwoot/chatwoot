module BaileysHelper
  def extract_baileys_message_timestamp(timestamp)
    # NOTE: Timestamp might be in this format {"low"=>1748003165, "high"=>0, "unsigned"=>true}
    if timestamp.is_a?(Hash) && timestamp.key?('low')
      low = timestamp['low'].to_i
      high = timestamp.fetch('high', 0).to_i
      return (high << 32) | low
    end

    # NOTE: Timestamp might be a string or a number
    timestamp.to_i
  end
end
