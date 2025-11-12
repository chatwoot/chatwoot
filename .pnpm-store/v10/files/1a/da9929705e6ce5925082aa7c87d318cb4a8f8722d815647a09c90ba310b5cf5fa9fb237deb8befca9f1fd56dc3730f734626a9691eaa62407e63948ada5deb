var formatDistanceLocale = {
  lessThanXSeconds: {
    one: 'أقل من ثانية واحدة',
    other: 'أقل من {{count}} ثواني'
  },
  xSeconds: {
    one: 'ثانية واحدة',
    other: '{{count}} ثواني'
  },
  halfAMinute: 'نصف دقيقة',
  lessThanXMinutes: {
    one: 'أقل من دقيقة',
    other: 'أقل من {{count}} دقيقة'
  },
  xMinutes: {
    one: 'دقيقة واحدة',
    other: '{{count}} دقائق'
  },
  aboutXHours: {
    one: 'ساعة واحدة تقريباً',
    other: '{{count}} ساعات تقريباً'
  },
  xHours: {
    one: 'ساعة واحدة',
    other: '{{count}} ساعات'
  },
  xDays: {
    one: 'يوم واحد',
    other: '{{count}} أيام'
  },
  aboutXMonths: {
    one: 'شهر واحد تقريباً',
    other: '{{count}} أشهر تقريباً'
  },
  xMonths: {
    one: 'شهر واحد',
    other: '{{count}} أشهر'
  },
  aboutXYears: {
    one: 'عام واحد تقريباً',
    other: '{{count}} أعوام تقريباً'
  },
  xYears: {
    one: 'عام واحد',
    other: '{{count}} أعوام'
  },
  overXYears: {
    one: 'أكثر من عام',
    other: 'أكثر من {{count}} أعوام'
  },
  almostXYears: {
    one: 'عام واحد تقريباً',
    other: '{{count}} أعوام تقريباً'
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
      return 'في خلال ' + result;
    } else {
      return 'منذ ' + result;
    }
  }

  return result;
}