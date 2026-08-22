<script setup>
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  title: {
    type: String,
    required: true,
  },
  displayId: {
    type: Number,
    default: null,
  },
  linkToAnalytics: {
    type: Boolean,
    default: true,
  },
  /** compact = header icon, pill = truncated inline, row = full title in list */
  variant: {
    type: String,
    default: 'compact',
    validator: v => ['compact', 'pill', 'row'].includes(v),
  },
});

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const tooltip = computed(() =>
  t('CONVERSATION.CAMPAIGN_BADGE.TOOLTIP', { title: props.title })
);

const canNavigate = computed(
  () => props.linkToAnalytics && props.displayId && route.params.accountId
);

const openAnalytics = () => {
  if (!canNavigate.value) return;

  router.push({
    name: 'campaigns_whatsapp_analytics',
    params: {
      accountId: route.params.accountId,
      campaignId: props.displayId,
    },
  });
};
</script>

<template>
  <button
    v-if="variant === 'compact'"
    v-tooltip.left="tooltip"
    type="button"
    class="flex items-center justify-center flex-shrink-0 rounded-full bg-n-brand/15 size-6"
    :class="
      canNavigate ? 'cursor-pointer hover:bg-n-brand/25' : 'cursor-default'
    "
    :aria-label="tooltip"
    @click.stop="openAnalytics"
  >
    <Icon
      icon="i-lucide-megaphone"
      class="flex-shrink-0 text-n-brand size-3.5"
    />
  </button>
  <button
    v-else-if="variant === 'pill'"
    v-tooltip.top="tooltip"
    type="button"
    class="inline-flex items-center gap-1 max-w-[9rem] truncate rounded-md border border-n-brand/30 bg-n-brand/10 px-1.5 py-0.5 text-xxs font-medium text-n-brand flex-shrink-0"
    :class="
      canNavigate ? 'cursor-pointer hover:bg-n-brand/15' : 'cursor-default'
    "
    :aria-label="tooltip"
    @click.stop="openAnalytics"
  >
    <Icon icon="i-lucide-megaphone" class="size-3 flex-shrink-0" />
    <span class="truncate">{{ title }}</span>
  </button>
  <button
    v-else
    v-tooltip.top="tooltip"
    type="button"
    class="inline-flex items-center gap-1.5 w-fit max-w-full rounded-md border border-n-brand/30 bg-n-brand/10 px-2 py-1 text-xs font-medium text-n-brand text-start"
    :class="
      canNavigate ? 'cursor-pointer hover:bg-n-brand/15' : 'cursor-default'
    "
    :aria-label="tooltip"
    @click.stop="openAnalytics"
  >
    <Icon icon="i-lucide-megaphone" class="size-3.5 flex-shrink-0" />
    <span class="min-w-0 truncate">{{ title }}</span>
  </button>
</template>
