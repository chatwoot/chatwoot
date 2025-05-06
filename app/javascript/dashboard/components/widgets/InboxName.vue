<script>
import { getInboxClassByType } from 'dashboard/helper/inbox';

export default {
  props: {
    inbox: {
      type: Object,
      default: () => {},
    },
    withPhoneNumber: {
      type: Boolean,
      default: false,
    },
    withProviderConnectionStatus: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    computedInboxClass() {
      const { phone_number: phoneNumber, channel_type: type } = this.inbox;
      const classByType = getInboxClassByType(type, phoneNumber);
      return classByType;
    },
    providerConnection() {
      return this.inbox.provider_connection?.connection;
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
    <span v-if="withPhoneNumber" class="ml-2 text-n-slate-12">{{
      inbox.phone_number
    }}</span>
    <span v-if="withProviderConnectionStatus" class="ml-2">
      <fluent-icon
        icon="circle"
        type="filled"
        :class="
          providerConnection === 'open' ? 'text-green-500' : 'text-n-slate-8'
        "
      />
    </span>
  </div>
</template>
