<!-- DEPRECIATED -->
<!-- TODO: Replace this banner component with NextBanner "app/javascript/dashboard/components-next/banner/Banner.vue" -->
<script setup>
import { computed } from 'vue';

const props = defineProps({
  color: {
    type: String,
    default: 'slate',
    validator: value =>
      ['blue', 'ruby', 'amber', 'slate', 'teal'].includes(value),
  },
  actionLabel: {
    type: String,
    default: null,
  },
});

const emit = defineEmits(['action']);

const bannerClass = computed(() => {
  const classMap = {
    slate: 'bg-s-subtle border-s-border-subtle text-s-muted',
    amber: 'bg-s-warning-soft border-s-border text-s-warning-text',
    teal: 'bg-s-success-soft border-s-success/30 text-s-success-text',
    ruby: 'bg-s-error-soft border-s-border text-s-error-text',
    blue: 'bg-s-brand-soft border-s-brand-soft text-s-brand-text',
  };

  return classMap[props.color];
});

const buttonClass = computed(() => {
  const classMap = {
    slate: 'bg-s-subtle hover:bg-s-border-subtle text-s-muted',
    amber: 'bg-s-warning-soft hover:bg-s-warning-soft text-s-warning-text',
    teal: 'bg-s-success-soft hover:bg-s-success/30 text-s-success-text',
    ruby: 'bg-s-error-soft hover:bg-s-error-soft text-s-error-text',
    blue: 'bg-s-brand-soft hover:bg-s-brand-soft text-s-brand-text',
  };

  return classMap[props.color];
});

const triggerAction = () => {
  emit('action');
};
</script>

<template>
  <div
    class="text-sm rounded-xl flex items-center justify-between gap-2 border"
    :class="[
      bannerClass,
      {
        'py-2 px-3': !actionLabel,
        'pl-3 p-2': actionLabel,
      },
    ]"
  >
    <div>
      <slot />
    </div>
    <div>
      <button
        v-if="actionLabel"
        class="px-3 py-1 w-auto grid place-content-center rounded-lg"
        :class="buttonClass"
        @click="triggerAction"
      >
        {{ actionLabel }}
      </button>
    </div>
  </div>
</template>
