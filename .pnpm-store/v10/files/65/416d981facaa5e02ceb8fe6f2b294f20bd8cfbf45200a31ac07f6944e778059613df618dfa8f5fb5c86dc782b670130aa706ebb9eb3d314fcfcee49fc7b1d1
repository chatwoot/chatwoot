var formatDistanceLocale = {
  lessThanXSeconds: {
    one: 'meno di un secondo',
    other: 'meno di {{count}} secondi'
  },
  xSeconds: {
    one: 'un secondo',
    other: '{{count}} secondi'
  },
  halfAMinute: 'alcuni secondi',
  lessThanXMinutes: {
    one: 'meno di un minuto',
    other: 'meno di {{count}} minuti'
  },
  xMinutes: {
    one: 'un minuto',
    other: '{{count}} minuti'
  },
  aboutXHours: {
    one: "circa un'ora",
    other: 'circa {{count}} ore'
  },
  xHours: {
    one: "un'ora",
    other: '{{count}} ore'
  },
  xDays: {
    one: 'un giorno',
    other: '{{count}} giorni'
  },
  aboutXWeeks: {
    one: 'circa una settimana',
    other: 'circa {{count}} settimane'
  },
  xWeeks: {
    one: 'una settimana',
    other: '{{count}} settimane'
  },
  aboutXMonths: {
    one: 'circa un mese',
    other: 'circa {{count}} mesi'
  },
  xMonths: {
    one: 'un mese',
    other: '{{count}} mesi'
  },
  aboutXYears: {
    one: 'circa un anno',
    other: 'circa {{count}} anni'
  },
  xYears: {
    one: 'un anno',
    other: '{{count}} anni'
  },
  overXYears: {
    one: 'più di un anno',
    other: 'più di {{count}} anni'
  },
  almostXYears: {
    one: 'quasi un anno',
    other: 'quasi {{count}} anni'
  }
};
export default function formatDistance(token, count, options) {
  options = options || {};
  var result;

  if (typeof formatDistanceLocale[token] === 'string') {
    result = formatDistanceLocale[token];
  } else if (count === 1) {
    result = formatDistanceLocale[token].one;
  } else {
    result = formatDistanceLocale[token].other.replace('{{count}}', count);
  }

  if (options.addSuffix) {
    if (options.comparison > 0) {
      return 'tra ' + result;
    } else {
      return result + ' fa';
    }
  }

  return result;
}