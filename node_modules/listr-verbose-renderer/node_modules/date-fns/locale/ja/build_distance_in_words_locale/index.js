function buildDistanceInWordsLocale () {
  var distanceInWordsLocale = {
    lessThanXSeconds: {
      one: '1秒以下',
      other: '{{count}}秒以下'
    },

    xSeconds: {
      one: '1秒',
      other: '{{count}}秒'
    },

    halfAMinute: '30秒ぐらい',

    lessThanXMinutes: {
      one: '1分以下',
      other: '{{count}}分以下'
    },

    xMinutes: {
      one: '1分',
      other: '{{count}}分'
    },

    aboutXHours: {
      one: '1時間ぐらい',
      other: '{{count}}時間ぐらい'
    },

    xHours: {
      one: '1時間',
      other: '{{count}}時間'
    },

    xDays: {
      one: '1日',
      other: '{{count}}日'
    },

    aboutXMonths: {
      one: '1ヶ月ぐらい',
      other: '{{count}}ヶ月ぐらい'
    },

    xMonths: {
      one: '1ヶ月',
      other: '{{count}}ヶ月'
    },

    aboutXYears: {
      one: '1年ぐらい',
      other: '{{count}}年ぐらい'
    },

    xYears: {
      one: '1年',
      other: '{{count}}年'
    },

    overXYears: {
      one: '1年以上',
      other: '{{count}}年以上'
    },

    almostXYears: {
      one: '1年以下',
      other: '{{count}}年以下',
      oneWithSuffix: '1年ぐらい',
      otherWithSuffix: '{{count}}年ぐらい'
    }
  }

  function localize (token, count, options) {
    options = options || {}

    var result
    if (typeof distanceInWordsLocale[token] === 'string') {
      result = distanceInWordsLocale[token]
    } else if (count === 1) {
      if (options.addSuffix && distanceInWordsLocale[token].oneWithSuffix) {
        result = distanceInWordsLocale[token].oneWithSuffix
      } else {
        result = distanceInWordsLocale[token].one
      }
    } else {
      if (options.addSuffix && distanceInWordsLocale[token].otherWithSuffix) {
        result = distanceInWordsLocale[token].otherWithSuffix.replace('{{count}}', count)
      } else {
        result = distanceInWordsLocale[token].other.replace('{{count}}', count)
      }
    }

    if (options.addSuffix) {
      if (options.comparison > 0) {
        return result + '後'
      } else {
        return result + '前'
      }
    }

    return result
  }

  return {
    localize: localize
  }
}

module.exports = buildDistanceInWordsLocale
