<script setup>
import NextButton from 'dashboard/components-next/button/Button.vue';

defineProps({
  shrink: {
    type: Boolean,
    default: false,
  },
});

defineEmits(['expand']);
</script>

<template>
  <div>
    <div
      :class="{
        'max-h-[100px] overflow-hidden relative': shrink,
      }"
    >
      <slot />
      <div
        v-if="shrink"
        class="absolute inset-x-0 bottom-0 h-16 bg-gradient-to-t to-transparent from-n-background flex items-end justify-center pb-2"
      >
        <NextButton
          :label="$t('SEARCH.READ_MORE')"
          icon="i-lucide-chevrons-down"
          blue
          xs
          faded
          class="backdrop-filter backdrop-blur-[2px]"
          @click.prevent="$emit('expand')"
        />
      </div>
    </div>
  </div>
</template>
