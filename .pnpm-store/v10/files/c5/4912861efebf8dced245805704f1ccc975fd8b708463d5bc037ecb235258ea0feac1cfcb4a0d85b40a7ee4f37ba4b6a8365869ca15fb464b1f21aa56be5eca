var formatDistanceLocale = {
  lessThanXSeconds: {
    one: 'malpli ol sekundo',
    other: 'malpli ol {{count}} sekundoj'
  },
  xSeconds: {
    one: '1 sekundo',
    other: '{{count}} sekundoj'
  },
  halfAMinute: 'duonminuto',
  lessThanXMinutes: {
    one: 'malpli ol minuto',
    other: 'malpli ol {{count}} minutoj'
  },
  xMinutes: {
    one: '1 minuto',
    other: '{{count}} minutoj'
  },
  aboutXHours: {
    one: 'proksimume 1 horo',
    other: 'proksimume {{count}} horoj'
  },
  xHours: {
    one: '1 horo',
    other: '{{count}} horoj'
  },
  xDays: {
    one: '1 tago',
    other: '{{count}} tagoj'
  },
  aboutXMonths: {
    one: 'proksimume 1 monato',
    other: 'proksimume {{count}} monatoj'
  },
  xWeeks: {
    one: '1 semajno',
    other: '{{count}} semajnoj'
  },
  aboutXWeeks: {
    one: 'proksimume 1 semajno',
    other: 'proksimume {{count}} semajnoj'
  },
  xMonths: {
    one: '1 monato',
    other: '{{count}} monatoj'
  },
  aboutXYears: {
    one: 'proksimume 1 jaro',
    other: 'proksimume {{count}} jaroj'
  },
  xYears: {
    one: '1 jaro',
    other: '{{count}} jaroj'
  },
  overXYears: {
    one: 'pli ol 1 jaro',
    other: 'pli ol {{count}} jaroj'
  },
  almostXYears: {
    one: 'preskaŭ 1 jaro',
    other: 'preskaŭ {{count}} jaroj'
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
      return 'post ' + result;
    } else {
      return 'antaŭ ' + result;
    }
  }

  return result;
}