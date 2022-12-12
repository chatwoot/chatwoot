function buildDistanceInWordsLocale () {
  var distanceInWordsLocale = {
    lessThanXSeconds: {
      one: 'manje od sekunde',
      other: 'manje od {{count}} sekundi'
    },

    xSeconds: {
      one: '1 sekund',
      other: '{{count}} sekunde'
    },

    halfAMinute: 'pola minuta',

    lessThanXMinutes: {
      one: 'manje od minute',
      other: 'manje od {{count}} minuta'
    },

    xMinutes: {
      one: '1 minut',
      other: '{{count}} minute'
    },

    aboutXHours: {
      one: 'oko 1 sat',
      other: 'oko {{count}} sata'
    },

    xHours: {
      one: '1 sat',
      other: '{{count}} sati'
    },

    xDays: {
      one: '1 dan',
      other: '{{count}} dani'
    },

    aboutXMonths: {
      one: 'oko 1 mesec',
      other: 'oko {{count}} meseca'
    },

    xMonths: {
      one: '1 mesec',
      other: '{{count}} meseci'
    },

    aboutXYears: {
      one: 'oko 1 godine',
      other: 'oko {{count}} godina'
    },

    xYears: {
      one: '1 godina',
      other: '{{count}} godine'
    },

    overXYears: {
      one: 'više od 1 godine',
      other: 'više od {{count}} godina'
    },

    almostXYears: {
      one: 'skoro 1 godinu',
      other: 'skoro {{count}} godina'
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
        return 'za ' + result
      } else {
        return result + ' pre'
      }
    }

    return result
  }

  return {
    localize: localize
  }
}

module.exports = buildDistanceInWordsLocale
