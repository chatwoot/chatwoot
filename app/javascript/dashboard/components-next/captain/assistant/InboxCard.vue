<script setup>
import { computed } from 'vue';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Policy from 'dashboard/components/policy.vue';
import ChannelIcon from 'dashboard/components-next/icon/ChannelIcon.vue';
import ChannelName from 'dashboard/routes/dashboard/settings/inbox/components/ChannelName.vue';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  inbox: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['action']);

const inboxName = computed(() => {
  const inbox = props.inbox;
  if (!inbox?.name) {
    return '';
  }

  const isTwilioChannel = inbox.channel_type === INBOX_TYPES.TWILIO;
  const isWhatsAppChannel = inbox.channel_type === INBOX_TYPES.WHATSAPP;
  const isEmailChannel = inbox.channel_type === INBOX_TYPES.EMAIL;

  if (isTwilioChannel || isWhatsAppChannel) {
    const identifier = inbox.messaging_service_sid || inbox.phone_number;
    return identifier ? `${inbox.name} (${identifier})` : inbox.name;
  }

  if (isEmailChannel && inbox.email) {
    return `${inbox.name} (${inbox.email})`;
  }

  return inbox.name;
});

const handleAction = (action, value) => {
  emit('action', { action, value, id: props.id });
};
</script>

<template>
  <CardLayout
    class="ltr:[&>div]:pl-4 ltr:[&>div]:pr-3 rtl:[&>div]:pl-3 rtl:[&>div]:pr-4 [&>div]:gap-2 [&>div]:py-4"
  >
    <div class="flex justify-between w-full gap-1">
      <div class="flex items-center gap-3 min-w-0">
        <div
          class="size-8 rounded-[0.625rem] flex items-center justify-center outline outline-1 outline-n-weak -outline-offset-1 flex-shrink-0"
        >
          <ChannelIcon
            :inbox="inbox"
            class="size-4 flex-shrink-0 text-n-slate-11"
          />
        </div>
        <span class="text-heading-3 text-n-slate-12 line-clamp-1 min-w-0">
          {{ inboxName }}
        </span>
        <div class="w-px h-3 bg-n-weak rounded-lg flex-shrink-0" />
        <ChannelName
          :channel-type="inbox.channel_type"
          :medium="inbox.medium"
          class="text-body-main text-n-slate-11 flex-shrink-0"
        />
      </div>
      <Policy :permissions="['administrator']">
        <Button
          icon="i-lucide-unlink"
          slate
          sm
          ghost
          @click="handleAction('delete', 'delete')"
        />
      </Policy>
    </div>
  </CardLayout>
</template>
