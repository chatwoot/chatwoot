export default {
  APP_BASE_URL: '/',
  get apiURL() {
    return `${this.APP_BASE_URL}/`;
  },
  GRAVATAR_URL: 'https://www.gravatar.com/avatar/',
  ASSIGNEE_TYPE: {
    ME: 'me',
    UNASSIGNED: 'unassigned',
    ALL: 'all',
  },
  STATUS_TYPE: {
    OPEN: 'open',
    RESOLVED: 'resolved',
    BOT: 'bot',
  },
};
