<script setup>
defineProps({
  buttonText: {
    type: String,
    default: '',
  },
});
</script>
<template>
  <div
    class="flex items-center justify-between h-10 gap-2 px-3 mt-px border-b rounded-t-xl border-slate-50 dark:border-slate-700"
  >
    <div class="flex items-center gap-2">
      <fluent-icon
        icon="search"
        size="18"
        class="text-slate-400 dark:text-slate-400"
      />
      <input
        type="text"
        class="w-full mb-0 text-sm bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-75 reset-base"
        placeholder="Search"
        @input="$emit('input', $event.target.value)"
      />
    </div>
    <woot-button
      size="small"
      variant="clear"
      color-scheme="primary"
      class="!px-1 !py-1.5"
      @click="$emit('clear')"
    >
      {{ buttonText }}
    </woot-button>
  </div>
</template>
