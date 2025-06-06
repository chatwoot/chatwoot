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
    slate: 'bg-n-slate-3 border-n-slate-4 text-n-slate-11',
    amber: 'bg-n-amber-3 border-n-amber-4 text-n-amber-11',
    teal: 'bg-n-teal-3 border-n-teal-4 text-n-teal-11',
    ruby: 'bg-n-ruby-3 border-n-ruby-4 text-n-ruby-11',
    blue: 'bg-n-blue-3 border-n-blue-4 text-n-blue-11',
  };

  return classMap[props.color];
});

const buttonClass = computed(() => {
  const classMap = {
    slate: 'bg-n-slate-4 hover:bg-n-slate-5 text-n-slate-11',
    amber: 'bg-n-amber-4 hover:bg-n-amber-5 text-n-amber-11',
    teal: 'bg-n-teal-4 hover:bg-n-teal-5 text-n-teal-11',
    ruby: 'bg-n-ruby-4 hover:bg-n-ruby-5 text-n-ruby-11',
    blue: 'bg-n-blue-4 hover:bg-n-blue-5 text-n-blue-11',
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
