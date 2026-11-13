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
    <!-- Prompts are full questions, so a long one wraps to a second line instead of being cut off. -->
    <Button
      v-for="prompt in prompts"
      :key="prompt.key"
      :label="prompt.label"
      faded
      slate
      sm
      class="!rounded-full !h-auto min-h-8 py-1.5 text-start [&>span]:!whitespace-normal [&>span]:!overflow-visible"
      @click="emit('select', prompt.key)"
    />
  </div>
</template>
