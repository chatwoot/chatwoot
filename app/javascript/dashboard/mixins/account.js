import auth from '../api/auth';

export default {
  computed: {
    accountId() {
      return auth.getCurrentUser().account_id;
    },
  },
  methods: {
    addAccountScoping(url) {
      return `/app/accounts/${this.accountId}/${url}`;
    },
  },
};
