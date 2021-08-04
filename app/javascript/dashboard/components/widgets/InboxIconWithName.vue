<template>
  <div class="inbox">
    <i :class="icon" />
    <span>{{ inbox.name }}</span>
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
        return 'icon ion-earth';
      }
      return 'icon ion-android-textsms';
    },
  },
};
</script>

<style scoped lang="scss">
.inbox {
  display: flex;
  align-items: center;
  .icon {
    margin-right: var(--space-micro);
    min-width: var(--space-normal);
    position: relative;
    top: -1px;
  }
}
</style>
