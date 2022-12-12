function buildDistanceInWordsLocale () {
  function futureSeconds (text) {
    return text.replace(/sekuntia?/, 'sekunnin')
  }

  function futureMinutes (text) {
    return text.replace(/minuuttia?/, 'minuutin')
  }

  function futureHours (text) {
    return text.replace(/tuntia?/, 'tunnin')
  }

  function futureDays (text) {
    return text.replace(/päivää?/, 'päivän')
  }

  function futureMonths (text) {
    return text.replace(/(kuukausi|kuukautta)/, 'kuukauden')
  }

  function futureYears (text) {
    return text.replace(/(vuosi|vuotta)/, 'vuoden')
  }

  var distanceInWordsLocale = {
    lessThanXSeconds: {
      one: 'alle sekunti',
      other: 'alle {{count}} sekuntia',
      futureTense: futureSeconds
    },

    xSeconds: {
      one: 'sekunti',
      other: '{{count}} sekuntia',
      futureTense: futureSeconds
    },

    halfAMinute: {
      one: 'puoli minuuttia',
      other: 'puoli minuuttia',
      futureTense: function (text) {
        return 'puolen minuutin'
      }
    },

    lessThanXMinutes: {
      one: 'alle minuutti',
      other: 'alle {{count}} minuuttia',
      futureTense: futureMinutes
    },

    xMinutes: {
      one: 'minuutti',
      other: '{{count}} minuuttia',
      futureTense: futureMinutes
    },

    aboutXHours: {
      one: 'noin tunti',
      other: 'noin {{count}} tuntia',
      futureTense: futureHours
    },

    xHours: {
      one: 'tunti',
      other: '{{count}} tuntia',
      futureTense: futureHours
    },

    xDays: {
      one: 'päivä',
      other: '{{count}} päivää',
      futureTense: futureDays
    },

    aboutXMonths: {
      one: 'noin kuukausi',
      other: 'noin {{count}} kuukautta',
      futureTense: futureMonths
    },

    xMonths: {
      one: 'kuukausi',
      other: '{{count}} kuukautta',
      futureTense: futureMonths
    },

    aboutXYears: {
      one: 'noin vuosi',
      other: 'noin {{count}} vuotta',
      futureTense: futureYears
    },

    xYears: {
      one: 'vuosi',
      other: '{{count}} vuotta',
      futureTense: futureYears
    },

    overXYears: {
      one: 'yli vuosi',
      other: 'yli {{count}} vuotta',
      futureTense: futureYears
    },

    almostXYears: {
      one: 'lähes vuosi',
      other: 'lähes {{count}} vuotta',
      futureTense: futureYears
    }
  }

  function localize (token, count, options) {
    options = options || {}

    var distance = distanceInWordsLocale[token]
    var result = count === 1 ? distance.one : distance.other.replace('{{count}}', count)

    if (options.addSuffix) {
      if (options.comparison > 0) {
        return distance.futureTense(result) + ' kuluttua'
      } else {
        return result + ' sitten'
      }
    }

    return result
  }

  return {
    localize: localize
  }
}

module.exports = buildDistanceInWordsLocale
