# Based on ISO_639-3 Codes. ref: https://en.wikipedia.org/wiki/List_of_ISO_639-2_codes
# This Hash is used in account model, so do not change the index for existing languages

LANGUAGES_CONFIG = {
  0 => { name: 'English', iso_639_3_code: 'eng', iso_639_1_code: 'en' },
  1 => { name: 'Arabic', iso_639_3_code: 'ara', iso_639_1_code: 'ar' },
  2 => { name: 'Dutch', iso_639_3_code: 'nld', iso_639_1_code: 'nl' },
  3 => { name: 'French', iso_639_3_code: 'fra', iso_639_1_code: 'fr' },
  4 => { name: 'German', iso_639_3_code: 'deu', iso_639_1_code: 'de' },
  5 => { name: 'Hindi', iso_639_3_code: 'hin', iso_639_1_code: 'hi' },
  6 => { name: 'Italian', iso_639_3_code: 'ita', iso_639_1_code: 'it' },
  7 => { name: 'Japanese', iso_639_3_code: 'jpn', iso_639_1_code: 'ja' },
  8 => { name: 'Korean', iso_639_3_code: 'kor', iso_639_1_code: 'ko' },
  9 => { name: 'Portuguese', iso_639_3_code: 'por', iso_639_1_code: 'pt' },
  10 => { name: 'Russian', iso_639_3_code: 'rus', iso_639_1_code: 'ru' },
  11 => { name: 'Chinese', iso_639_3_code: 'zho', iso_639_1_code: 'zh' },
  12 => { name: 'Spanish', iso_639_3_code: 'spa', iso_639_1_code: 'es' },
  13 => { name: 'Malayalam', iso_639_3_code: 'mal', iso_639_1_code: 'ml' },
  14 => { name: 'Catalan', iso_639_3_code: 'cat', iso_639_1_code: 'ca' }
}.freeze
