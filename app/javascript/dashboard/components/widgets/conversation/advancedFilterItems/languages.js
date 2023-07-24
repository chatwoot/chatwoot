const languages = [
  {
    name: 'Abkhazian',
    id: 'ab',
  },
  {
    name: 'Afar',
    id: 'aa',
  },
  {
    name: 'Afrikaans',
    id: 'af',
  },
  {
    name: 'Akan',
    id: 'ak',
  },
  {
    name: 'Albanian',
    id: 'sq',
  },
  {
    name: 'Amharic',
    id: 'am',
  },
  {
    name: 'Arabic',
    id: 'ar',
  },
  {
    name: 'Aragonese',
    id: 'an',
  },
  {
    name: 'Armenian',
    id: 'hy',
  },
  {
    name: 'Assamese',
    id: 'as',
  },
  {
    name: 'Avaric',
    id: 'av',
  },
  {
    name: 'Avestan',
    id: 'ae',
  },
  {
    name: 'Aymara',
    id: 'ay',
  },
  {
    name: 'Azerbaijani',
    id: 'az',
  },
  {
    name: 'Bambara',
    id: 'bm',
  },
  {
    name: 'Bashkir',
    id: 'ba',
  },
  {
    name: 'Basque',
    id: 'eu',
  },
  {
    name: 'Belarusian',
    id: 'be',
  },
  {
    name: 'Bengali',
    id: 'bn',
  },
  {
    name: 'Bislama',
    id: 'bi',
  },
  {
    name: 'Bosnian',
    id: 'bs',
  },
  {
    name: 'Breton',
    id: 'br',
  },
  {
    name: 'Bulgarian',
    id: 'bg',
  },
  {
    name: 'Burmese',
    id: 'my',
  },
  {
    name: 'Catalan',
    id: 'ca',
  },
  {
    name: 'Chamorro',
    id: 'ch',
  },
  {
    name: 'Chechen',
    id: 'ce',
  },
  {
    name: 'Chichewa',
    id: 'ny',
  },
  {
    name: 'Chinese',
    id: 'zh',
  },
  {
    name: 'Church Slavonic',
    id: 'cu',
  },
  {
    name: 'Chuvash',
    id: 'cv',
  },
  {
    name: 'Cornish',
    id: 'kw',
  },
  {
    name: 'Corsican',
    id: 'co',
  },
  {
    name: 'Cree',
    id: 'cr',
  },
  {
    name: 'Croatian',
    id: 'hr',
  },
  {
    name: 'Czech',
    id: 'cs',
  },
  {
    name: 'Danish',
    id: 'da',
  },
  {
    name: 'Divehi',
    id: 'dv',
  },
  {
    name: 'Dutch',
    id: 'nl',
  },
  {
    name: 'Dzongkha',
    id: 'dz',
  },
  {
    name: 'English',
    id: 'en',
  },
  {
    name: 'Esperanto',
    id: 'eo',
  },
  {
    name: 'Estonian',
    id: 'et',
  },
  {
    name: 'Ewe',
    id: 'ee',
  },
  {
    name: 'Faroese',
    id: 'fo',
  },
  {
    name: 'Fijian',
    id: 'fj',
  },
  {
    name: 'Finnish',
    id: 'fi',
  },
  {
    name: 'French',
    id: 'fr',
  },
  {
    name: 'Western Frisian',
    id: 'fy',
  },
  {
    name: 'Fulah',
    id: 'ff',
  },
  {
    name: 'Gaelic',
    id: 'gd',
  },
  {
    name: 'Galician',
    id: 'gl',
  },
  {
    name: 'Ganda',
    id: 'lg',
  },
  {
    name: 'Georgian',
    id: 'ka',
  },
  {
    name: 'German',
    id: 'de',
  },
  {
    name: 'Greek',
    id: 'el',
  },
  {
    name: 'Kalaallisut',
    id: 'kl',
  },
  {
    name: 'Guarani',
    id: 'gn',
  },
  {
    name: 'Gujarati',
    id: 'gu',
  },
  {
    name: 'Haitian',
    id: 'ht',
  },
  {
    name: 'Hausa',
    id: 'ha',
  },
  {
    name: 'Hebrew',
    id: 'he',
  },
  {
    name: 'Herero',
    id: 'hz',
  },
  {
    name: 'Hindi',
    id: 'hi',
  },
  {
    name: 'Hiri Motu',
    id: 'ho',
  },
  {
    name: 'Hungarian',
    id: 'hu',
  },
  {
    name: 'Icelandic',
    id: 'is',
  },
  {
    name: 'Ido',
    id: 'io',
  },
  {
    name: 'Igbo',
    id: 'ig',
  },
  {
    name: 'Indonesian',
    id: 'id',
  },
  {
    name: 'Interlingua',
    id: 'ia',
  },
  {
    name: 'Interlingue',
    id: 'ie',
  },
  {
    name: 'Inuktitut',
    id: 'iu',
  },
  {
    name: 'Inupiaq',
    id: 'ik',
  },
  {
    name: 'Irish',
    id: 'ga',
  },
  {
    name: 'Italian',
    id: 'it',
  },
  {
    name: 'Japanese',
    id: 'ja',
  },
  {
    name: 'Javanese',
    id: 'jv',
  },
  {
    name: 'Kannada',
    id: 'kn',
  },
  {
    name: 'Kanuri',
    id: 'kr',
  },
  {
    name: 'Kashmiri',
    id: 'ks',
  },
  {
    name: 'Kazakh',
    id: 'kk',
  },
  {
    name: 'Central Khmer',
    id: 'km',
  },
  {
    name: 'Kikuyu',
    id: 'ki',
  },
  {
    name: 'Kinyarwanda',
    id: 'rw',
  },
  {
    name: 'Kirghiz',
    id: 'ky',
  },
  {
    name: 'Komi',
    id: 'kv',
  },
  {
    name: 'Kongo',
    id: 'kg',
  },
  {
    name: 'Korean',
    id: 'ko',
  },
  {
    name: 'Kuanyama',
    id: 'kj',
  },
  {
    name: 'Kurdish',
    id: 'ku',
  },
  {
    name: 'Lao',
    id: 'lo',
  },
  {
    name: 'Latin',
    id: 'la',
  },
  {
    name: 'Latvian',
    id: 'lv',
  },
  {
    name: 'Limburgan',
    id: 'li',
  },
  {
    name: 'Lingala',
    id: 'ln',
  },
  {
    name: 'Lithuanian',
    id: 'lt',
  },
  {
    name: 'Luba-Katanga',
    id: 'lu',
  },
  {
    name: 'Luxembourgish',
    id: 'lb',
  },
  {
    name: 'Macedonian',
    id: 'mk',
  },
  {
    name: 'Malagasy',
    id: 'mg',
  },
  {
    name: 'Malay',
    id: 'ms',
  },
  {
    name: 'Malayalam',
    id: 'ml',
  },
  {
    name: 'Maltese',
    id: 'mt',
  },
  {
    name: 'Manx',
    id: 'gv',
  },
  {
    name: 'Maori',
    id: 'mi',
  },
  {
    name: 'Marathi',
    id: 'mr',
  },
  {
    name: 'Marshallese',
    id: 'mh',
  },
  {
    name: 'Mongolian',
    id: 'mn',
  },
  {
    name: 'Nauru',
    id: 'na',
  },
  {
    name: 'Navajo',
    id: 'nv',
  },
  {
    name: 'North Ndebele',
    id: 'nd',
  },
  {
    name: 'South Ndebele',
    id: 'nr',
  },
  {
    name: 'Ndonga',
    id: 'ng',
  },
  {
    name: 'Nepali',
    id: 'ne',
  },
  {
    name: 'Norwegian',
    id: 'no',
  },
  {
    name: 'Norwegian Bokmål',
    id: 'nb',
  },
  {
    name: 'Norwegian Nynorsk',
    id: 'nn',
  },
  {
    name: 'Sichuan Yi',
    id: 'ii',
  },
  {
    name: 'Occitan',
    id: 'oc',
  },
  {
    name: 'Ojibwa',
    id: 'oj',
  },
  {
    name: 'Oriya',
    id: 'or',
  },
  {
    name: 'Oromo',
    id: 'om',
  },
  {
    name: 'Ossetian',
    id: 'os',
  },
  {
    name: 'Pali',
    id: 'pi',
  },
  {
    name: 'Pashto, Pushto',
    id: 'ps',
  },
  {
    name: 'Persian',
    id: 'fa',
  },
  {
    name: 'Polish',
    id: 'pl',
  },
  {
    name: 'Portuguese',
    id: 'pt',
  },
  {
    name: 'Punjabi',
    id: 'pa',
  },
  {
    name: 'Quechua',
    id: 'qu',
  },
  {
    name: 'Romanian',
    id: 'ro',
  },
  {
    name: 'Romansh',
    id: 'rm',
  },
  {
    name: 'Rundi',
    id: 'rn',
  },
  {
    name: 'Russian',
    id: 'ru',
  },
  {
    name: 'Northern Sami',
    id: 'se',
  },
  {
    name: 'Samoan',
    id: 'sm',
  },
  {
    name: 'Sango',
    id: 'sg',
  },
  {
    name: 'Sanskrit',
    id: 'sa',
  },
  {
    name: 'Sardinian',
    id: 'sc',
  },
  {
    name: 'Serbian',
    id: 'sr',
  },
  {
    name: 'Shona',
    id: 'sn',
  },
  {
    name: 'Sindhi',
    id: 'sd',
  },
  {
    name: 'Sinhala',
    id: 'si',
  },
  {
    name: 'Slovak',
    id: 'sk',
  },
  {
    name: 'Slovenian',
    id: 'sl',
  },
  {
    name: 'Somali',
    id: 'so',
  },
  {
    name: 'Southern Sotho',
    id: 'st',
  },
  {
    name: 'Spanish',
    id: 'es',
  },
  {
    name: 'Sundanese',
    id: 'su',
  },
  {
    name: 'Swahili',
    id: 'sw',
  },
  {
    name: 'Swati',
    id: 'ss',
  },
  {
    name: 'Swedish',
    id: 'sv',
  },
  {
    name: 'Tagalog',
    id: 'tl',
  },
  {
    name: 'Tahitian',
    id: 'ty',
  },
  {
    name: 'Tajik',
    id: 'tg',
  },
  {
    name: 'Tamil',
    id: 'ta',
  },
  {
    name: 'Tatar',
    id: 'tt',
  },
  {
    name: 'Telugu',
    id: 'te',
  },
  {
    name: 'Thai',
    id: 'th',
  },
  {
    name: 'Tibetan',
    id: 'bo',
  },
  {
    name: 'Tigrinya',
    id: 'ti',
  },
  {
    name: 'Tonga',
    id: 'to',
  },
  {
    name: 'Tsonga',
    id: 'ts',
  },
  {
    name: 'Tswana',
    id: 'tn',
  },
  {
    name: 'Turkish',
    id: 'tr',
  },
  {
    name: 'Turkmen',
    id: 'tk',
  },
  {
    name: 'Twi',
    id: 'tw',
  },
  {
    name: 'Uighur',
    id: 'ug',
  },
  {
    name: 'Ukrainian',
    id: 'uk',
  },
  {
    name: 'Urdu',
    id: 'ur',
  },
  {
    name: 'Uzbek',
    id: 'uz',
  },
  {
    name: 'Venda',
    id: 've',
  },
  {
    name: 'Vietnamese',
    id: 'vi',
  },
  {
    name: 'Volapük',
    id: 'vo',
  },
  {
    name: 'Walloon',
    id: 'wa',
  },
  {
    name: 'Welsh',
    id: 'cy',
  },
  {
    name: 'Wolof',
    id: 'wo',
  },
  {
    name: 'Xhosa',
    id: 'xh',
  },
  {
    name: 'Yiddish',
    id: 'yi',
  },
  {
    name: 'Yoruba',
    id: 'yo',
  },
  {
    name: 'Zhuang, Chuang',
    id: 'za',
  },
  {
    name: 'Zulu',
    id: 'zu',
  },
];

export const getLanguageName = (languageCode = '') => {
  const languageObj =
    languages.find(language => language.id === languageCode) || {};
  return languageObj.name || '';
};

export const getLanguageDirection = (languageCode = '') => {
  const rtlLanguageIds = ['ar', 'as', 'fa', 'he', 'ku', 'ur'];
  return rtlLanguageIds.includes(languageCode);
};

export default languages;
