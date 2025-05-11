<template>
  <div>
    <Button
      icon="i-ri-phone-fill"
      color="slate"
      size="sm"
      :tooltip="$t('CALL_BUTTON.TOOLTIP')"
      class="!h-7 !bg-n-solid-3 dark:!bg-n-black/30 !outline-n-weak !text-n-slate-11"
      @click="openCallModal"
    />
    <div v-if="showCallModal" class="fixed z-50 bg-n-alpha-black1 backdrop-blur-[4px] flex items-start pt-[clamp(3rem,15vh,12rem)] justify-center inset-0">
      <CallModal @close="showCallModal = false" />
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';
import CallModal from './CallModal.vue';

const showCallModal = ref(false);

const openCallModal = () => {
  showCallModal.value = true;
};
</script>