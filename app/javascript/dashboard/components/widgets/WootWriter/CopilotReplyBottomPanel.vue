<script setup>
import NextButton from 'dashboard/components-next/button/Button.vue';

defineProps({
  isGeneratingContent: {
    type: Boolean,
    default: false,
  },
  isPrivate: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['submit', 'cancel']);

const handleCancel = () => {
  emit('cancel');
};

const handleSubmit = () => {
  emit('submit');
};
</script>

<template>
  <div
    class="flex justify-between items-center p-3 border-t"
    :class="{ 'border-n-weak': !isPrivate, 'border-n-amber-12/5': isPrivate }"
  >
    <NextButton
      label="Discard"
      slate
      link
      class="!px-1 hover:!no-underline"
      sm
      :disabled="isGeneratingContent"
      @click="handleCancel"
    />
    <NextButton
      label="Accept"
      class="bg-n-iris-9 text-white"
      solid
      sm
      :disabled="isGeneratingContent"
      @click="handleSubmit"
    />
  </div>
</template>
