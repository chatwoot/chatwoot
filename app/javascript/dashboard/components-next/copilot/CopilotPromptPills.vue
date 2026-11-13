<script setup>
import Button from '../button/Button.vue';

defineProps({
  prompts: {
    type: Array,
    required: true,
  },
});

const emit = defineEmits(['select']);
</script>

<template>
  <div class="flex flex-wrap gap-2">
    <Button
      v-for="prompt in prompts"
      :key="prompt.key"
      :label="prompt.label"
      faded
      slate
      sm
      class="!rounded-full"
      @click="emit('select', prompt.key)"
    />
  </div>
</template>
