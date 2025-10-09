<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { messageStamp } from 'shared/helpers/timeHelper';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  title: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
  startDate: {
    type: Number,
    default: 0,
  },
  endDate: {
    type: Number,
    default: 0,
  },
  sourceId: {
    type: String,
    default: '',
  },
  active: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['edit', 'delete']);

const { t } = useI18n();

const { formatMessage } = useMessageFormatter();

const isActive = computed(() => props.active);

const statusTextColor = computed(() => ({
  'text-n-teal-11': isActive.value,
  'text-n-slate-12': !isActive.value,
}));

const campaignStatus = computed(() => {
  return isActive.value
    ? t('CAMPAIGN.MARKETING.CARD.STATUS.ACTIVE')
    : t('CAMPAIGN.MARKETING.CARD.STATUS.INACTIVE');
});
</script>

<template>
  <CardLayout layout="row">
    <div class="flex flex-col items-start justify-between flex-1 min-w-0 gap-2">
      <div class="flex justify-between gap-3 w-fit">
        <span
          class="text-base font-medium capitalize text-n-slate-12 line-clamp-1"
        >
          {{ title }}
        </span>

        <span
          class="text-xs font-medium inline-flex items-center h-6 px-2 py-0.5 rounded-md bg-n-alpha-2"
          :class="statusTextColor"
        >
          {{ campaignStatus }}
        </span>
      </div>

      <div class="flex justify-between gap-3 w-fit">
        <span class="text-xs font-medium text-n-slate-12 line-clamp-1">
          {{ sourceId }}
        </span>
      </div>
      <div
        v-dompurify-html="formatMessage(description, false, false, false)"
        class="text-sm text-n-slate-11 line-clamp-1 [&>p]:mb-0 h-6"
      />
      <div class="flex items-center w-full h-6 gap-2 overflow-hidden">
        <span class="flex-shrink-0 text-sm text-n-slate-11 whitespace-nowrap">
          {{ t('CAMPAIGN.MARKETING.CARD.CAMPAIGN_DETAILS.FROM') }}
        </span>
        <span class="text-sm font-medium truncate text-n-slate-12">
          {{ messageStamp(new Date(startDate), 'LLL d, h:mm a') }}
        </span>
        <span class="text-sm text-n-slate-11 whitespace-nowrap">
          {{ t('CAMPAIGN.MARKETING.CARD.CAMPAIGN_DETAILS.TO') }}
        </span>
        <span class="text-sm font-medium truncate text-n-slate-12">
          {{ messageStamp(new Date(endDate), 'LLL d, h:mm a') }}
        </span>
      </div>
    </div>
    <div class="flex items-center justify-end gap-2">
      <Button
        variant="faded"
        size="sm"
        color="slate"
        icon="i-lucide-sliders-vertical"
        @click="emit('edit')"
      />
      <Button
        variant="faded"
        color="ruby"
        size="sm"
        icon="i-lucide-trash"
        @click="emit('delete')"
      />
    </div>
  </CardLayout>
</template>
