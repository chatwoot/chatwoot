import { fromUnixTime, isToday, isYesterday } from 'date-fns';
import { dateFormat } from 'shared/helpers/timeHelper';

export const getCompanyProfile = additionalAttributes => {
  const {
    industry,
    sub_industry: subIndustry,
    employee_count_range: employeeCountRange,
    employee_count: employeeCount,
    city,
    country,
    country_code: countryCode,
  } = additionalAttributes || {};

  return {
    industry: subIndustry || industry,
    employees: employeeCount
      ? employeeCount.toLocaleString()
      : employeeCountRange,
    location: [city, city ? countryCode || country : country]
      .filter(Boolean)
      .join(', '),
    fullLocation: [city, country].filter(Boolean).join(', '),
    countryCode,
  };
};

export const groupByDay = (items, timeKey, t) => {
  const dayLabel = time => {
    const date = fromUnixTime(time);
    if (isToday(date)) return t('COMPANIES.DETAIL.ACTIVITY.TODAY');
    if (isYesterday(date)) return t('COMPANIES.DETAIL.ACTIVITY.YESTERDAY');
    return dateFormat(time, 'EEEE, MMM d');
  };

  return items.reduce((groups, item) => {
    const label = dayLabel(item[timeKey]);
    const group = groups.at(-1);
    if (group?.label === label) group.items.push(item);
    else groups.push({ label, items: [item] });
    return groups;
  }, []);
};
