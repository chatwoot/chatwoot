<script setup>
import { computed } from 'vue';
import { isWebUrl } from 'widget-v2/helpers/urlHelpers';

const props = defineProps({
  notice: { type: Object, required: true },
});

const level = computed(() =>
  ['info', 'warning', 'critical'].includes(props.notice.level)
    ? props.notice.level
    : 'info'
);

// shadcn Alert style: card surface + level-tinted border, color carried by
// the icon rather than a filled slab.
const borderClasses = computed(
  () =>
    ({
      info: 'border-cw-border',
      warning: 'border-n-amber-6',
      critical: 'border-n-ruby-6',
    })[level.value]
);

const iconClasses = computed(
  () =>
    ({
      info: 'text-cw-primary',
      warning: 'text-n-amber-11',
      critical: 'text-n-ruby-11',
    })[level.value]
);

const icon = computed(
  () =>
    ({
      info: 'i-ph-info-fill',
      warning: 'i-ph-warning-fill',
      critical: 'i-ph-warning-octagon-fill',
    })[level.value]
);

const linkUrl = computed(() =>
  isWebUrl(props.notice.url) ? props.notice.url : null
);
</script>

<template>
  <component
    :is="linkUrl ? 'a' : 'div'"
    :href="linkUrl || undefined"
    :target="linkUrl ? '_blank' : undefined"
    :rel="linkUrl ? 'noreferrer noopener' : undefined"
    class="flex items-start gap-2.5 px-4 py-3 rounded-token border bg-cw-solid shadow-sm"
    :class="borderClasses"
  >
    <span :class="[icon, iconClasses]" class="shrink-0 mt-0.5" />
    <span class="flex-1 min-w-0">
      <span v-if="notice.title" class="block text-sm font-520 text-cw-text">
        {{ notice.title }}
      </span>
      <span
        v-if="notice.message"
        class="block text-xs leading-relaxed text-cw-text-muted"
        :class="{ 'mt-0.5': notice.title }"
      >
        {{ notice.message }}
      </span>
    </span>
    <span
      v-if="linkUrl"
      class="i-ph-arrow-square-out shrink-0 mt-0.5 text-cw-text-faint"
    />
  </component>
</template>
