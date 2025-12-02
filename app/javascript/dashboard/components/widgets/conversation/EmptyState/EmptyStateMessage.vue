<script setup>
import FeaturePlaceholder from './FeaturePlaceholder.vue';

defineProps({
  message: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <div class="flex flex-col items-center h-full">
    <div class="flex-[2]" />
    <div class="flex flex-col items-center">
      <img
        class="m-6 w-[7.5rem] hidden dark:block"
        src="dashboard/assets/images/no-chat-dark.svg"
        alt="No Chat dark"
      />
      <img
        class="m-6 w-[7.5rem] block dark:hidden"
        src="dashboard/assets/images/no-chat.svg"
        alt="No Chat"
      />
      <span class="text-sm text-n-slate-11 font-420 text-center">
        {{ message }}
      </span>
    </div>
    <div class="flex-[2]" />
    <!-- Cmd bar, keyboard shortcuts placeholder -->
    <FeaturePlaceholder />
    <div class="flex-[2]" />
  </div>
</template>
