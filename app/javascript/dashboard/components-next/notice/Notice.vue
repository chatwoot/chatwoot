<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  color: {
    type: String,
    default: 'blue',
    validator: value => ['ruby', 'blue', 'teal', 'amber'].includes(value),
  },
  icon: {
    type: String,
    default: 'i-lucide-info',
  },
  title: {
    type: String,
    default: null,
  },
  message: {
    type: String,
    default: null,
  },
});

const colorClasses = {
  ruby: 'outline-n-ruby-4 bg-n-ruby-3 text-n-ruby-11',
  blue: 'outline-n-blue-4 bg-n-blue-3 text-n-blue-11',
  teal: 'outline-n-teal-4 bg-n-teal-3 text-n-teal-11',
  amber: 'outline-n-amber-4 bg-n-amber-3 text-n-amber-11',
};

const titleColorClasses = {
  ruby: 'text-n-ruby-11',
  blue: 'text-n-blue-11',
  teal: 'text-n-teal-11',
  amber: 'text-n-amber-11',
};
</script>

<template>
  <div
    class="p-4 rounded-xl outline outline-1 -outline-offset-1"
    :class="colorClasses[color]"
  >
    <div class="flex gap-3 items-start">
      <Icon :icon="icon" class="flex-shrink-0 mt-0.5" />
      <div class="flex-1 space-y-1">
        <h4
          v-if="title"
          class="text-sm font-semibold"
          :class="titleColorClasses[color]"
        >
          {{ title }}
        </h4>
        <p v-if="message" class="mb-0 text-sm">
          {{ message }}
        </p>
        <slot />
      </div>
    </div>
  </div>
</template>
