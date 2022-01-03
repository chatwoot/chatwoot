<template>
  <woot-label
    :title="inbox.name"
    :icon="computedInboxClass"
    color-scheme="secondary"
    class="inbox--name"
  />
</template>
<script>
import { getInboxClassByType } from 'dashboard/helper/inbox';

export default {
  props: {
    inbox: {
      type: Object,
      default: () => {},
    },
  },
  computed: {
    computedInboxClass() {
      const { phone_number: phoneNumber, channel_type: type } = this.inbox;
      const classByType = getInboxClassByType(type, phoneNumber);
      return classByType;
    },
  },
};
</script>
<style lang="scss" scoped>
.label.secondary.inbox--name {
  background: none;
  color: var(--s-600);
  padding: 0;

  .label__title {
    line-height: 1.2;
  }
}
</style>
