function buildDistanceInWordsLocale () {
  var distanceInWordsLocale = {
    lessThanXSeconds: {
      one: 'mindre end et sekund',
      other: 'mindre end {{count}} sekunder'
    },

    xSeconds: {
      one: '1 sekund',
      other: '{{count}} sekunder'
    },

    halfAMinute: 'et halvt minut',

    lessThanXMinutes: {
      one: 'mindre end et minut',
      other: 'mindre end {{count}} minutter'
    },

    xMinutes: {
      one: '1 minut',
      other: '{{count}} minutter'
    },

    aboutXHours: {
      one: 'cirka 1 time',
      other: 'cirka {{count}} timer'
    },

    xHours: {
      one: '1 time',
      other: '{{count}} timer'
    },

    xDays: {
      one: '1 dag',
      other: '{{count}} dage'
    },

    aboutXMonths: {
      one: 'cirka 1 måned',
      other: 'cirka {{count}} måneder'
    },

    xMonths: {
      one: '1 måned',
      other: '{{count}} måneder'
    },

    aboutXYears: {
      one: 'cirka 1 år',
      other: 'cirka {{count}} år'
    },

    xYears: {
      one: '1 år',
      other: '{{count}} år'
    },

    overXYears: {
      one: 'over 1 år',
      other: 'over {{count}} år'
    },

    almostXYears: {
      one: 'næsten 1 år',
      other: 'næsten {{count}} år'
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
        return 'om ' + result
      } else {
        return result + ' siden'
      }
    }

    return result
  }

  return {
    localize: localize
  }
}

module.exports = buildDistanceInWordsLocale
