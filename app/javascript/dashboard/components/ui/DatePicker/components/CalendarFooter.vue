<script setup>
const emit = defineEmits(['clear', 'change']);

const onClickClear = () => {
  emit('clear');
};

const onClickApply = () => {
  emit('change');
};
</script>

<template>
  <div class="h-[56px] flex justify-between px-5 py-3 items-center">
    <button
      class="p-1.5 rounded-lg w-fit text-sm font-medium text-slate-600 dark:text-slate-200 hover:text-slate-800 dark:hover:text-slate-100"
      @click="onClickClear"
    >
      {{ $t('DATE_PICKER.CLEAR_BUTTON') }}
    </button>
    <button
      class="p-1.5 rounded-lg w-fit text-sm font-medium text-woot-500 dark:text-woot-300 hover:text-woot-700 dark:hover:text-woot-500"
      @click="onClickApply"
    >
      {{ $t('DATE_PICKER.APPLY_BUTTON') }}
    </button>
  </div>
</template>
