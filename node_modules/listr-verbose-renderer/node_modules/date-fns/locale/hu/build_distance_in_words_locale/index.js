function buildDistanceInWordsLocale () {
  var distanceInWordsLocale = {
    lessThanXSeconds: {
      one: 'kevesebb, mint egy másodperce',
      other: 'kevesebb, mint {{count}} másodperce'
    },

    xSeconds: {
      one: '1 másodperce',
      other: '{{count}} másodperce'
    },

    halfAMinute: 'fél perce',

    lessThanXMinutes: {
      one: 'kevesebb, mint egy perce',
      other: 'kevesebb, mint {{count}} perce'
    },

    xMinutes: {
      one: '1 perce',
      other: '{{count}} perce'
    },

    aboutXHours: {
      one: 'közel 1 órája',
      other: 'közel {{count}} órája'
    },

    xHours: {
      one: '1 órája',
      other: '{{count}} órája'
    },

    xDays: {
      one: '1 napja',
      other: '{{count}} napja'
    },

    aboutXMonths: {
      one: 'közel 1 hónapja',
      other: 'közel {{count}} hónapja'
    },

    xMonths: {
      one: '1 hónapja',
      other: '{{count}} hónapja'
    },

    aboutXYears: {
      one: 'közel 1 éve',
      other: 'közel {{count}} éve'
    },

    xYears: {
      one: '1 éve',
      other: '{{count}} éve'
    },

    overXYears: {
      one: 'több, mint 1 éve',
      other: 'több, mint {{count}} éve'
    },

    almostXYears: {
      one: 'majdnem 1 éve',
      other: 'majdnem {{count}} éve'
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
        return '' + result
      } else {
        return result + ''
      }
    }

    return result
  }

  return {
    localize: localize
  }
}

module.exports = buildDistanceInWordsLocale
