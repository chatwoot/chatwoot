function buildDistanceInWordsLocale () {
  var distanceInWordsLocale = {
    lessThanXSeconds: {
      one: 'bir saniyeden az',
      other: '{{count}} saniyeden az'
    },

    xSeconds: {
      one: '1 saniye',
      other: '{{count}} saniye'
    },

    halfAMinute: 'yarım dakika',

    lessThanXMinutes: {
      one: 'bir dakikadan az',
      other: '{{count}} dakikadan az'
    },

    xMinutes: {
      one: '1 dakika',
      other: '{{count}} dakika'
    },

    aboutXHours: {
      one: 'yaklaşık 1 saat',
      other: 'yaklaşık {{count}} saat'
    },

    xHours: {
      one: '1 saat',
      other: '{{count}} saat'
    },

    xDays: {
      one: '1 gün',
      other: '{{count}} gün'
    },

    aboutXMonths: {
      one: 'yaklaşık 1 ay',
      other: 'yaklaşık {{count}} ay'
    },

    xMonths: {
      one: '1 ay',
      other: '{{count}} ay'
    },

    aboutXYears: {
      one: 'yaklaşık 1 yıl',
      other: 'yaklaşık {{count}} yıl'
    },

    xYears: {
      one: '1 yıl',
      other: '{{count}} yıl'
    },

    overXYears: {
      one: '1 yıldan fazla',
      other: '{{count}} yıldan fazla'
    },

    almostXYears: {
      one: 'neredeyse 1 yıl',
      other: 'neredeyse {{count}} yıl'
    }
  }

  var extraWordTokens = [
    'lessThanXSeconds',
    'lessThanXMinutes',
    'overXYears'
  ]

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
      var extraWord = ''
      if (extraWordTokens.indexOf(token) > -1) {
        extraWord = ' bir süre'
      }

      if (options.comparison > 0) {
        return result + extraWord + ' içinde'
      } else {
        return result + extraWord + ' önce'
      }
    }

    return result
  }

  return {
    localize: localize
  }
}

module.exports = buildDistanceInWordsLocale
