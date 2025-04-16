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
  <div
    class="inbox--name inline-flex items-center py-0.5 px-0 leading-3 whitespace-nowrap bg-none text-n-slate-11 text-xs my-0 mx-2.5"
  >
    <fluent-icon
      class="mr-0.5 rtl:ml-0.5 rtl:mr-0"
      :icon="computedInboxClass"
      size="12"
    />
    {{ inbox.name }}
  </div>
</template>
