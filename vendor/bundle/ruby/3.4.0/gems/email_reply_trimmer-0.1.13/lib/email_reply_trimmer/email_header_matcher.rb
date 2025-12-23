class EmailHeaderMatcher

  EMAIL_HEADERS_WITH_DATE_MARKERS ||= [
    # Norwegian
    ["Sendt"],
    # English
    ["Sent", "Date"],
    # French
    ["Date", "Le"],
    # German
    ["Gesendet"],
    # Portuguese
    ["Enviada em"],
    # Spanish
    ["Enviado"],
    # Spanish (Mexican)
    ["Fecha"],
    # Italian
    ["Data"],
    # Dutch
    ["Datum"],
    # Swedish
    ["Skickat"],
    # Chinese
    ["发送时间"],
  ]

  EMAIL_HEADERS_WITH_DATE_REGEXES ||= EMAIL_HEADERS_WITH_DATE_MARKERS.map do |header|
    /^[[:blank:]*]*(?:#{header.join("|")})[[:blank:]*]*:.*\d+/
  end

  EMAIL_HEADERS_WITH_TEXT_MARKERS ||= [
    # Norwegian
    ["Fra", "Til", "Emne"],
    # English
    ["From", "To", "Cc", "Reply-To", "Subject"],
    # French
    ["De", "Expéditeur", "À", "Destinataire", "Répondre à", "Objet"],
    # German
    ["Von", "An", "Betreff"],
    # Portuguese
    ["De", "Para", "Assunto"],
    # Spanish
    ["De", "Para", "Asunto"],
    # Italian
    ["Da", "Risposta", "A", "Oggetto"],
    # Dutch
    ["Van", "Beantwoorden - Aan", "Aan", "Onderwerp"],
    # Swedish
    ["Från", "Till", "Ämne"],
    # Chinese
    ["发件人", "收件人", "主题"],
  ]

  EMAIL_HEADERS_WITH_TEXT_REGEXES ||= EMAIL_HEADERS_WITH_TEXT_MARKERS.map do |header|
    /^[[:blank:]*]*(?:#{header.join("|")})[[:blank:]*]*:.*[[:word:]]+/i
  end

  EMAIL_HEADER_REGEXES ||= [
    EMAIL_HEADERS_WITH_DATE_REGEXES,
    EMAIL_HEADERS_WITH_TEXT_REGEXES,
  ].flatten

  def self.match?(line)
    EMAIL_HEADER_REGEXES.any? { |r| line =~ r }
  end

end
