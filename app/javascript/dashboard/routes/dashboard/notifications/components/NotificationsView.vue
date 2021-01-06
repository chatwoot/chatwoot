<template>
  <div class="notifications-page row">
    <div class="left-wrap medium-12">
      <notification-header />
      <notifications :notifications="records" />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import NotificationHeader from './Header';
import Notifications from './Notifications';
export default {
  components: {
    NotificationHeader,
    Notifications,
  },
  computed: {
    ...mapGetters({
      records: 'notifications/getNotifications',
      uiFlags: 'notifications/getUIFlags',
    }),
  },
  mounted() {
    this.$store.dispatch('notifications/get', { page: 1 });
  },
};
</script>

<style lang="scss" scoped>
.notifications-page {
  width: 100%;
}
.left-wrap {
  display: flex;
  flex-direction: column;
  padding-top: var(--space-normal);
  height: 100%;
}
</style>
