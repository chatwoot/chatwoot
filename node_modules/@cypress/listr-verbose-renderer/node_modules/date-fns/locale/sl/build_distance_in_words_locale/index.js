function buildDistanceInWordsLocale () {
  var distanceInWordsLocale = {
    lessThanXSeconds: {
      one: 'manj kot sekunda',
      two: 'manj kot 2 sekundi',
      three: 'manj kot {{count}} sekunde',
      other: 'manj kot {{count}} sekund'
    },

    xSeconds: {
      one: '1 sekunda',
      two: '2 sekundi',
      three: '{{count}} sekunde',
      other: '{{count}} sekund'
    },

    halfAMinute: 'pol minute',

    lessThanXMinutes: {
      one: 'manj kot minuta',
      two: 'manj kot 2 minuti',
      three: 'manj kot {{count}} minute',
      other: 'manj kot {{count}} minut'
    },

    xMinutes: {
      one: '1 minuta',
      two: '2 minuti',
      three: '{{count}} minute',
      other: '{{count}} minut'
    },

    aboutXHours: {
      one: 'približno 1 ura',
      two: 'približno 2 uri',
      three: 'približno {{count}} ure',
      other: 'približno {{count}} ur'
    },

    xHours: {
      one: '1 ura',
      two: '2 uri',
      three: '{{count}} ure',
      other: '{{count}} ur'
    },

    xDays: {
      one: '1 dan',
      two: '2 dni',
      three: '{{count}} dni',
      other: '{{count}} dni'
    },

    aboutXMonths: {
      one: 'približno 1 mesec',
      two: 'približno 2 meseca',
      three: 'približno {{count}} mesece',
      other: 'približno {{count}} mesecev'
    },

    xMonths: {
      one: '1 mesec',
      two: '2 meseca',
      three: '{{count}} meseci',
      other: '{{count}} mesecev'
    },

    aboutXYears: {
      one: 'približno 1 leto',
      two: 'približno 2 leti',
      three: 'približno {{count}} leta',
      other: 'približno {{count}} let'
    },

    xYears: {
      one: '1 leto',
      two: '2 leti',
      three: '{{count}} leta',
      other: '{{count}} let'
    },

    overXYears: {
      one: 'več kot 1 leto',
      two: 'več kot 2 leti',
      three: 'več kot {{count}} leta',
      other: 'več kot {{count}} let'
    },

    almostXYears: {
      one: 'skoraj 1 leto',
      two: 'skoraj 2 leti',
      three: 'skoraj {{count}} leta',
      other: 'skoraj {{count}} let'
    }
  }

  function localize (token, count, options) {
    options = options || {}

    var result
    if (typeof distanceInWordsLocale[token] === 'string') {
      result = distanceInWordsLocale[token]
    } else if (count === 1) {
      result = distanceInWordsLocale[token].one
    } else if (count === 2) {
      result = distanceInWordsLocale[token].two
    } else if (count === 3 || count === 4) {
      result = distanceInWordsLocale[token].three.replace('{{count}}', count)
    } else {
      result = distanceInWordsLocale[token].other.replace('{{count}}', count)
    }

    if (options.addSuffix) {
      result = result.replace(/(minut|sekund|ur)(a)/, '$1o')
      if (token === 'xMonths') {
        result = result.replace(/(mesec)(i)/, '$1e')
      }
      if (options.comparison > 0) {
        return 'čez ' + result
      } else {
        return result + ' nazaj'
      }
    }

    return result
  }

  return {
    localize: localize
  }
}

module.exports = buildDistanceInWordsLocale
