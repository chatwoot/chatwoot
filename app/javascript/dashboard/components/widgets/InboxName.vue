<template>
  <span class="inbox--name">
    <i :class="computedInboxClass" />
    {{ inbox.name }}
  </span>
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
<style scoped>
.inbox--name {
  padding: var(--space-micro) 0;
  line-height: var(--space-slab);
  font-weight: var(--font-weight-medium);
  background: none;
  color: var(--s-500);
  font-size: var(--font-size-mini);
}
</style>
