const languages = [
  {
    name: 'Abkhazian',
    id: 'ab',
    rtl: false,
  },
  {
    name: 'Afar',
    id: 'aa',
    rtl: false,
  },
  {
    name: 'Afrikaans',
    id: 'af',
    rtl: false,
  },
  {
    name: 'Akan',
    id: 'ak',
    rtl: false,
  },
  {
    name: 'Albanian',
    id: 'sq',
    rtl: false,
  },
  {
    name: 'Amharic',
    id: 'am',
    rtl: false,
  },
  {
    name: 'Arabic',
    id: 'ar',
    rtl: true,
  },
  {
    name: 'Aragonese',
    id: 'an',
    rtl: false,
  },
  {
    name: 'Armenian',
    id: 'hy',
    rtl: false,
  },
  {
    name: 'Assamese',
    id: 'as',
    rtl: true,
  },
  {
    name: 'Avaric',
    id: 'av',
    rtl: false,
  },
  {
    name: 'Avestan',
    id: 'ae',
    rtl: false,
  },
  {
    name: 'Aymara',
    id: 'ay',
    rtl: false,
  },
  {
    name: 'Azerbaijani',
    id: 'az',
    rtl: false,
  },
  {
    name: 'Bambara',
    id: 'bm',
    rtl: false,
  },
  {
    name: 'Bashkir',
    id: 'ba',
    rtl: false,
  },
  {
    name: 'Basque',
    id: 'eu',
    rtl: false,
  },
  {
    name: 'Belarusian',
    id: 'be',
    rtl: false,
  },
  {
    name: 'Bengali',
    id: 'bn',
    rtl: false,
  },
  {
    name: 'Bislama',
    id: 'bi',
    rtl: false,
  },
  {
    name: 'Bosnian',
    id: 'bs',
    rtl: false,
  },
  {
    name: 'Breton',
    id: 'br',
    rtl: false,
  },
  {
    name: 'Bulgarian',
    id: 'bg',
    rtl: false,
  },
  {
    name: 'Burmese',
    id: 'my',
    rtl: false,
  },
  {
    name: 'Catalan',
    id: 'ca',
    rtl: false,
  },
  {
    name: 'Chamorro',
    id: 'ch',
    rtl: false,
  },
  {
    name: 'Chechen',
    id: 'ce',
    rtl: false,
  },
  {
    name: 'Chichewa',
    id: 'ny',
    rtl: false,
  },
  {
    name: 'Chinese',
    id: 'zh',
    rtl: false,
  },
  {
    name: 'Church Slavonic',
    id: 'cu',
    rtl: false,
  },
  {
    name: 'Chuvash',
    id: 'cv',
    rtl: false,
  },
  {
    name: 'Cornish',
    id: 'kw',
    rtl: false,
  },
  {
    name: 'Corsican',
    id: 'co',
    rtl: false,
  },
  {
    name: 'Cree',
    id: 'cr',
    rtl: false,
  },
  {
    name: 'Croatian',
    id: 'hr',
    rtl: false,
  },
  {
    name: 'Czech',
    id: 'cs',
    rtl: false,
  },
  {
    name: 'Danish',
    id: 'da',
    rtl: false,
  },
  {
    name: 'Divehi',
    id: 'dv',
    rtl: false,
  },
  {
    name: 'Dutch',
    id: 'nl',
    rtl: false,
  },
  {
    name: 'Dzongkha',
    id: 'dz',
    rtl: false,
  },
  {
    name: 'English',
    id: 'en',
    rtl: false,
  },
  {
    name: 'Esperanto',
    id: 'eo',
    rtl: false,
  },
  {
    name: 'Estonian',
    id: 'et',
    rtl: false,
  },
  {
    name: 'Ewe',
    id: 'ee',
    rtl: false,
  },
  {
    name: 'Faroese',
    id: 'fo',
    rtl: false,
  },
  {
    name: 'Fijian',
    id: 'fj',
    rtl: false,
  },
  {
    name: 'Finnish',
    id: 'fi',
    rtl: false,
  },
  {
    name: 'French',
    id: 'fr',
    rtl: false,
  },
  {
    name: 'Western Frisian',
    id: 'fy',
    rtl: false,
  },
  {
    name: 'Fulah',
    id: 'ff',
    rtl: false,
  },
  {
    name: 'Gaelic',
    id: 'gd',
    rtl: false,
  },
  {
    name: 'Galician',
    id: 'gl',
    rtl: false,
  },
  {
    name: 'Ganda',
    id: 'lg',
    rtl: false,
  },
  {
    name: 'Georgian',
    id: 'ka',
    rtl: false,
  },
  {
    name: 'German',
    id: 'de',
    rtl: false,
  },
  {
    name: 'Greek',
    id: 'el',
    rtl: false,
  },
  {
    name: 'Kalaallisut',
    id: 'kl',
    rtl: false,
  },
  {
    name: 'Guarani',
    id: 'gn',
    rtl: false,
  },
  {
    name: 'Gujarati',
    id: 'gu',
    rtl: false,
  },
  {
    name: 'Haitian',
    id: 'ht',
    rtl: false,
  },
  {
    name: 'Hausa',
    id: 'ha',
    rtl: false,
  },
  {
    name: 'Hebrew',
    id: 'he',
    rtl: true,
  },
  {
    name: 'Herero',
    id: 'hz',
    rtl: false,
  },
  {
    name: 'Hindi',
    id: 'hi',
    rtl: false,
  },
  {
    name: 'Hiri Motu',
    id: 'ho',
    rtl: false,
  },
  {
    name: 'Hungarian',
    id: 'hu',
    rtl: false,
  },
  {
    name: 'Icelandic',
    id: 'is',
    rtl: false,
  },
  {
    name: 'Ido',
    id: 'io',
    rtl: false,
  },
  {
    name: 'Igbo',
    id: 'ig',
    rtl: false,
  },
  {
    name: 'Indonesian',
    id: 'id',
    rtl: false,
  },
  {
    name: 'Interlingua',
    id: 'ia',
    rtl: false,
  },
  {
    name: 'Interlingue',
    id: 'ie',
    rtl: false,
  },
  {
    name: 'Inuktitut',
    id: 'iu',
    rtl: false,
  },
  {
    name: 'Inupiaq',
    id: 'ik',
    rtl: false,
  },
  {
    name: 'Irish',
    id: 'ga',
    rtl: false,
  },
  {
    name: 'Italian',
    id: 'it',
    rtl: false,
  },
  {
    name: 'Japanese',
    id: 'ja',
    rtl: false,
  },
  {
    name: 'Javanese',
    id: 'jv',
    rtl: false,
  },
  {
    name: 'Kannada',
    id: 'kn',
    rtl: false,
  },
  {
    name: 'Kanuri',
    id: 'kr',
    rtl: false,
  },
  {
    name: 'Kashmiri',
    id: 'ks',
    rtl: false,
  },
  {
    name: 'Kazakh',
    id: 'kk',
    rtl: false,
  },
  {
    name: 'Central Khmer',
    id: 'km',
    rtl: false,
  },
  {
    name: 'Kikuyu',
    id: 'ki',
    rtl: false,
  },
  {
    name: 'Kinyarwanda',
    id: 'rw',
    rtl: false,
  },
  {
    name: 'Kirghiz',
    id: 'ky',
    rtl: false,
  },
  {
    name: 'Komi',
    id: 'kv',
    rtl: false,
  },
  {
    name: 'Kongo',
    id: 'kg',
    rtl: false,
  },
  {
    name: 'Korean',
    id: 'ko',
    rtl: false,
  },
  {
    name: 'Kuanyama',
    id: 'kj',
    rtl: false,
  },
  {
    name: 'Kurdish',
    id: 'ku',
    rtl: true,
  },
  {
    name: 'Lao',
    id: 'lo',
    rtl: false,
  },
  {
    name: 'Latin',
    id: 'la',
    rtl: false,
  },
  {
    name: 'Latvian',
    id: 'lv',
    rtl: false,
  },
  {
    name: 'Limburgan',
    id: 'li',
    rtl: false,
  },
  {
    name: 'Lingala',
    id: 'ln',
    rtl: false,
  },
  {
    name: 'Lithuanian',
    id: 'lt',
    rtl: false,
  },
  {
    name: 'Luba-Katanga',
    id: 'lu',
    rtl: false,
  },
  {
    name: 'Luxembourgish',
    id: 'lb',
    rtl: false,
  },
  {
    name: 'Macedonian',
    id: 'mk',
    rtl: false,
  },
  {
    name: 'Malagasy',
    id: 'mg',
    rtl: false,
  },
  {
    name: 'Malay',
    id: 'ms',
    rtl: false,
  },
  {
    name: 'Malayalam',
    id: 'ml',
    rtl: false,
  },
  {
    name: 'Maltese',
    id: 'mt',
    rtl: false,
  },
  {
    name: 'Manx',
    id: 'gv',
    rtl: false,
  },
  {
    name: 'Maori',
    id: 'mi',
    rtl: false,
  },
  {
    name: 'Marathi',
    id: 'mr',
    rtl: false,
  },
  {
    name: 'Marshallese',
    id: 'mh',
    rtl: false,
  },
  {
    name: 'Mongolian',
    id: 'mn',
    rtl: false,
  },
  {
    name: 'Nauru',
    id: 'na',
    rtl: false,
  },
  {
    name: 'Navajo',
    id: 'nv',
    rtl: false,
  },
  {
    name: 'North Ndebele',
    id: 'nd',
    rtl: false,
  },
  {
    name: 'South Ndebele',
    id: 'nr',
    rtl: false,
  },
  {
    name: 'Ndonga',
    id: 'ng',
    rtl: false,
  },
  {
    name: 'Nepali',
    id: 'ne',
    rtl: false,
  },
  {
    name: 'Norwegian',
    id: 'no',
    rtl: false,
  },
  {
    name: 'Norwegian Bokmål',
    id: 'nb',
    rtl: false,
  },
  {
    name: 'Norwegian Nynorsk',
    id: 'nn',
    rtl: false,
  },
  {
    name: 'Sichuan Yi',
    id: 'ii',
    rtl: false,
  },
  {
    name: 'Occitan',
    id: 'oc',
    rtl: false,
  },
  {
    name: 'Ojibwa',
    id: 'oj',
    rtl: false,
  },
  {
    name: 'Oriya',
    id: 'or',
    rtl: false,
  },
  {
    name: 'Oromo',
    id: 'om',
    rtl: false,
  },
  {
    name: 'Ossetian',
    id: 'os',
    rtl: false,
  },
  {
    name: 'Pali',
    id: 'pi',
    rtl: false,
  },
  {
    name: 'Pashto, Pushto',
    id: 'ps',
    rtl: false,
  },
  {
    name: 'Persian',
    id: 'fa',
    rtl: true,
  },
  {
    name: 'Polish',
    id: 'pl',
    rtl: false,
  },
  {
    name: 'Portuguese',
    id: 'pt',
    rtl: false,
  },
  {
    name: 'Punjabi',
    id: 'pa',
    rtl: false,
  },
  {
    name: 'Quechua',
    id: 'qu',
    rtl: false,
  },
  {
    name: 'Romanian',
    id: 'ro',
    rtl: false,
  },
  {
    name: 'Romansh',
    id: 'rm',
    rtl: false,
  },
  {
    name: 'Rundi',
    id: 'rn',
    rtl: false,
  },
  {
    name: 'Russian',
    id: 'ru',
    rtl: false,
  },
  {
    name: 'Northern Sami',
    id: 'se',
    rtl: false,
  },
  {
    name: 'Samoan',
    id: 'sm',
    rtl: false,
  },
  {
    name: 'Sango',
    id: 'sg',
    rtl: false,
  },
  {
    name: 'Sanskrit',
    id: 'sa',
    rtl: false,
  },
  {
    name: 'Sardinian',
    id: 'sc',
    rtl: false,
  },
  {
    name: 'Serbian',
    id: 'sr',
    rtl: false,
  },
  {
    name: 'Shona',
    id: 'sn',
    rtl: false,
  },
  {
    name: 'Sindhi',
    id: 'sd',
    rtl: false,
  },
  {
    name: 'Sinhala',
    id: 'si',
    rtl: false,
  },
  {
    name: 'Slovak',
    id: 'sk',
    rtl: false,
  },
  {
    name: 'Slovenian',
    id: 'sl',
    rtl: false,
  },
  {
    name: 'Somali',
    id: 'so',
    rtl: false,
  },
  {
    name: 'Southern Sotho',
    id: 'st',
    rtl: false,
  },
  {
    name: 'Spanish',
    id: 'es',
    rtl: false,
  },
  {
    name: 'Sundanese',
    id: 'su',
    rtl: false,
  },
  {
    name: 'Swahili',
    id: 'sw',
    rtl: false,
  },
  {
    name: 'Swati',
    id: 'ss',
    rtl: false,
  },
  {
    name: 'Swedish',
    id: 'sv',
    rtl: false,
  },
  {
    name: 'Tagalog',
    id: 'tl',
    rtl: false,
  },
  {
    name: 'Tahitian',
    id: 'ty',
    rtl: false,
  },
  {
    name: 'Tajik',
    id: 'tg',
    rtl: false,
  },
  {
    name: 'Tamil',
    id: 'ta',
    rtl: false,
  },
  {
    name: 'Tatar',
    id: 'tt',
    rtl: false,
  },
  {
    name: 'Telugu',
    id: 'te',
    rtl: false,
  },
  {
    name: 'Thai',
    id: 'th',
    rtl: false,
  },
  {
    name: 'Tibetan',
    id: 'bo',
    rtl: false,
  },
  {
    name: 'Tigrinya',
    id: 'ti',
    rtl: false,
  },
  {
    name: 'Tonga',
    id: 'to',
    rtl: false,
  },
  {
    name: 'Tsonga',
    id: 'ts',
    rtl: false,
  },
  {
    name: 'Tswana',
    id: 'tn',
    rtl: false,
  },
  {
    name: 'Turkish',
    id: 'tr',
    rtl: false,
  },
  {
    name: 'Turkmen',
    id: 'tk',
    rtl: false,
  },
  {
    name: 'Twi',
    id: 'tw',
    rtl: false,
  },
  {
    name: 'Uighur',
    id: 'ug',
    rtl: false,
  },
  {
    name: 'Ukrainian',
    id: 'uk',
    rtl: false,
  },
  {
    name: 'Urdu',
    id: 'ur',
    rtl: true,
  },
  {
    name: 'Uzbek',
    id: 'uz',
    rtl: false,
  },
  {
    name: 'Venda',
    id: 've',
    rtl: false,
  },
  {
    name: 'Vietnamese',
    id: 'vi',
    rtl: false,
  },
  {
    name: 'Volapük',
    id: 'vo',
    rtl: false,
  },
  {
    name: 'Walloon',
    id: 'wa',
    rtl: false,
  },
  {
    name: 'Welsh',
    id: 'cy',
    rtl: false,
  },
  {
    name: 'Wolof',
    id: 'wo',
    rtl: false,
  },
  {
    name: 'Xhosa',
    id: 'xh',
    rtl: false,
  },
  {
    name: 'Yiddish',
    id: 'yi',
    rtl: false,
  },
  {
    name: 'Yoruba',
    id: 'yo',
    rtl: false,
  },
  {
    name: 'Zhuang, Chuang',
    id: 'za',
    rtl: false,
  },
  {
    name: 'Zulu',
    id: 'zu',
    rtl: false,
  },
];

export const getLanguageName = (languageCode = '') => {
  const languageObj =
    languages.find(language => language.id === languageCode) || {};
  return languageObj.name || '';
};

export const getLanguageDirection = (languageCode = '') => {
  const languageObj =
    languages.find(language => language.id === languageCode) || {};
  return languageObj.rtl;
};

export default languages;
