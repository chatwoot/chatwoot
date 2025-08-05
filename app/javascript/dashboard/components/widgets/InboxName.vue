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

<template>
  <div class="flex items-center text-n-slate-11 text-xs min-w-0">
    <fluent-icon
      class="ltr:mr-0.5 rtl:ml-0.5 flex-shrink-0"
      :icon="computedInboxClass"
      size="12"
    />
    <span class="truncate">
      {{ inbox.name }}
    </span>
  </div>
</template>
