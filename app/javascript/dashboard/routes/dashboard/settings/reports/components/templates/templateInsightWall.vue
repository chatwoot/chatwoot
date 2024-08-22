<script setup>
const emit = defineEmits(['click']);
function handleClick() {
  window.open(
    'https://www.facebook.com/business/help/218116047387456',
    '_blank'
  );
}
</script>

<template>
  <div
    class="flex flex-col max-w-md px-6 py-6 bg-white border shadow dark:bg-slate-800 rounded-xl border-slate-100 dark:border-slate-900"
  >
    <div class="flex items-center w-full gap-2 mb-4">
      <span
        class="flex items-center justify-center w-6 h-6 rounded-full bg-woot-75/70 dark:bg-woot-800/40"
      >
        <fluent-icon
          size="14"
          class="flex-shrink-0 text-woot-500 dark:text-woot-500"
          icon="lock-closed"
        />
      </span>
      <span class="text-base font-medium text-slate-900 dark:text-white">
        {{ $t('TEMPLATE_REPORTS.INSIGHT_ALERT.TITLE') }}
      </span>
    </div>
    <p class="text-sm font-normal">
      {{ $t('TEMPLATE_REPORTS.INSIGHT_ALERT.TEXT') }}
    </p>
    <template>
      <woot-button
        color-scheme="primary"
        class="w-full mt-2 text-center rounded-xl"
        size="expanded"
        is-expanded
        @click="handleClick"
      >
        {{ $t('TEMPLATE_REPORTS.INSIGHT_ALERT.BUTTON') }}
      </woot-button>
    </template>
  </div>
</template>
