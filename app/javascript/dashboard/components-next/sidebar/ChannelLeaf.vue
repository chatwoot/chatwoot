<script setup>
import { computed } from 'vue';
import Icon from 'next/icon/Icon.vue';
import ChannelIcon from 'next/icon/ChannelIcon.vue';
import { getInboxIdentifier } from 'dashboard/helper/inbox';
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
});

const IDENTIFIER_SEPARATOR = '·';

const reauthorizationRequired = computed(() => {
  return props.inbox.reauthorization_required;
});

const channelIdentifier = computed(() => getInboxIdentifier(props.inbox));

const rowTitle = computed(() =>
  channelIdentifier.value
    ? `${props.label} ${IDENTIFIER_SEPARATOR} ${channelIdentifier.value}`
    : props.label
);
</script>

<template>
  <span class="size-4 grid place-content-center rounded-full">
    <ChannelIcon :inbox="inbox" class="size-4" />
  </span>
  <div
    :title="rowTitle"
    class="flex-1 truncate min-w-0"
    data-test-id="channel-leaf-label"
  >
    {{ label }}
    <template v-if="channelIdentifier">
      <span aria-hidden="true" class="text-n-slate-9 mx-0.5">
        {{ IDENTIFIER_SEPARATOR }}
      </span>
      <bdi dir="auto" class="text-n-slate-9" data-test-id="channel-identifier">
        {{ channelIdentifier }}
      </bdi>
    </template>
  </div>
  <SidebarUnreadBadge :count="badgeCount" />
  <div
    v-if="reauthorizationRequired"
    v-tooltip.top-end="$t('SIDEBAR.REAUTHORIZE')"
    class="grid place-content-center size-5 bg-n-ruby-5/60 rounded-full"
  >
    <Icon icon="i-woot-alert" class="size-3 text-n-ruby-9" />
  </div>
</template>
