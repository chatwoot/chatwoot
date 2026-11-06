# Reads Jev answers defensively. A missing or malformed answer reads as no confidence.
module Captain::JevAnswers
  module_function

  def probability(hash, key)
    value = hash[key] if hash.is_a?(Hash) && key
    value.is_a?(Numeric) ? value.to_f : 0.0
  end

  def choice(answer)
    value = answer['choice'] if answer.is_a?(Hash)
    value if value.is_a?(String)
  end

  def choice_probability(answer)
    answer.is_a?(Hash) ? probability(answer['probabilities'], choice(answer)) : 0.0
  end

  # The chosen option when Jev gave it at least `minimum` probability.
  def confident_choice(answer, minimum)
    choice(answer) if choice_probability(answer) >= minimum
  end
end
