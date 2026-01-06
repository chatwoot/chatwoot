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
    slate: 'bg-n-slate-1 outline-n-slate-5 text-n-slate-12',
    amber: 'bg-n-amber-1 outline-n-amber-5 text-n-amber-12',
    teal: 'bg-n-teal-1 outline-n-teal-5 text-n-teal-12',
    ruby: 'bg-n-ruby-1 outline-n-ruby-5 text-n-ruby-12',
    blue: 'bg-n-blue-1 outline-n-blue-5 text-n-blue-12',
  };

  return classMap[props.color];
});

const buttonClass = computed(() => {
  const classMap = {
    slate: 'hover:bg-n-slate-4 text-n-slate-11',
    amber: 'hover:bg-n-amber-4 text-n-amber-11',
    teal: 'hover:bg-n-teal-4 text-n-teal-11',
    ruby: 'hover:bg-n-ruby-4 text-n-ruby-11',
    blue: 'hover:bg-n-blue-4 text-n-blue-11',
  };

  return classMap[props.color];
});

const triggerAction = () => {
  emit('action');
};
</script>

<template>
  <div
    class="text-sm rounded-xl flex items-center justify-between min-h-12 gap-2 outline outline-1 -outline-offset-1"
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
        class="px-3 py-1 w-auto flex items-center justify-center rounded-lg flex-shrink-0"
        :class="buttonClass"
        @click="triggerAction"
      >
        <span class="line-clamp-2 text-button">{{ actionLabel }}</span>
      </button>
    </div>
  </div>
</template>
