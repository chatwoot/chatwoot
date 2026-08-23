<script setup>
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { tintStylesFromHex } from 'dashboard/helper/colorHelper';

const props = defineProps({
  title: {
    type: String,
    required: true,
  },
  displayId: {
    type: Number,
    default: null,
  },
  color: {
    type: String,
    default: '',
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

const tintStyles = computed(() => tintStylesFromHex(props.color));
const hasCustomColor = computed(() => Object.keys(tintStyles.value).length > 0);

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
    class="flex items-center justify-center flex-shrink-0 rounded-full size-6"
    :class="[
      hasCustomColor ? '' : 'bg-n-brand/15',
      canNavigate ? 'cursor-pointer hover:opacity-90' : 'cursor-default',
    ]"
    :style="
      hasCustomColor
        ? { backgroundColor: tintStyles.backgroundColor }
        : undefined
    "
    :aria-label="tooltip"
    @click.stop="openAnalytics"
  >
    <Icon
      icon="i-lucide-megaphone"
      class="flex-shrink-0 size-3.5"
      :class="hasCustomColor ? '' : 'text-n-brand'"
      :style="hasCustomColor ? { color: tintStyles.color } : undefined"
    />
  </button>
  <button
    v-else-if="variant === 'pill'"
    v-tooltip.top="tooltip"
    type="button"
    class="inline-flex items-center gap-1 max-w-[9rem] truncate rounded-md border px-1.5 py-0.5 text-xxs font-medium flex-shrink-0"
    :class="[
      hasCustomColor ? '' : 'border-n-brand/30 bg-n-brand/10 text-n-brand',
      canNavigate ? 'cursor-pointer hover:opacity-90' : 'cursor-default',
    ]"
    :style="hasCustomColor ? tintStyles : undefined"
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
    class="inline-flex items-center gap-1.5 w-fit max-w-full rounded-md border px-2 py-1 text-xs font-medium text-start"
    :class="[
      hasCustomColor ? '' : 'border-n-brand/30 bg-n-brand/10 text-n-brand',
      canNavigate ? 'cursor-pointer hover:opacity-90' : 'cursor-default',
    ]"
    :style="hasCustomColor ? tintStyles : undefined"
    :aria-label="tooltip"
    @click.stop="openAnalytics"
  >
    <Icon icon="i-lucide-megaphone" class="size-3.5 flex-shrink-0" />
    <span class="min-w-0 truncate">{{ title }}</span>
  </button>
</template>
