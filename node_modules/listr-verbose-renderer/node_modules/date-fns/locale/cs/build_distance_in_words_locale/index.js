function declensionGroup (scheme, count) {
  if (count === 1) {
    return scheme.one
  }

  if (count >= 2 && count <= 4) {
    return scheme.twoFour
  }

  // if count === null || count === 0 || count >= 5
  return scheme.other
}

function declension (scheme, count, time) {
  var group = declensionGroup(scheme, count)
  var finalText = group[time] || group
  return finalText.replace('{{count}}', count)
}

function extractPreposition (token) {
  var result = ['lessThan', 'about', 'over', 'almost'].filter(function (preposition) {
    return !!token.match(new RegExp('^' + preposition))
  })

  return result[0]
}

function prefixPreposition (preposition) {
  var translation = ''

  if (preposition === 'almost') {
    translation = 'skoro'
  }

  if (preposition === 'about') {
    translation = 'přibližně'
  }

  return translation.length > 0 ? translation + ' ' : ''
}

function suffixPreposition (preposition) {
  var translation = ''

  if (preposition === 'lessThan') {
    translation = 'méně než'
  }

  if (preposition === 'over') {
    translation = 'více než'
  }

  return translation.length > 0 ? translation + ' ' : ''
}

function lowercaseFirstLetter (string) {
  return string.charAt(0).toLowerCase() + string.slice(1)
}

function buildDistanceInWordsLocale () {
  var distanceInWordsLocale = {
    xSeconds: {
      one: {
        regular: 'vteřina',
        past: 'vteřinou',
        future: 'vteřinu'
      },
      twoFour: {
        regular: '{{count}} vteřiny',
        past: '{{count}} vteřinami',
        future: '{{count}} vteřiny'
      },
      other: {
        regular: '{{count}} vteřin',
        past: '{{count}} vteřinami',
        future: '{{count}} vteřin'
      }
    },

    halfAMinute: {
      other: {
        regular: 'půl minuty',
        past: 'půl minutou',
        future: 'půl minuty'
      }
    },

    xMinutes: {
      one: {
        regular: 'minuta',
        past: 'minutou',
        future: 'minutu'
      },
      twoFour: {
        regular: '{{count}} minuty',
        past: '{{count}} minutami',
        future: '{{count}} minuty'
      },
      other: {
        regular: '{{count}} minut',
        past: '{{count}} minutami',
        future: '{{count}} minut'
      }
    },

    xHours: {
      one: {
        regular: 'hodina',
        past: 'hodinou',
        future: 'hodinu'
      },
      twoFour: {
        regular: '{{count}} hodiny',
        past: '{{count}} hodinami',
        future: '{{count}} hodiny'
      },
      other: {
        regular: '{{count}} hodin',
        past: '{{count}} hodinami',
        future: '{{count}} hodin'
      }
    },

    xDays: {
      one: {
        regular: 'den',
        past: 'dnem',
        future: 'den'
      },
      twoFour: {
        regular: '{{count}} dni',
        past: '{{count}} dny',
        future: '{{count}} dni'
      },
      other: {
        regular: '{{count}} dní',
        past: '{{count}} dny',
        future: '{{count}} dní'
      }
    },

    xMonths: {
      one: {
        regular: 'měsíc',
        past: 'měsícem',
        future: 'měsíc'
      },
      twoFour: {
        regular: '{{count}} měsíce',
        past: '{{count}} měsíci',
        future: '{{count}} měsíce'
      },
      other: {
        regular: '{{count}} měsíců',
        past: '{{count}} měsíci',
        future: '{{count}} měsíců'
      }
    },

    xYears: {
      one: {
        regular: 'rok',
        past: 'rokem',
        future: 'rok'
      },
      twoFour: {
        regular: '{{count}} roky',
        past: '{{count}} roky',
        future: '{{count}} roky'
      },
      other: {
        regular: '{{count}} roků',
        past: '{{count}} roky',
        future: '{{count}} roků'
      }
    }
  }

  function localize (token, count, options) {
    options = options || {}

    var preposition = extractPreposition(token) || ''
    var key = lowercaseFirstLetter(token.substring(preposition.length))
    var scheme = distanceInWordsLocale[key]

    if (!options.addSuffix) {
      return prefixPreposition(preposition) + suffixPreposition(preposition) + declension(scheme, count, 'regular')
    }

    if (options.comparison > 0) {
      return prefixPreposition(preposition) + 'za ' + suffixPreposition(preposition) + declension(scheme, count, 'future')
    } else {
      return prefixPreposition(preposition) + 'před ' + suffixPreposition(preposition) + declension(scheme, count, 'past')
    }
  }

  return {
    localize: localize
  }
}

module.exports = buildDistanceInWordsLocale
