<script setup>
import Logo from 'dashboard/components-next/icon/Logo.vue';

defineProps({
  message: { type: String, default: '' },
});
</script>

<template>
  <div
    class="flex h-screen w-full flex-col items-center justify-center gap-6 bg-n-background"
  >
    <Logo class="h-11 w-11" />
    <div class="flex items-center gap-3 text-base text-center text-n-slate-11">
      <span v-if="message" class="text-n-slate-12">{{ message }}</span>
      <div
        class="h-5 w-5 animate-spin rounded-full border-2 border-n-blue-6 border-t-n-brand"
      />
    </div>
  </div>
</template>
