function buildDistanceInWordsLocale () {
  var distanceInWordsLocale = {
    lessThanXSeconds: {
      one: 'по-малко от секунда',
      other: 'по-малко от {{count}} секунди'
    },

    xSeconds: {
      one: '1 секунда',
      other: '{{count}} секунди'
    },

    halfAMinute: 'половин минута',

    lessThanXMinutes: {
      one: 'по-малко от минута',
      other: 'по-малко от {{count}} минути'
    },

    xMinutes: {
      one: '1 минута',
      other: '{{count}} минути'
    },

    aboutXHours: {
      one: 'около час',
      other: 'около {{count}} часа'
    },

    xHours: {
      one: '1 час',
      other: '{{count}} часа'
    },

    xDays: {
      one: '1 ден',
      other: '{{count}} дни'
    },

    aboutXMonths: {
      one: 'около месец',
      other: 'около {{count}} месеца'
    },

    xMonths: {
      one: '1 месец',
      other: '{{count}} месеца'
    },

    aboutXYears: {
      one: 'около година',
      other: 'около {{count}} години'
    },

    xYears: {
      one: '1 година',
      other: '{{count}} години'
    },

    overXYears: {
      one: 'над година',
      other: 'над {{count}} години'
    },

    almostXYears: {
      one: 'почти година',
      other: 'почти {{count}} години'
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
        return 'след ' + result
      } else {
        return 'преди ' + result
      }
    }

    return result
  }

  return {
    localize: localize
  }
}

module.exports = buildDistanceInWordsLocale
