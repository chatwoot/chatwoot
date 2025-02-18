<script setup>
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
        class="bg-n-slate-3 rounded-md dark:bg-n-solid-3 absolute left-0 right-0 z-20 mx-auto mt-0 max-w-max bottom-2 backdrop-blur[100px]"
      >
        <woot-button
          v-if="shrink"
          size="tiny"
          variant="smooth"
          color-scheme="primary"
          @click.prevent="$emit('expand')"
        >
          {{ $t('SEARCH.READ_MORE') }}
        </woot-button>
      </div>
    </div>
  </div>
</template>
