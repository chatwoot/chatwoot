import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
  },
  methods: {
    addAccountScoping(url) {
      console.log(url);
      return `/app/accounts/${this.accountId}/${url}`;
    },
  },
};
