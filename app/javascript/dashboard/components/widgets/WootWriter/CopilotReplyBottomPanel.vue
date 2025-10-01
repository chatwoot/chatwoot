<script setup>
import NextButton from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits(['submit', 'cancel']);

const handleCancel = () => {
  emit('cancel');
};

const handleSubmit = () => {
  emit('submit');
};
</script>

<template>
  <div class="flex justify-between items-center p-3 border-t border-n-weak">
    <NextButton
      label="Discard"
      slate
      link
      class="!px-1 hover:!no-underline"
      sm
      @click="handleCancel"
    />
    <NextButton
      label="Accept"
      class="bg-n-iris-9 text-white"
      solid
      sm
      @click="handleSubmit"
    />
  </div>
</template>
