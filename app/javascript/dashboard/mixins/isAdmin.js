import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters({
      currentUserRole: 'getCurrentRole',
    }),
    isAdmin() {
      return this.currentUserRole === 'administrator';
    },
  },
};
