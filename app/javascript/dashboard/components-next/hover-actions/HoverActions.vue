<script setup>
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  actions: {
    type: Array,
    required: true,
  },
  loading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['action']);
</script>

<template>
  <div
    class="relative flex shrink-0 flex-col items-end gap-1 md:flex-row md:items-center md:justify-end md:gap-0"
  >
    <div
      class="transition-opacity"
      :class="{
        'md:[@media(hover:hover)]:group-hover:opacity-0 md:[@media(hover:hover)]:group-focus-within:opacity-0':
          actions.length,
      }"
    >
      <slot />
    </div>
    <div
      v-if="actions.length"
      class="flex gap-1 transition-opacity md:ms-3 md:gap-3 md:[@media(hover:hover)]:pointer-events-none md:[@media(hover:hover)]:absolute md:[@media(hover:hover)]:end-0 md:[@media(hover:hover)]:top-1/2 md:[@media(hover:hover)]:-translate-y-1/2 md:[@media(hover:hover)]:ms-0 md:[@media(hover:hover)]:opacity-0 md:[@media(hover:hover)]:group-hover:pointer-events-auto md:[@media(hover:hover)]:group-hover:opacity-100 md:[@media(hover:hover)]:group-focus-within:pointer-events-auto md:[@media(hover:hover)]:group-focus-within:opacity-100"
    >
      <Button
        v-for="action in actions"
        :key="action.key"
        v-tooltip.top="action.label"
        :icon="action.icon"
        :aria-label="action.label"
        :is-loading="loading"
        slate
        sm
        :class="{
          'hover:enabled:bg-n-ruby-2 hover:enabled:text-n-ruby-11':
            action.danger,
        }"
        @click.stop="emit('action', action.key)"
      />
    </div>
  </div>
</template>
