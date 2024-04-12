<template>
  <div class="flex flex-col gap-6 w-full items-start">
    <div
      class="flex flex-col gap-4 divide-y divide-slate-200 dark:divide-slate-700"
    >
      <h4
        v-if="header"
        class="text-slate-900 dark:text-slate-25 text-lg font-medium"
      >
        {{ header }}
      </h4>
      <p
        v-if="description"
        class="text-slate-600 dark:text-slate-400 text-sm font-normal mb-0 pt-4"
      >
        {{ description }}
      </p>
    </div>
    <div v-if="$slots.settingsItem" class="w-full flex flex-col gap-6">
      <slot name="settingsItem" />
      <woot-button
        v-if="showActionButton"
        color-scheme="primary"
        class="rounded-xl w-fit"
        @click="$emit('click')"
      >
        Save
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
});
</script>
