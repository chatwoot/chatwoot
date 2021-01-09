# Based on ISO_639-3 Codes. ref: https://en.wikipedia.org/wiki/List_of_ISO_639-2_codes
# This Hash is used in account model, so do not change the index for existing languages

LANGUAGES_CONFIG = {
  0 => { name: 'English (en)', iso_639_3_code: 'eng', iso_639_1_code: 'en', enabled: true },
  1 => { name: 'العربية (ar)', iso_639_3_code: 'ara', iso_639_1_code: 'ar', enabled: true },
  2 => { name: 'Nederlands (nl) ', iso_639_3_code: 'nld', iso_639_1_code: 'nl', enabled: true },
  3 => { name: 'Français (fr)', iso_639_3_code: 'fra', iso_639_1_code: 'fr', enabled: true },
  4 => { name: 'Deutsch (de)', iso_639_3_code: 'deu', iso_639_1_code: 'de', enabled: true },
  5 => { name: 'हिन्दी (hi)', iso_639_3_code: 'hin', iso_639_1_code: 'hi', enabled: false },
  6 => { name: 'Italiano (it)', iso_639_3_code: 'ita', iso_639_1_code: 'it', enabled: true },
  7 => { name: '日本語 (ja)', iso_639_3_code: 'jpn', iso_639_1_code: 'ja', enabled: true },
  8 => { name: '한국어 (ko)', iso_639_3_code: 'kor', iso_639_1_code: 'ko', enabled: true },
  9 => { name: 'Português (pt)', iso_639_3_code: 'por', iso_639_1_code: 'pt', enabled: true },
  10 => { name: 'русский (ru)', iso_639_3_code: 'rus', iso_639_1_code: 'ru', enabled: true },
  11 => { name: '中文 (zh)', iso_639_3_code: 'zho', iso_639_1_code: 'zh', enabled: false },
  12 => { name: 'Español (es)', iso_639_3_code: 'spa', iso_639_1_code: 'es', enabled: true },
  13 => { name: 'മലയാളം (ml)', iso_639_3_code: 'mal', iso_639_1_code: 'ml', enabled: true },
  14 => { name: 'Català (ca)', iso_639_3_code: 'cat', iso_639_1_code: 'ca', enabled: true },
  15 => { name: 'ελληνικά (el)', iso_639_3_code: 'ell', iso_639_1_code: 'el', enabled: true },
  16 => { name: 'Português Brasileiro (pt-BR)', iso_639_3_code: '', iso_639_1_code: 'pt_BR', enabled: true },
  17 => { name: 'Română (ro)', iso_639_3_code: 'ron', iso_639_1_code: 'ro', enabled: true },
  18 => { name: 'தமிழ் (ta)', iso_639_3_code: 'tam', iso_639_1_code: 'ta', enabled: true },
  19 => { name: 'فارسی (fa)', iso_639_3_code: 'fas', iso_639_1_code: 'fa', enabled: true },
  20 => { name: '中文 (台湾) (zh-TW)', iso_639_3_code: 'zho', iso_639_1_code: 'zh_TW', enabled: true },
  21 => { name: 'Tiếng Việt (vi)', iso_639_3_code: 'vie', iso_639_1_code: 'vi', enabled: true },
  22 => { name: 'dansk (da)', iso_639_3_code: 'dan', iso_639_1_code: 'da', enabled: true },
  23 => { name: 'Türkçe (tr)', iso_639_3_code: 'tur', iso_639_1_code: 'tr', enabled: true },
  24 => { name: 'čeština (cs)', iso_639_3_code: 'ces', iso_639_1_code: 'cs', enabled: true },
  25 => { name: 'suomi, suomen kieli (fi)', iso_639_3_code: 'fin', iso_639_1_code: 'fi', enabled: true },
  26 => { name: 'Bahasa Indonesia (id)', iso_639_3_code: 'ind', iso_639_1_code: 'id', enabled: true },
  27 => { name: 'Svenska (sv)', iso_639_3_code: 'swe', iso_639_1_code: 'sv', enabled: true }

}.filter { |_key, val| val[:enabled] }.freeze

Rails.configuration.i18n.available_locales = LANGUAGES_CONFIG.map { |_index, lang| lang[:iso_639_1_code].to_sym }
