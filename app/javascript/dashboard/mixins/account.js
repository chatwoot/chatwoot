import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
  },
  methods: {
    addAccountScoping(url) {
      return `/app/accounts/${this.accountId}/${url}`;
    },
  },
};
