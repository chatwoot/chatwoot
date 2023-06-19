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
    LATEST: 'latest',
    CREATED_AT: 'sort_on_created_at',
    PRIORITY: 'sort_on_priority',
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
  DOCS_URL: '//www.chatwoot.com/docs/product/',
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
};
export const DEFAULT_REDIRECT_URL = '/app/';
