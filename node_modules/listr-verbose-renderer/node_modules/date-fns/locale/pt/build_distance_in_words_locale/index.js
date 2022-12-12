function buildDistanceInWordsLocale () {
  var distanceInWordsLocale = {
    lessThanXSeconds: {
      one: 'menos de um segundo',
      other: 'menos de {{count}} segundos'
    },

    xSeconds: {
      one: '1 segundo',
      other: '{{count}} segundos'
    },

    halfAMinute: 'meio minuto',

    lessThanXMinutes: {
      one: 'menos de um minuto',
      other: 'menos de {{count}} minutos'
    },

    xMinutes: {
      one: '1 minuto',
      other: '{{count}} minutos'
    },

    aboutXHours: {
      one: 'aproximadamente 1 hora',
      other: 'aproximadamente {{count}} horas'
    },

    xHours: {
      one: '1 hora',
      other: '{{count}} horas'
    },

    xDays: {
      one: '1 dia',
      other: '{{count}} dias'
    },

    aboutXMonths: {
      one: 'aproximadamente 1 mês',
      other: 'aproximadamente {{count}} meses'
    },

    xMonths: {
      one: '1 mês',
      other: '{{count}} meses'
    },

    aboutXYears: {
      one: 'aproximadamente 1 ano',
      other: 'aproximadamente {{count}} anos'
    },

    xYears: {
      one: '1 ano',
      other: '{{count}} anos'
    },

    overXYears: {
      one: 'mais de 1 ano',
      other: 'mais de {{count}} anos'
    },

    almostXYears: {
      one: 'quase 1 ano',
      other: 'quase {{count}} anos'
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
        return 'daqui a ' + result
      } else {
        return 'há ' + result
      }
    }

    return result
  }

  return {
    localize: localize
  }
}

module.exports = buildDistanceInWordsLocale
