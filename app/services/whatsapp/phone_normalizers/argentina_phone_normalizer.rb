class Whatsapp::PhoneNormalizers::ArgentinaPhoneNormalizer < Whatsapp::PhoneNormalizers::BasePhoneNormalizer
  def handles_country?(waid)
    waid.start_with?('549')
  end

  def normalize(waid)
    return waid unless handles_country?(waid)

    # Remove the '9' after country code for Argentina numbers
    # 5491123456789 -> 541123456789
    waid.sub(/^549/, '54')
  end
end
