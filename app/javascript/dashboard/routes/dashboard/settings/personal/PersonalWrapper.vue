<template>
  <div class="flex flex-col items-start w-full gap-6">
    <div
      class="flex flex-col w-full gap-4 divide-y divide-slate-200 dark:divide-slate-700"
    >
      <h4
        v-if="header"
        class="text-lg font-medium text-slate-900 dark:text-slate-25"
      >
        {{ header }}
      </h4>
      <p
        v-if="description"
        class="pt-4 mb-0 text-sm font-normal text-slate-600 dark:text-slate-400"
      >
        {{ description }}
      </p>
    </div>
    <div v-if="$slots.settingsItem" class="flex flex-col w-full gap-6">
      <slot name="settingsItem" />
      <woot-button
        v-if="showActionButton"
        color-scheme="primary"
        class="rounded-xl w-fit"
        @click="$emit('click')"
      >
        {{ buttonText }}
      </woot-button>
    </div>
  </div>
</template>

<script setup>
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
