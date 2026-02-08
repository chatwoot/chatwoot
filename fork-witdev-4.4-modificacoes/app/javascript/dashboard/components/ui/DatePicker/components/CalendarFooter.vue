<script setup>
import NextButton from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits(['clear', 'change']);

const onClickClear = () => {
  emit('clear');
};

const onClickApply = () => {
  emit('change');
};
</script>

<template>
  <div class="h-[56px] flex justify-between gap-2 px-2 py-3 items-center">
    <NextButton
      slate
      ghost
      sm
      :label="$t('DATE_PICKER.CLEAR_BUTTON')"
      @click="onClickClear"
    />
    <NextButton
      sm
      ghost
      :label="$t('DATE_PICKER.APPLY_BUTTON')"
      @click="onClickApply"
    />
  </div>
</template>
