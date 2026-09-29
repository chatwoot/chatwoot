<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import { useExactTimestamp } from 'shared/composables/useExactTimestamp';
import { useCampaignAnalytics } from 'dashboard/composables/useCampaignAnalytics';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useAccount } from 'dashboard/composables/useAccount';
import Icon from 'next/icon/Icon.vue';
import MessageStatus from './MessageStatus.vue';

const props = defineProps({
  recipient: { type: Object, required: true },
});
const { t } = useI18n();
const { isAdmin } = useAdmin();
const { canViewAnalytics } = useCampaignAnalytics();
const { accountScopedRoute } = useAccount();
const exactTimestamp = useExactTimestamp();
const sentAt = computed(() =>
  messageTimestamp(props.recipient.sent_at, 'LLL d, h:mm a')
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
    class="flex w-full justify-end items-end gap-2 mb-2 ps-8"
    data-clarity-mask="True"
  >
    <div class="max-w-[30rem] min-w-0 text-sm">
      <div
        class="flex items-center gap-2 font-interDisplay text-xs leading-5 tracking-[0.0125rem] font-medium text-n-amber-11 mb-1.5 px-2"
      >
        <Icon
          v-tooltip.top="t('CAMPAIGN.HISTORY.LABEL')"
          icon="i-lucide-megaphone"
          class="size-4 shrink-0"
        />
        <span class="sr-only">{{ t('CAMPAIGN.HISTORY.LABEL') }}</span>
        <RouterLink
          v-if="isAdmin && canViewAnalytics"
          :to="
            accountScopedRoute('campaigns_whatsapp_analytics', {
              campaignId: recipient.campaign.id,
            })
          "
          class="flex min-w-0 items-center gap-1 text-xs leading-5 text-inherit hover:underline focus-visible:underline"
        >
          <span class="min-w-0 break-words">{{
            recipient.campaign.title
          }}</span>
          <Icon
            icon="i-lucide-chevron-right"
            class="size-4 shrink-0 rtl:rotate-180"
          />
        </RouterLink>
        <span v-else class="min-w-0 break-words">
          {{ recipient.campaign.title }}
        </span>
      </div>
      <div class="rounded-xl rounded-ee-sm bg-n-slate-4 p-3">
        <p
          class="whitespace-pre-wrap break-words text-n-slate-12 leading-[1.3125rem] m-0"
        >
          {{ recipient.message_content }}
        </p>
        <div
          class="flex flex-wrap items-center justify-end gap-2 mt-2.5 text-xs leading-5 text-n-slate-11"
        >
          <time
            v-tooltip.top="exactTimestamp(recipient.sent_at)"
            :datetime="new Date(recipient.sent_at * 1000).toISOString()"
          >
            {{ sentAt }}
          </time>
          <span v-if="recipient.status === 'failed'" class="text-n-ruby-11">
            {{ statusLabel }}
          </span>
          <span v-else role="img" :aria-label="statusLabel" class="inline-flex">
            <MessageStatus :status="recipient.status" />
          </span>
        </div>
      </div>
    </div>
    <span
      v-tooltip.top="t('CAMPAIGN.HISTORY.LABEL')"
      class="flex size-6 shrink-0 items-center justify-center rounded-full bg-n-amber-3 text-n-amber-11"
      aria-hidden="true"
    >
      <Icon icon="i-lucide-megaphone" class="size-3.5" />
    </span>
  </li>
</template>
