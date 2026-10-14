import { addDays, format, fromUnixTime, subDays } from 'date-fns';
import { FILTER_OPS } from 'dashboard/components-next/filter/operators';
import { CONVERSATION_ATTRIBUTES } from 'dashboard/components-next/filter/helper/filterHelper';

export const CONVERSATION_CREATED_METRIC = 'conversations_count';
const DATE_FORMAT = 'yyyy-MM-dd';

const DIMENSION_ATTRIBUTES = {
  inbox: CONVERSATION_ATTRIBUTES.INBOX_ID,
  agent: CONVERSATION_ATTRIBUTES.ASSIGNEE_ID,
  team: CONVERSATION_ATTRIBUTES.TEAM_ID,
};

// The Created-at filter compares dates strictly, so bound by the surrounding days.
const dayBefore = timestamp =>
  format(subDays(fromUnixTime(timestamp), 1), DATE_FORMAT);
const dayAfter = timestamp =>
  format(addDays(fromUnixTime(timestamp - 1), 1), DATE_FORMAT);

const condition = (attributeKey, filterOperator, values) => ({
  attribute_key: attributeKey,
  filter_operator: filterOperator,
  values,
  query_operator: 'and',
});

export const canLinkDrilldownToConversations = ({ metric, groupBy }) =>
  metric === CONVERSATION_CREATED_METRIC && groupBy !== 'hour';

export const buildDrilldownConversationFilters = ({
  bucket,
  type,
  id,
  labelTitle,
}) => {
  const filters = [
    condition(
      CONVERSATION_ATTRIBUTES.CREATED_AT,
      FILTER_OPS.IS_GREATER_THAN,
      dayBefore(bucket.since)
    ),
    condition(
      CONVERSATION_ATTRIBUTES.CREATED_AT,
      FILTER_OPS.IS_LESS_THAN,
      dayAfter(bucket.until)
    ),
  ];

  if (type === 'label') {
    filters.push(
      condition(CONVERSATION_ATTRIBUTES.LABELS, FILTER_OPS.EQUAL_TO, [
        { id: labelTitle },
      ])
    );
  } else if (DIMENSION_ATTRIBUTES[type]) {
    filters.push(
      condition(DIMENSION_ATTRIBUTES[type], FILTER_OPS.EQUAL_TO, { id })
    );
  }

  return filters;
};
