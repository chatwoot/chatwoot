<template>
  <div class="flex flex-col items-start w-full gap-6">
    <div class="flex flex-col w-full gap-4">
      <h4 v-if="header" class="text-lg font-medium text-ash-900">
        {{ header }}
      </h4>
      <div class="flex flex-row items-center justify-between">
        <div class="flex-grow h-px bg-ash-200" />
      </div>
      <p v-if="description" class="mb-0 text-sm font-normal text-ash-900">
        {{ description }}
      </p>
    </div>
    <div v-if="$slots.settingsItem" class="flex flex-col w-full gap-6">
      <slot name="settingsItem" />
      <v3-button
        v-if="showActionButton"
        type="submit"
        color-scheme="primary"
        variant="solid"
        size="large"
      >
        {{ buttonText }}
      </v3-button>
    </div>
  </div>
</template>

<script setup>
import V3Button from 'v3/components/Form/Button.vue';
defineProps({
  header: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
  showActionButton: {
    type: Boolean,
    default: true,
  },
  buttonText: {
    type: String,
    default: 'Save',
  },
});
</script>
