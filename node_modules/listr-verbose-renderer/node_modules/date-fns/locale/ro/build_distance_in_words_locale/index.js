function buildDistanceInWordsLocale () {
  var distanceInWordsLocale = {
    lessThanXSeconds: {
      one: 'mai puțin de o secundă',
      other: 'mai puțin de {{count}} secunde'
    },

    xSeconds: {
      one: '1 secundă',
      other: '{{count}} secunde'
    },

    halfAMinute: 'jumătate de minut',

    lessThanXMinutes: {
      one: 'mai puțin de un minut',
      other: 'mai puțin de {{count}} minute'
    },

    xMinutes: {
      one: '1 minut',
      other: '{{count}} minute'
    },

    aboutXHours: {
      one: 'circa 1 oră',
      other: 'circa {{count}} ore'
    },

    xHours: {
      one: '1 oră',
      other: '{{count}} ore'
    },

    xDays: {
      one: '1 zi',
      other: '{{count}} zile'
    },

    aboutXMonths: {
      one: 'circa 1 lună',
      other: 'circa {{count}} luni'
    },

    xMonths: {
      one: '1 lună',
      other: '{{count}} luni'
    },

    aboutXYears: {
      one: 'circa 1 an',
      other: 'circa {{count}} ani'
    },

    xYears: {
      one: '1 an',
      other: '{{count}} ani'
    },

    overXYears: {
      one: 'peste 1 an',
      other: 'peste {{count}} ani'
    },

    almostXYears: {
      one: 'aproape 1 an',
      other: 'aproape {{count}} ani'
    }
  }

  function localize (token, count, options) {
    options = options || {}

    var result
    if (typeof distanceInWordsLocale[token] === 'string') {
      result = distanceInWordsLocale[token]
    } else if (count === 1) {
      result = distanceInWordsLocale[token].one
    } else {
      result = distanceInWordsLocale[token].other.replace('{{count}}', count)
    }

    if (options.addSuffix) {
      if (options.comparison > 0) {
        return 'în ' + result
      } else {
        return result + ' în urmă'
      }
    }

    return result
  }

  return {
    localize: localize
  }
}

module.exports = buildDistanceInWordsLocale
