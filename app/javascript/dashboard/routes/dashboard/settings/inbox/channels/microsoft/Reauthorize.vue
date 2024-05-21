<template>
  <inbox-reconnection-required
    class="mx-8 mt-5"
    @reauthorize="requestAuthorization"
  />
</template>
<script>
import alertMixin from 'shared/mixins/alertMixin';
import InboxReconnectionRequired from '../../components/InboxReconnectionRequired';
import microsoftClient from '../../../../../../api/channel/microsoftClient';

export default {
  components: { InboxReconnectionRequired },
  mixins: [alertMixin],
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return { isRequestingAuthorization: false };
  },
  methods: {
    async requestAuthorization() {
      try {
        this.isRequestingAuthorization = true;
        const response = await microsoftClient.generateAuthorization({
          email: this.inbox.email,
        });
        const {
          data: { url },
        } = response;
        window.location.href = url;
      } catch (error) {
        this.showAlert(this.$t('INBOX_MGMT.ADD.MICROSOFT.ERROR_MESSAGE'));
      } finally {
        this.isRequestingAuthorization = false;
      }
    },
  },
};
</script>
<style lang="scss" scoped>
.smtp-details-wrap {
  margin-bottom: var(--space-medium);
}
</style>
