class SignatureMatcher

  # Envoyé depuis mon iPhone
  # Von meinem Mobilgerät gesendet
  # Diese Nachricht wurde von meinem Android-Mobiltelefon mit K-9 Mail gesendet.
  # Nik from mobile
  # From My Iphone 6
  # Sent via mobile
  # Sent with Airmail
  # Sent from Windows Mail
  # Sent from my TI-85
  # <<sent by galaxy>>
  # (sent from a phone)
  # (Sent from mobile device)
  # 從我的 iPhone 傳送
  SIGNATURE_REGEXES ||= [
    # Chinese
    /^[[:blank:]]*從我的 iPhone 傳送/i,
    # English
    /^[[:blank:]]*[[:word:]]+ from mobile/i,
    /^[[:blank:]]*[\(<]*Sent (from|via|with|by) .+[\)>]*/i,
    /^[[:blank:]]*From my .{1,20}/i,
    /^[[:blank:]]*Get Outlook for /i,
    # French
    /^[[:blank:]]*Envoyé depuis (mon|Yahoo Mail)/i,
    # German
    /^[[:blank:]]*Von meinem .+ gesendet/i,
    /^[[:blank:]]*Diese Nachricht wurde von .+ gesendet/i,
    # Italian
    /^[[:blank:]]*Inviato da /i,
    # Norwegian
    /^[[:blank:]]*Sendt fra min /i,
    # Portuguese
    /^[[:blank:]]*Enviado do meu /i,
    # Spanish
    /^[[:blank:]]*Enviado desde mi /i,
    # Dutch
    /^[[:blank:]]*Verzonden met /i,
    /^[[:blank:]]*Verstuurd vanaf mijn /i,
    # Swedish
    /^[[:blank:]]*från min /i,
  ]

  def self.match?(line)
    # remove any markdown links
    stripped = line.gsub(/\[([^\]]+)\]\([^\)]+\)/) { $1 }
    SIGNATURE_REGEXES.any? { |r| stripped =~ r }
  end

end
