<script setup>
import Icon from './Icon.vue';

defineProps({
  name: {
    type: String,
    required: true,
  },
  to: {
    type: [String, Object],
    required: true,
  },
  icon: {
    type: String,
    default: null,
  },
  active: {
    type: Boolean,
    default: false,
  },
});
</script>

<template>
  <component
    :is="to ? 'router-link' : 'div'"
    :to="to"
    :title="name"
    class="flex h-8 items-center gap-2 px-2 py-1 rounded-lg max-w-[151px] hover:bg-gradient-to-r from-transparent via-n-slate-3/70 to-n-slate-3/70"
    :class="{
      'text-n-blue bg-n-alpha-2 font-medium': active,
    }"
  >
    <div>
      <Icon
        v-if="icon"
        :icon="icon"
        class="size-4 inline-block"
        :class="active ? 'bg-n-blue/20' : 'bg-n-alpha-2'"
      />
    </div>
    <div class="flex-1 truncate min-w-0">{{ name }}</div>
  </component>
</template>
