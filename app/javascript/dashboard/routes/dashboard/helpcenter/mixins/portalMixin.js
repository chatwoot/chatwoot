import { mapGetters } from 'vuex';
import { frontendURL } from 'dashboard/helper/URLHelper';
export default {
  computed: {
    ...mapGetters({ accountId: 'getCurrentAccountId' }),
    portalSlug() {
      return this.$route.params.portalSlug;
    },
    locale() {
      return this.$route.params.locale;
    },
  },
  methods: {
    articleUrl(id) {
      return frontendURL(
        `accounts/${this.accountId}/portals/${this.portalSlug}/${this.locale}/articles/${id}`
      );
    },
  },
};
