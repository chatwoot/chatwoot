import { CONTENT_TYPES } from '../constants/contentType';

export default {
  computed: {
    isEmailContentType() {
      return this.contentType === CONTENT_TYPES.INCOMING_EMAIL;
    },
  },
};
