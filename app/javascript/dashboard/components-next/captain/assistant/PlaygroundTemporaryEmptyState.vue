<script setup>
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  message: { type: String, required: true },
  actionLabel: { type: String, required: true },
});

const emit = defineEmits(['add']);
</script>

<template>
  <div class="overflow-hidden rounded-xl border border-n-weak bg-n-solid-1">
    <div class="p-3">
      <p
        class="rounded-lg border border-dashed border-n-strong px-4 py-6 text-center text-sm text-n-slate-11"
      >
        {{ message }}
      </p>
    </div>
    <div class="border-t border-n-weak p-1">
      <Button
        type="button"
        :label="actionLabel"
        icon="i-lucide-plus"
        variant="ghost"
        color="slate"
        size="sm"
        class="!w-full"
        @click="emit('add')"
      />
    </div>
  </div>
</template>
