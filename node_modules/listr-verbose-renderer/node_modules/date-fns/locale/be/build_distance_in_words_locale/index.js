function buildDistanceInWordsLocale () {
  var distanceInWordsLocale = {
    lessThanXSeconds: {
      one: 'менш секунды',
      other: 'менш {{count}} секунд'
    },

    xSeconds: {
      one: '1 секунда',
      other: '{{count}} секунд(-ы)'
    },

    halfAMinute: 'паўхвіліны',

    lessThanXMinutes: {
      one: 'менш хвіліны',
      other: 'менш {{count}} хвілін'
    },

    xMinutes: {
      one: '1 хвіліна',
      other: '{{count}} хвілін(-ы)'
    },

    aboutXHours: {
      one: 'каля 1 гадзіны',
      other: 'каля {{count}} гадзін'
    },

    xHours: {
      one: '1 гадзіна',
      other: '{{count}} гадзін(-ы)'
    },

    xDays: {
      one: '1 дзень',
      other: '{{count}} дні (дзён)'
    },

    aboutXMonths: {
      one: 'каля 1 месяца',
      other: 'каля {{count}} месяцаў'
    },

    xMonths: {
      one: '1 месяц',
      other: '{{count}} месяцы(-аў)'
    },

    aboutXYears: {
      one: 'каля 1 года',
      other: 'каля {{count}} гадоў'
    },

    xYears: {
      one: '1 год',
      other: '{{count}} гады(гадоў)'
    },

    overXYears: {
      one: 'больш 1 года',
      other: 'больш {{count}} гадоў'
    },

    almostXYears: {
      one: 'амаль 1 год',
      other: 'амаль {{count}} гады(-оў)'
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
        return 'у/праз ' + result
      } else {
        return result + ' таму'
      }
    }

    return result
  }

  return {
    localize: localize
  }
}

module.exports = buildDistanceInWordsLocale
