<script setup>
defineProps({
  label: {
    type: Object,
    default: null,
  },
});
</script>

<template>
  <div
    class="bg-n-alpha-2 rounded-md flex items-center h-7 w-fit py-1 ltr:pl-1 rtl:pr-1 ltr:pr-1.5 rtl:pl-1.5"
  >
    <div
      class="w-2 h-2 m-1 rounded-sm"
      :style="{ backgroundColor: label.color }"
    />
    <span class="text-sm text-n-slate-12">
      {{ label.title }}
    </span>
  </div>
</template>
