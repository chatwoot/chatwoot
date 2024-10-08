<script setup>
import { ref, computed } from 'vue';
import Dialog from 'dashboard/playground/components/Dialog.vue';
import ComboBox from 'dashboard/playground/components/ComboBox.vue';
import allLocales from 'shared/constants/locales.js';

const emit = defineEmits(['confirm']);

const dialogRef = ref(null);

const handleDialogConfirm = () => {
  emit('confirm');
};

// Expose the dialogRef to the parent component
defineExpose({ dialogRef });

const locales = computed(() => {
  return Object.keys(allLocales).map(key => {
    return {
      value: key,
      label: `${allLocales[key]} (${key})`,
    };
  });
});

const selectedLocale = ref('');
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    title="Add locale"
    description="Select the language in which this article will be written. This will be added to your list of translations, and you can add more later."
    @confirm="handleDialogConfirm"
  >
    <template #form>
      <div class="flex flex-col gap-6">
        <ComboBox
          v-model="selectedLocale"
          :options="locales"
          placeholder="Select framework..."
        />
      </div>
    </template>
  </Dialog>
</template>
