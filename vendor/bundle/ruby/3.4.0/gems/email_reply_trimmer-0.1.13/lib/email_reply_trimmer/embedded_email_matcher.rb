class EmbeddedEmailMatcher

  # On Wed, Sep 25, 2013, at 03:57 PM, jorge_castro wrote:
  # On Thursday, June 27, 2013, knwang via Discourse Meta wrote:
  # On Wed, 2015-12-02 at 13:58 +0000, Tom Newsom wrote:
  # On 10/12/15 12:30, Jeff Atwood wrote:
  # ---- On Tue, 22 Dec 2015 14:17:36 +0530 Sam Saffron&lt;info@discourse.org&gt; wrote ----
  # Op 24 aug. 2013 om 16:48 heeft ven88 via Discourse Meta <info@discourse.org> het volgende geschreven:
  # Le 4 janv. 2016 19:03, "Neil Lalonde" <info@discourse.org> a écrit :
  # Dnia 14 lip 2015 o godz. 00:25 Michael Downey <info@discourse.org> napisał(a):
  # Em seg, 27 de jul de 2015 17:13, Neil Lalonde <info@discourse.org> escreveu:
  # El jueves, 21 de noviembre de 2013, codinghorror escribió:
  # At 6/16/2016 08:32 PM, you wrote:
  ON_DATE_SOMEONE_WROTE_REGEXES ||= [
    # Chinese
    /^[[:blank:]<>-]*在 (?:(?!\b(?>在|写道)\b).)+?写道[[:blank:].:>-]*$/im,
    # Dutch
    /^[[:blank:]<>-]*Op (?:(?!\b(?>Op|het\svolgende\sgeschreven|schreef)\b).)+?(het\svolgende\sgeschreven|schreef[^:]+)[[:blank:].:>-]*$/im,
    # English
    /^[[:blank:]<>-]*In message (?:(?!\b(?>In message|writes)\b).)+?writes[[:blank:].:>-]*$/im,
    /^[[:blank:]<>-]*(On|At) (?:(?!\b(?>On|wrote|writes|says|said)\b).)+?(wrote|writes|says|said)[[:blank:].:>-]*$/im,
    # French
    /^[[:blank:]<>-]*Le (?:(?!\b(?>Le|nous\sa\sdit|a\s+écrit)\b).)+?(nous\sa\sdit|a\s+écrit)[[:blank:].:>-]*$/im,
    # German
    /^[[:blank:]<>-]*Am (?:(?!\b(?>Am|schrieben\sSie)\b).)+?schrieben\sSie[[:blank:].:>-]*$/im,
    /^[[:blank:]<>-]*Am (?:(?!\b(?>Am|geschrieben)\b).)+?(geschrieben|schrieb[^:]+)[[:blank:].:>-]*$/im,
    # Italian
    /^[[:blank:]<>-]*Il (?:(?!\b(?>Il|ha\sscritto)\b).)+?ha\sscritto[[:blank:].:>-]*$/im,
    # Polish
    /^[[:blank:]<>-]*(Dnia|Dňa) (?:(?!\b(?>Dnia|Dňa|napisał)\b).)+?napisał(\(a\))?[[:blank:].:>-]*$/im,
    # Portuguese
    /^[[:blank:]<>-]*Em (?:(?!\b(?>Em|escreveu)\b).)+?escreveu[[:blank:].:>-]*$/im,
    # Spanish
    /^[[:blank:]<>-]*El (?:(?!\b(?>El|escribió)\b).)+?escribió[[:blank:].:>-]*$/im,
  ]

  # Op 10 dec. 2015 18:35 schreef "Arpit Jalan" <info@discourse.org>:
  # Am 18.09.2013 um 16:24 schrieb codinghorror <info@discourse.org>:
  # Den 15. jun. 2016 kl. 20.42 skrev Jeff Atwood <info@discourse.org>:
  # søn. 30. apr. 2017 kl. 00.26 skrev David Taylor <meta@discoursemail.com>:
  ON_DATE_WROTE_SOMEONE_MARKERS = [
    # Dutch
    ["Op", "schreef"],
    # German
    ["Am", "schrieb"],
    # Norwegian
    ["Den", "skrev"],
    # Dutch
    ["søn\.", "skrev"],
  ]

  ON_DATE_WROTE_SOMEONE_REGEXES = ON_DATE_WROTE_SOMEONE_MARKERS.map do |on, wrote|
    /^[[:blank:]>]*#{on}\s.+\s#{wrote}\s[^:]+:/
  end

  # суббота, 14 марта 2015 г. пользователь etewiah написал:
  # 23 mar 2017 21:25 "Neil Lalonde" <meta@discoursemail.com> napisał(a):
  # 30 серп. 2016 р. 20:45 "Arpit" no-reply@example.com пише:
  DATE_SOMEONE_WROTE_MARKERS = [
    # Russian
    ["пользователь", "написал"],
    # Polish
    ["", "napisał\\(a\\)"],
    # Ukrainian
    ["", "пише"],
  ]

  DATE_SOMEONE_WROTE_REGEXES = DATE_SOMEONE_WROTE_MARKERS.map do |user, wrote|
    user.size == 0 ?
      /\d{4}.{1,80}\n?.{0,80}?#{wrote}:/ :
      /\d{4}.{1,80}#{user}.{0,80}\n?.{0,80}?#{wrote}:/
  end

  # Max Mustermann <try_discourse@discoursemail.com> schrieb am Fr., 28. Apr. 2017 um 11:53 Uhr:
  SOMEONE_WROTE_ON_DATE_REGEXES ||= [
    # English
    /^.+\bwrote\b[[:space:]]+\bon\b.+[^:]+:/,
    # German
    /^.+\bschrieb\b[[:space:]]+\bam\b.+[^:]+:/,
  ]

  # 2016-03-03 17:21 GMT+01:00 Some One
  ISO_DATE_SOMEONE_REGEX = /^[[:blank:]>]*20\d\d-\d\d-\d\d \d\d:\d\d GMT\+\d\d:\d\d [\w[:blank:]]+$/

  # 2015-10-18 0:17 GMT+03:00 Matt Palmer <info@discourse.org>:
  # 2013/10/2 camilohollanda <info@discourse.org>
  # вт, 5 янв. 2016 г. в 23:39, Erlend Sogge Heggen <info@discourse.org>:
  # ср, 1 апр. 2015, 18:29, Denis Didkovsky <info@discourse.org>:
  DATE_SOMEONE_EMAIL_REGEX = /\d{4}.{1,80}\s?<[^@<>]+@[^@<>.]+\.[^@<>]+>:?$/

  # codinghorror via Discourse Meta wrote:
  # codinghorror via Discourse Meta <info@discourse.org> schrieb:
  SOMEONE_VIA_SOMETHING_WROTE_MARKERS = [
    # English
    "wrote",
    # German
    "schrieb",
  ]

  SOMEONE_VIA_SOMETHING_WROTE_REGEXES = SOMEONE_VIA_SOMETHING_WROTE_MARKERS.map do |wrote|
    /^.+ via .+ #{wrote}:?[[:blank:]]*$/
  end

  # Some One <info@discourse.org> wrote:
  # Gavin Sinclair (gsinclair@soyabean.com.au) wrote:
  SOMEONE_EMAIL_WROTE_REGEX = /^.+\b[\w.+-]+@[\w.-]+\.\w{2,}\b.+wrote:?$/

  # Posted by mpalmer on 01/21/2016
  POSTED_BY_SOMEONE_ON_DATE_REGEX = /^[[:blank:]>]*Posted by .+ on \d{2}\/\d{2}\/\d{4}$/i

  # Begin forwarded message:
  # Reply Message
  # ----- Forwarded Message -----
  # ----- Original Message -----
  # -----Original Message-----
  # *----- Original Message -----*
  # ----- Reply message -----
  # ------------------ 原始邮件 ------------------
  FORWARDED_EMAIL_REGEXES = [
    # English
    /^[[:blank:]>]*Begin forwarded message:/i,
    /^[[:blank:]>*]*-{2,}[[:blank:]]*(Forwarded|Original|Reply) Message[[:blank:]]*-{2,}/i,
    # French
    /^[[:blank:]>]*Début du message transféré :/i,
    /^[[:blank:]>*]*-{2,}[[:blank:]]*Message transféré[[:blank:]]*-{2,}/i,
    # German
    /^[[:blank:]>*]*-{2,}[[:blank:]]*Ursprüngliche Nachricht[[:blank:]]*-{2,}/i,
    # Spanish
    /^[[:blank:]>*]*-{2,}[[:blank:]]*Mensaje original[[:blank:]]*-{2,}/i,
    # Chinese
    /^[[:blank:]>*]*-{2,}[[:blank:]]*原始邮件[[:blank:]]*-{2,}/i,
  ]

  EMBEDDED_REGEXES = [
    ON_DATE_SOMEONE_WROTE_REGEXES,
    ON_DATE_WROTE_SOMEONE_REGEXES,
    DATE_SOMEONE_WROTE_REGEXES,
    DATE_SOMEONE_EMAIL_REGEX,
    SOMEONE_WROTE_ON_DATE_REGEXES,
    ISO_DATE_SOMEONE_REGEX,
    SOMEONE_VIA_SOMETHING_WROTE_REGEXES,
    SOMEONE_EMAIL_WROTE_REGEX,
    POSTED_BY_SOMEONE_ON_DATE_REGEX,
    FORWARDED_EMAIL_REGEXES,
  ].flatten

  def self.match?(line)
    EMBEDDED_REGEXES.any? { |r| line =~ r }
  end

end
