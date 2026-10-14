import {
  CONVERSATION_CREATED_METRIC,
  buildDrilldownConversationFilters,
  canLinkDrilldownToConversations,
} from './drilldownConversationFilters';

// Local-time timestamps so the expected dates hold in any test timezone.
const localTimestamp = (...dateParts) =>
  Math.floor(new Date(...dateParts).getTime() / 1000);

const SEP_14 = localTimestamp(2026, 8, 14);
const SEP_15 = localTimestamp(2026, 8, 15);

const createdBetween = (after, before) => [
  {
    attribute_key: 'created_at',
    filter_operator: 'is_greater_than',
    values: after,
    query_operator: 'and',
  },
  {
    attribute_key: 'created_at',
    filter_operator: 'is_less_than',
    values: before,
    query_operator: 'and',
  },
];

describe('drilldownConversationFilters', () => {
  describe('canLinkDrilldownToConversations', () => {
    it.each(['day', 'week', 'month', 'year', undefined])(
      'links the conversations metric grouped by %s',
      groupBy => {
        expect(
          canLinkDrilldownToConversations({
            metric: CONVERSATION_CREATED_METRIC,
            groupBy,
          })
        ).toBe(true);
      }
    );

    it('does not link hourly buckets because the filter is date-only', () => {
      expect(
        canLinkDrilldownToConversations({
          metric: CONVERSATION_CREATED_METRIC,
          groupBy: 'hour',
        })
      ).toBe(false);
    });

    it.each([
      'incoming_messages_count',
      'outgoing_messages_count',
      'avg_first_response_time',
      'avg_resolution_time',
      'resolutions_count',
      'reply_time',
      '',
    ])('does not link the %s metric', metric => {
      expect(canLinkDrilldownToConversations({ metric, groupBy: 'day' })).toBe(
        false
      );
    });
  });

  describe('buildDrilldownConversationFilters', () => {
    it('bounds a day bucket by the surrounding days', () => {
      const filters = buildDrilldownConversationFilters({
        bucket: { since: SEP_14, until: SEP_15 },
        type: 'account',
        id: null,
      });

      expect(filters).toEqual(createdBetween('2026-09-13', '2026-09-15'));
    });

    it('bounds a multi-day bucket by its first and last days', () => {
      const filters = buildDrilldownConversationFilters({
        bucket: { since: localTimestamp(2026, 8, 8), until: SEP_15 },
        type: 'account',
        id: null,
      });

      expect(filters).toEqual(createdBetween('2026-09-07', '2026-09-15'));
    });

    it('keeps the last day when the bucket end is clamped inside it', () => {
      const filters = buildDrilldownConversationFilters({
        bucket: {
          since: SEP_14,
          until: localTimestamp(2026, 8, 15, 23, 59, 59),
        },
        type: 'account',
        id: null,
      });

      expect(filters).toEqual(createdBetween('2026-09-13', '2026-09-16'));
    });

    it('crosses month and year boundaries', () => {
      const filters = buildDrilldownConversationFilters({
        bucket: {
          since: localTimestamp(2026, 11, 31),
          until: localTimestamp(2027, 0, 1),
        },
        type: 'account',
        id: null,
      });

      expect(filters).toEqual(createdBetween('2026-12-30', '2027-01-01'));
    });

    it.each([
      ['inbox', 'inbox_id'],
      ['agent', 'assignee_id'],
      ['team', 'team_id'],
    ])('scopes a %s report by its %s', (type, attributeKey) => {
      const filters = buildDrilldownConversationFilters({
        bucket: { since: SEP_14, until: SEP_15 },
        type,
        id: 42,
      });

      expect(filters).toEqual([
        ...createdBetween('2026-09-13', '2026-09-15'),
        {
          attribute_key: attributeKey,
          filter_operator: 'equal_to',
          values: { id: 42 },
          query_operator: 'and',
        },
      ]);
    });

    it('scopes a label report by the label title', () => {
      const filters = buildDrilldownConversationFilters({
        bucket: { since: SEP_14, until: SEP_15 },
        type: 'label',
        id: 7,
        labelTitle: 'billing',
      });

      expect(filters).toEqual([
        ...createdBetween('2026-09-13', '2026-09-15'),
        {
          attribute_key: 'labels',
          filter_operator: 'equal_to',
          values: [{ id: 'billing' }],
          query_operator: 'and',
        },
      ]);
    });

    it('adds no scope for account-wide reports', () => {
      const filters = buildDrilldownConversationFilters({
        bucket: { since: SEP_14, until: SEP_15 },
        type: 'account',
        id: null,
      });

      expect(filters).toHaveLength(2);
    });
  });
});
