<template>
  <div class="inbox--name">
    <fluent-icon class="inbox--icon" :icon="computedInboxClass" size="12" />
    {{ inbox.name }}
  </div>
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
  align-items: center;
  display: inline-flex;
  padding: var(--space-micro) 0;
  line-height: var(--space-slab);
  font-weight: var(--font-weight-medium);
  background: none;
  color: var(--s-600);
  font-size: var(--font-size-mini);
  margin: 0 var(--space-one);
}

.inbox--icon {
  margin-right: var(--space-micro);
}
</style>
