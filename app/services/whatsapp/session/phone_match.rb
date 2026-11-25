# Whether two WhatsApp numbers name the same line.
#
# Brazilian and Argentinian mobile numbers appear with and without the extra digit
# depending on when the account was created, so the number an operator typed and the
# number WhatsApp reports for the very same phone can differ textually. Comparing the
# raw digits therefore calls one line two different numbers, which is how a valid
# pairing gets rejected and how "did we leave this group?" answers no when we did.
module Whatsapp::Session::PhoneMatch
  module_function

  def same_number?(left, right)
    left = digits(left)
    right = digits(right)
    return false if left.blank? || right.blank?
    return true if left == right

    normalizer = normalizer_for(left) || normalizer_for(right)
    return false if normalizer.nil?

    normalizer.normalize(left) == normalizer.normalize(right)
  end

  # Every form the number may be stored under, itself included. Used where a lookup has
  # to reach a row written under the other ninth-digit form rather than merely decide
  # whether two numbers match.
  def variants(value)
    number = digits(value)
    return [] if number.blank?

    normalizer = normalizer_for(number)
    return [number] if normalizer.nil?

    (normalizer.variants(number) + [number]).uniq
  end

  def digits(value)
    value.to_s.gsub(/\D/, '')
  end

  def normalizer_for(value)
    Whatsapp::PhoneNumberNormalizationService::NORMALIZERS
      .map(&:new)
      .find { |normalizer| normalizer.handles_country?(value) }
  end
end
