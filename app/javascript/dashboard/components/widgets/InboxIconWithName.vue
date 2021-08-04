<template>
  <div class="row--inbox-block">
    <i class="inbox-icon" :class="icon" />
    <div>{{ inbox.name }}</div>
  </div>
</template>
<script>
import { INBOX_TYPES } from 'shared/mixins/inboxMixin';
export default {
  props: {
    inbox: {
      type: Object,
      default: () => {},
    },
  },
  computed: {
    icon() {
      if (this.inbox.channel_type === INBOX_TYPES.WEB) {
        return 'ion-earth';
      }
      return 'ion-android-textsms';
    },
  },
};
</script>

<style scoped lang="scss">
.row--inbox-block {
  display: flex;
  align-items: center;
  .inbox-icon {
    margin-right: var(--space-micro);
    min-width: var(--space-normal);
    position: relative;
    top: -1px;
  }
}
</style>
