module EvolutionGo::PayloadHelper
  private

  def qr_image_from(payload_data)
    candidate_a = payload_value(payload_data, :qrcode, :Qrcode)
    candidate_b = payload_value(payload_data, :code, :Code)
    return candidate_a if candidate_a.to_s.start_with?('data:image/')
    return candidate_b if candidate_b.to_s.start_with?('data:image/')

    nil
  end

  def pairing_code_from(payload_data)
    candidate_a = payload_value(payload_data, :code, :Code)
    candidate_b = payload_value(payload_data, :qrcode, :Qrcode)
    return candidate_a unless candidate_a.to_s.start_with?('data:image/')
    return candidate_b unless candidate_b.to_s.start_with?('data:image/')

    nil
  end

  def payload_value(payload_data, *keys, default: nil)
    source = payload_data.to_h.with_indifferent_access

    keys.each do |key|
      value = source[key]
      return value if value.present?
      return value if value == false
    end

    default
  end
end
