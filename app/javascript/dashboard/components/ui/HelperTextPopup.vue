<script setup>
defineProps({
  message: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <div class="relative group w-[inherit] whitespace-normal z-20">
    <fluent-icon
      icon="info"
      size="14"
      class="mt-0.5 text-s-muted absolute"
    />
    <div
      class="bg-s-bg w-fit ltr:left-4 rtl:right-4 top-0 border p-2.5 group-hover:flex items-center hidden absolute border-s-border rounded-lg shadow-md"
    >
      <p class="text-s-primary mb-0 text-xs">
        {{ message }}
      </p>
    </div>
  </div>
</template>
