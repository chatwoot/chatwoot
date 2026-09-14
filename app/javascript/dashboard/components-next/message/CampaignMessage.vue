<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import Icon from 'next/icon/Icon.vue';

const props = defineProps({
  recipient: { type: Object, required: true },
});
const { t } = useI18n();
const sentAt = computed(() =>
  messageTimestamp(props.recipient.sent_at, 'LLL d, yyyy, h:mm a')
);
const statusLabel = computed(
  () =>
    ({
      sent: t('CAMPAIGN.WHATSAPP.ANALYTICS.STATUS.SENT'),
      delivered: t('CAMPAIGN.WHATSAPP.ANALYTICS.STATUS.DELIVERED'),
      read: t('CAMPAIGN.WHATSAPP.ANALYTICS.STATUS.READ'),
      failed: t('CAMPAIGN.WHATSAPP.ANALYTICS.STATUS.FAILED'),
    })[props.recipient.status]
);
</script>

<template>
  <li
    :id="`campaign-recipient-${recipient.id}`"
    class="flex justify-end my-3 message--read"
    data-clarity-mask="True"
  >
    <div
      class="max-w-[85%] min-w-0 rounded-xl border border-n-weak bg-n-alpha-2 px-4 py-3 text-sm"
    >
      <div class="flex items-center gap-2 text-n-slate-11 mb-2">
        <Icon icon="i-lucide-megaphone" class="size-4 shrink-0" />
        <span class="font-medium break-words">
          {{
            t('CAMPAIGN.HISTORY.SENT_CAMPAIGN', {
              name: recipient.campaign.title,
            })
          }}
        </span>
      </div>
      <p class="whitespace-pre-wrap break-words text-n-slate-12 m-0">
        {{ recipient.message_content }}
      </p>
      <div
        class="flex flex-wrap justify-end gap-x-2 mt-2 text-xs text-n-slate-11"
      >
        <span>{{ sentAt }}</span>
        <span :class="{ 'text-n-ruby-11': recipient.status === 'failed' }">
          {{ statusLabel }}
        </span>
      </div>
    </div>
  </li>
</template>
