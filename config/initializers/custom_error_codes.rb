Rack::Utils::HTTP_STATUS_CODES.merge!({
  901 => 'Trial Expired',
  902 => 'Account Suspended'
})

Rack::Utils::SYMBOL_TO_STATUS_CODE = Hash[*Rack::Utils::HTTP_STATUS_CODES.map { |code, message|
      [message.downcase.gsub(/\s|-|'/, '_').to_sym, code]
}.flatten]
