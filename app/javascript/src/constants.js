export default {
  APP_BASE_URL: '/',
  PUSHER: 'test',
  get apiURL() {
    return `${this.APP_BASE_URL}/`;
  },
  GRAVATAR_URL: 'https://www.gravatar.com/avatar/',
  CHANNELS: {
    FACEBOOK: 'facebook',
  },
  ASSIGNEE_TYPE_SLUG: {
    MINE: 0,
    UNASSIGNED: 1,
    OPEN: 0,
  },
};
