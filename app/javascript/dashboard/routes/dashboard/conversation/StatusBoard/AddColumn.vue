<script setup>
import Button from '../../../../components-next/button/Button.vue';

const emit = defineEmits(['newColumn']);

// =================== Events =================== //
const newColumn = () => {
  emit('newColumn');
};
</script>

<template>
  <div>
    <Button label="Add new column" icon="i-lucide-plus" @click="newColumn" />
  </div>
</template>
