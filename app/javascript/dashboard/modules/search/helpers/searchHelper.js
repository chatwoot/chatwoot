import ContactAPI from 'dashboard/api/contacts';

export const DATE_RANGE_TYPES = {
  LAST_7_DAYS: 'last_7_days',
  LAST_30_DAYS: 'last_30_days',
  LAST_90_DAYS: 'last_90_days',
  CUSTOM: 'custom',
  BETWEEN: 'between',
  BEFORE: 'before',
  AFTER: 'after',
};

export const generateURLParams = ({ from, in: inboxId, dateRange }) => {
  const params = {};

  if (from) params.from = from;
  if (inboxId) params.inbox_id = inboxId;

  if (dateRange?.type) {
    const { type, from: dateFrom, to: dateTo } = dateRange;
    params.range = type;
    if (dateFrom && type !== DATE_RANGE_TYPES.BEFORE) params.since = dateFrom;
    if (dateTo && type !== DATE_RANGE_TYPES.AFTER) params.until = dateTo;
  }

  return params;
};

export const parseURLParams = query => {
  const { from, inbox_id, since, until, range } = query;

  let type = range;
  if (!type && (since || until)) {
    if (since && until) type = DATE_RANGE_TYPES.BETWEEN;
    else if (since) type = DATE_RANGE_TYPES.AFTER;
    else if (until) type = DATE_RANGE_TYPES.BEFORE;
  }

  return {
    from: from || null,
    in: inbox_id ? Number(inbox_id) : null,
    dateRange: {
      type,
      from: since ? Number(since) : null,
      to: until ? Number(until) : null,
    },
  };
};

export const fetchContactDetails = async id => {
  try {
    const response = await ContactAPI.show(id);
    return response.data.payload;
  } catch (error) {
    // error
    return null;
  }
};
