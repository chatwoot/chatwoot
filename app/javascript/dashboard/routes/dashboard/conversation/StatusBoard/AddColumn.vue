<script setup>
import { computed } from 'vue';
import Button from '../../../../components-next/button/Button.vue';
import { useStore } from 'vuex';

const emit = defineEmits(['newColumn']);

const store = useStore();

const isCreating = computed(() => {
  return store.getters['pipelineStatuses/getUiFlags'].isCreating;
});

// =================== Events =================== //
const newColumn = () => {
  emit('newColumn');
};
</script>

<template>
  <div>
    <Button
      label="Add new column"
      icon="i-lucide-plus"
      :disabled="isCreating"
      @click="newColumn"
    />
  </div>
</template>
