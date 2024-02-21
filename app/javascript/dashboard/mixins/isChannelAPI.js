import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters({ activeInbox: 'getSelectedInbox' }),
    isChannelApi() {
      if (this.activeInbox !== null) {
        return (
          this.$store.getters['inboxes/getInbox'](this.activeInbox)
            .channel_type === 'Channel::Api'
        );
      }
      return false;
    },
  },
};
