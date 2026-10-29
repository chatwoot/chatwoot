<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import ChannelIcon from 'dashboard/components-next/icon/ChannelIcon.vue';
import { getInboxDisplayName } from 'dashboard/helper/inbox';

const props = defineProps({
  inbox: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();
const displayName = computed(() => getInboxDisplayName(props.inbox, t));
</script>

<template>
  <div :title="displayName" class="flex items-center gap-0.5 min-w-0">
    <ChannelIcon :inbox="inbox" class="size-4 flex-shrink-0 text-n-slate-11" />
    <span class="truncate text-body-main text-n-slate-11">
      {{ displayName }}
    </span>
  </div>
</template>
