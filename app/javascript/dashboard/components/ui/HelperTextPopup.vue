<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  message: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <div class="relative group flex-shrink-0 flex items-center">
    <Icon icon="i-lucide-info" class="text-n-slate-11 size-3.5 cursor-help" />
    <div
      class="hidden group-hover:block absolute z-50 ltr:left-5 rtl:right-5 top-0 w-max max-w-64 bg-n-alpha-3 backdrop-blur-[50px] border border-n-weak rounded-xl shadow-lg px-3 py-2"
    >
      <p class="text-n-slate-12 text-xs leading-relaxed mb-0 whitespace-normal">
        {{ message }}
      </p>
    </div>
  </div>
</template>
