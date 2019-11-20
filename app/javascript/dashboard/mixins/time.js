/* eslint no-console: 0 */
/* eslint no-undef: "error" */
/* eslint no-unused-expressions: ["error", { "allowShortCircuit": true }] */
import moment from 'moment';

export default {
  methods: {
    messageStamp(time) {
      const createdAt = time * 1000;
      return moment(createdAt).format('h:mm A');
    },
    wootTime(time) {
      const createdAt = time * 1000;
      return moment(createdAt);
    },
    dynamicTime(time) {
      const createdAt = moment(time * 1000);
      return createdAt.fromNow();
    },
  },
};
