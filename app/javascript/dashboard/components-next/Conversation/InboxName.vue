<script setup>
import { useI18n } from 'vue-i18n';
import ChannelIcon from 'dashboard/components-next/icon/ChannelIcon.vue';

defineProps({
  inbox: {
    type: Object,
    default: () => {},
  },
});

const { t } = useI18n();
</script>

<template>
  <div :title="inbox.name" class="flex items-center gap-1 min-w-0">
    <ChannelIcon :inbox="inbox" class="size-4 flex-shrink-0 text-n-slate-11" />
    <span class="truncate text-body-main text-n-slate-11">
      {{ inbox.name }}
    </span>
    <span
      v-if="inbox.active === false"
      class="inline-flex h-4 shrink-0 items-center rounded-md bg-n-alpha-2 px-1 text-label-mini font-medium text-n-slate-11"
    >
      {{ t('INBOX_MGMT.DISABLED') }}
    </span>
  </div>
</template>
