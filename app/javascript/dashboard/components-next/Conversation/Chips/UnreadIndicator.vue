<script setup>
import { vIntersectionObserver } from '@vueuse/components';
import { computed } from 'vue';

const props = defineProps({
  label: {
    type: String,
    required: true,
  },
  variant: {
    type: String,
    default: 'primary',
    validator: value => ['primary', 'secondary'].includes(value),
  },
});

const emit = defineEmits(['click', 'intersect']);

function onIntersectionObserver([entry]) {
  const isVisible = entry?.isIntersecting || false;
  emit('intersect', isVisible);
}

const classToApply = computed(() => {
  return {
    'bg-n-solid-blue text-n-blue-text': props.variant === 'primary',
    'shadow-sm border border-n-weak bg-n-solid-2 text-n-slate-11':
      props.variant === 'secondary',
  };
});
</script>

<template>
  <div>
    <div
      v-intersection-observer="onIntersectionObserver"
      :class="classToApply"
      class="flex py-1.5 px-3 rounded-full text-xs font-semibold my-2.5 mx-auto"
      @click="emit('click')"
    >
      {{ label }}
    </div>
  </div>
</template>
