<script setup>
defineProps({
  firstIndex: {
    type: Number,
    default: 0,
  },
  lastIndex: {
    type: Number,
    default: 0,
  },
  totalCount: {
    type: Number,
    default: 0,
  },
});
</script>

<template>
  <span class="text-sm text-n-slate-11 font-medium">
    {{
      $t('GENERAL.SHOWING_RESULTS', {
        firstIndex,
        lastIndex,
        totalCount,
      })
    }}
  </span>
</template>
