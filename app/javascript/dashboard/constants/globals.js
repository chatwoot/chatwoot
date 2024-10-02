export default {
  GRAVATAR_URL: 'https://www.gravatar.com/avatar/',
  ASSIGNEE_TYPE: {
    ME: 'me',
    UNASSIGNED: 'unassigned',
    ALL: 'all',
  },
  STATUS_TYPE: {
    OPEN: 'open',
    RESOLVED: 'resolved',
    PENDING: 'pending',
    SNOOZED: 'snoozed',
    ALL: 'all',
  },
  SORT_BY_TYPE: {
    LAST_ACTIVITY_AT_ASC: 'last_activity_at_asc',
    LAST_ACTIVITY_AT_DESC: 'last_activity_at_desc',
    CREATED_AT_ASC: 'created_at_asc',
    CREATED_AT_DESC: 'created_at_desc',
    PRIORITY_ASC: 'priority_asc',
    PRIORITY_DESC: 'priority_desc',
    WAITING_SINCE_ASC: 'waiting_since_asc',
    WAITING_SINCE_DESC: 'waiting_since_desc',
  },
  ARTICLE_STATUS_TYPES: {
    DRAFT: 0,
    PUBLISH: 1,
    ARCHIVE: 2,
  },
  LAYOUT_TYPES: {
    CONDENSED: 'condensed',
    EXPANDED: 'expanded',
  },
  DOCS_URL: 'https://www.chatwoot.com/docs/product/',
  HELP_CENTER_DOCS_URL:
    'https://www.chatwoot.com/docs/product/others/help-center',
  TESTIMONIAL_URL: 'https://testimonials.cdn.chatwoot.com/content.json',
  SMALL_SCREEN_BREAKPOINT: 1024,
  AVAILABILITY_STATUS_KEYS: ['online', 'busy', 'offline'],
  SNOOZE_OPTIONS: {
    UNTIL_NEXT_REPLY: 'until_next_reply',
    AN_HOUR_FROM_NOW: 'an_hour_from_now',
    UNTIL_TOMORROW: 'until_tomorrow',
    UNTIL_NEXT_WEEK: 'until_next_week',
    UNTIL_NEXT_MONTH: 'until_next_month',
    UNTIL_CUSTOM_TIME: 'until_custom_time',
  },
  EXAMPLE_URL: 'example.com',
  EXAMPLE_WEBHOOK_URL: 'https://example/api/webhook',
  INBOX_SORT_BY: {
    NEWEST: 'desc',
    OLDEST: 'asc',
  },
  INBOX_DISPLAY_BY: {
    SNOOZED: 'snoozed',
    READ: 'read',
  },
  INBOX_FILTER_TYPE: {
    STATUS: 'status',
    TYPE: 'type',
    SORT_ORDER: 'sort_order',
  },
  SLA_MISS_TYPES: {
    FRT: 'frt',
    NRT: 'nrt',
    RT: 'rt',
  },
};
export const DEFAULT_REDIRECT_URL = '/app/';
