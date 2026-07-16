<script setup>
import { computed } from 'vue';
import Icon from 'next/icon/Icon.vue';
import ChannelIcon from 'next/icon/ChannelIcon.vue';
import SidebarUnreadBadge from './SidebarUnreadBadge.vue';

const props = defineProps({
  label: {
    type: String,
    required: true,
  },
  // eslint-disable-next-line vue/no-unused-properties
  active: {
    type: Boolean,
    default: false,
  },
  inbox: {
    type: Object,
    required: true,
  },
  badgeCount: {
    type: [Number, String],
    default: 0,
  },
  manualMigrationRecommended: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['reviewManualMigration']);

const reauthorizationRequired = computed(() => {
  return props.inbox.reauthorization_required;
});

const showManualMigrationRecommendation = computed(() => {
  return props.manualMigrationRecommended && !reauthorizationRequired.value;
});
</script>

<template>
  <span class="size-4 grid place-content-center rounded-full">
    <ChannelIcon :inbox="inbox" class="size-4" />
  </span>
  <div class="flex-1 truncate min-w-0">{{ label }}</div>
  <SidebarUnreadBadge :count="badgeCount" />
  <div
    v-if="reauthorizationRequired"
    v-tooltip.top-end="$t('SIDEBAR.REAUTHORIZE')"
    class="grid place-content-center size-5 bg-n-ruby-5/60 rounded-full"
  >
    <Icon icon="i-woot-alert" class="size-3 text-n-ruby-9" />
  </div>
  <button
    v-else-if="showManualMigrationRecommendation"
    v-tooltip.top-end="$t('SIDEBAR.WHATSAPP_MANUAL_MIGRATION')"
    type="button"
    :aria-label="$t('SIDEBAR.WHATSAPP_MANUAL_MIGRATION')"
    class="grid place-content-center size-5 bg-n-blue-5/60 rounded-full hover:bg-n-blue-5 focus-visible:bg-n-blue-5 focus-visible:outline-none"
    @click.stop.prevent="emit('reviewManualMigration')"
  >
    <Icon icon="i-lucide-info" class="size-3 text-n-blue-9" />
  </button>
</template>
