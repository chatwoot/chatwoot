function buildDistanceInWordsLocale () {
  var distanceInWordsLocale = {
    lessThanXSeconds: {
      one: 'mas maliit sa isang segundo',
      other: 'mas maliit sa {{count}} segundo'
    },

    xSeconds: {
      one: '1 segundo',
      other: '{{count}} segundo'
    },

    halfAMinute: 'kalahating minuto',

    lessThanXMinutes: {
      one: 'mas maliit sa isang minuto',
      other: 'mas maliit sa {{count}} minuto'
    },

    xMinutes: {
      one: '1 minuto',
      other: '{{count}} minuto'
    },

    aboutXHours: {
      one: 'mga 1 oras',
      other: 'mga {{count}} oras'
    },

    xHours: {
      one: '1 oras',
      other: '{{count}} oras'
    },

    xDays: {
      one: '1 araw',
      other: '{{count}} araw'
    },

    aboutXMonths: {
      one: 'mga 1 buwan',
      other: 'mga {{count}} buwan'
    },

    xMonths: {
      one: '1 buwan',
      other: '{{count}} buwan'
    },

    aboutXYears: {
      one: 'mga 1 taon',
      other: 'mga {{count}} taon'
    },

    xYears: {
      one: '1 taon',
      other: '{{count}} taon'
    },

    overXYears: {
      one: 'higit sa 1 taon',
      other: 'higit sa {{count}} taon'
    },

    almostXYears: {
      one: 'halos 1 taon',
      other: 'halos {{count}} taon'
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
        return 'sa loob ng ' + result
      } else {
        return result + ' ang nakalipas'
      }
    }

    return result
  }

  return {
    localize: localize
  }
}

module.exports = buildDistanceInWordsLocale
