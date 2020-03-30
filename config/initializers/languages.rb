# Based on ISO_639-3 Codes. ref: https://en.wikipedia.org/wiki/List_of_ISO_639-2_codes
# This Hash is used in account model, so do not change the index for existing languages

LANGUAGES_CONFIG = {
  0 => { name: 'English', iso_639_3_code: 'eng' },
  1 => { name: 'Arabic', iso_639_3_code: 'ara' },
  2 => { name: 'Dutch', iso_639_3_code: 'nld' },
  3 => { name: 'French', iso_639_3_code: 'fra' },
  4 => { name: 'German', iso_639_3_code: 'deu' },
  5 => { name: 'Hindi', iso_639_3_code: 'hin' },
  6 => { name: 'Italian', iso_639_3_code: 'ita' },
  7 => { name: 'Japanese', iso_639_3_code: 'jpn' },
  8 => { name: 'Korean', iso_639_3_code: 'kor' },
  9 => { name: 'Portugues', iso_639_3_code: 'por' },
  10 => { name: 'Russian', iso_639_3_code: 'rus' },
  11 => { name: 'Chinese', iso_639_3_code: 'zho' },
  12 => { name: 'Spanish', iso_639_3_code: 'spa' }
}.freeze
