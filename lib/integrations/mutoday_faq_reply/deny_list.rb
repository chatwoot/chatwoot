class Integrations::MutodayFaqReply::DenyList
  # Politeness particles, stripped from the tail before matching. Thai does not space its
  # words, so "ขอเงินคืนหน่อยครับ" must normalise to "ขอเงินคืน" or a term list written
  # naturally never fires. Stripped one at a time until stable, suffix-only, and never
  # down to nothing — a message that is only "ครับ" stays "ครับ".
  TRAILERS = %w[ครับผม ครับ คับ ค่ะ คะ ค่า จ้า จ้ะ จ๊ะ นะ น่ะ หน่อย บ้าง ด้วย เลย].freeze

  # Thai terms are matched as plain substrings — \b is meaningless in Thai script.
  #
  # RULE FOR ADDING A TERM: it must be at least 3 Thai characters AND must not be a
  # substring of any phrase in NON_MATCHING_FIXTURES. That rule, not a list of negative
  # exceptions, is what keeps "ขอบคุณครับ" from being read as a request. A spec enforces
  # it, and the corpus importer enforces the matching rule in the other direction: no term
  # here may be a substring of any approved question, or that answer could never ship.
  #
  # Absent on purpose: ราคา · ค่าสมัคร · ค่าเทอม · สมัคร. Those are what the corpus is for.
  #
  # crisis is checked first. Every topic routes to the same body, so order only decides the
  # telemetry label — and a message carrying both a crisis phrase and a complaint phrase
  # must be counted as crisis. That count is the entire reason the group survived the
  # decision to cut the crisis-specific reply.
  THAI_TERMS = {
    crisis: %w[
      ฆ่าตัวตาย อยากตาย ทำร้ายตัวเอง ไม่อยากมีชีวิต ทำร้ายร่างกาย ถูกคุกคาม ล่วงละเมิด
    ],
    money: %w[
      คืนเงิน เงินคืน รีฟันด์ เก็บเงินซ้ำ ตัดเงินซ้ำ ตัดเงินสองรอบ หักเงินซ้ำ
      โดนหักเงิน เงินหาย โอนผิด โอนเกิน จ่ายซ้ำ จ่ายเกิน ยกเลิกออเดอร์ ยกเลิกคำสั่งซื้อ
      ยกเลิกการสั่งซื้อ ยกเลิกสมาชิก ยกเลิกบริการ ยกเลิกสัญญา เคลม ใบเสร็จ ใบกำกับภาษี
      ค่าปรับ มัดจำ
    ],
    complaint: %w[
      ร้องเรียน ไม่พอใจ แย่มาก ห่วยมาก หลอกลวง ต้มตุ๋น ฉ้อโกง โกงเงิน โดนโกง รับไม่ได้ เสียหาย
    ],
    legal: %w[
      ทนาย ฟ้องร้อง จะฟ้อง ดำเนินคดี แจ้งความ หมิ่นประมาท สคบ คุ้มครองผู้บริโภค ลบข้อมูลของฉัน
    ],
    # Narrowed to unambiguous escalation. "ติดต่อทีมงาน", "ติดต่อเจ้าหน้าที่", "เบอร์โทร"
    # and the bare "เจ้าหน้าที่" are information requests and belong to the corpus — the
    # first of those is the headline question in the worked corpus example, so leaving it
    # here meant that answer could never ship.
    #
    # "ต่อเจ้าหน้าที่" is gone for the same reason: dropping "ติดต่อเจ้าหน้าที่" from this
    # list achieves nothing while a substring of it is still listed.
    human: %w[
      คุยกับคน คุยกับเจ้าหน้าที่ ขอเจ้าหน้าที่ คุยกับแอดมิน ขอแอดมิน คุยกับพนักงาน
    ],
    credential: %w[บัตรประชาชน เลขบัญชี รหัสผ่าน รหัสโอที เลขหลังบัตร]
  }.freeze

  # ASCII terms DO get word boundaries — \b is meaningful for Latin script, and without it
  # "otp" fires inside any word containing those three letters.
  ASCII_TERMS = {
    money: %w[refund chargeback],
    legal: %w[pdpa lawyer lawsuit],
    human: %w[human operator],
    credential: %w[otp cvv password]
  }.freeze

  # Ordinary Thai messages that must never be read as a deny-list topic. This is a frozen
  # constant rather than prose because two mechanical checks consume it: the spec asserts
  # every one returns nil, and it asserts no term above is a substring of any of them.
  # rubocop:disable Style/WordArray -- these are Thai sentences, and %w mangles them
  NON_MATCHING_FIXTURES = [
    'ขอบคุณครับ', 'ขอบคุณค่ะ', 'ขอบพระคุณมากครับ', 'ขอโทษครับ', 'ขออภัยด้วยครับ',
    'ขอสอบถามหน่อยครับ', 'ขอถามหน่อย', 'ขอข้อมูลเพิ่มเติมครับ', 'ขอดูรายละเอียดหน่อย',
    'ขอราคาหน่อยครับ', 'ค่าสมัครเท่าไหร่ครับ', 'สมัครยังไงครับ', 'เปิดรับสมัครเมื่อไหร่',
    'อยากทราบกำหนดการครับ', 'สวัสดีครับ'
  ].freeze
  # rubocop:enable Style/WordArray

  # Questions the corpus exists to answer. A term that swallows one of these makes its
  # approved answer unshippable, which is how the headline corpus question ended up inside
  # the deny list in the first place. Held here, next to the terms, so the same mechanical
  # check covers them and the mistake cannot come back by a different route.
  CORPUS_QUESTION_FIXTURES = [
    'ติดต่อทีมงาน MU Today ได้ช่วงเวลาไหน', 'ติดต่อเจ้าหน้าที่ได้ที่ไหน', 'ติดต่อแอดมินยังไงครับ',
    'ขอเบอร์โทรหน่อยครับ', 'มีสายด่วนไหมครับ', 'คอลเซ็นเตอร์เปิดกี่โมง',
    'อยากส่งข่าวประชาสัมพันธ์ต้องทำยังไง', 'ขอใช้ภาพนี้ได้ไหมครับ เรื่องลิขสิทธิ์',
    'ขอทราบนโยบายข้อมูลส่วนบุคคล', 'เจ้าหน้าที่ทำงานวันไหนบ้าง'
  ].freeze

  THAI_PATTERNS = THAI_TERMS.transform_values { |terms| Regexp.union(terms) }.freeze
  ASCII_PATTERNS = ASCII_TERMS.transform_values do |terms|
    /\b(?:#{terms.map { |t| Regexp.escape(t) }.join('|')})\b/i
  end.freeze

  # Every term, in one flat list. The corpus importer walks this to refuse an approved
  # question that a deny term would swallow.
  ALL_TERMS = (THAI_TERMS.values + ASCII_TERMS.values).flatten.freeze

  # Returns a topic symbol (:crisis, :money, :complaint, :legal, :human, :credential) or
  # nil. The topic is a telemetry label only — every topic routes to the same body.
  def self.match(text)
    normalised = normalise(text)
    return nil if normalised.blank?

    thai_topic(normalised) || ascii_topic(normalised)
  end

  def self.normalise(raw)
    text = raw.to_s.strip.gsub(/\s+/, ' ').downcase
    loop do
      stripped = strip_one_trailer(strip_punctuation(text))
      return text if stripped == text

      text = stripped
    end
  end

  def self.strip_punctuation(text)
    text.sub(/[?？!！.]+\z/, '').rstrip
  end
  private_class_method :strip_punctuation

  def self.strip_one_trailer(text)
    particle = TRAILERS.find { |candidate| text.length > candidate.length && text.end_with?(candidate) }
    return text if particle.nil?

    text.delete_suffix(particle).rstrip
  end
  private_class_method :strip_one_trailer

  def self.thai_topic(text)
    THAI_PATTERNS.find { |_topic, pattern| pattern.match?(text) }&.first
  end
  private_class_method :thai_topic

  def self.ascii_topic(text)
    ASCII_PATTERNS.find { |_topic, pattern| pattern.match?(text) }&.first
  end
  private_class_method :ascii_topic
end
