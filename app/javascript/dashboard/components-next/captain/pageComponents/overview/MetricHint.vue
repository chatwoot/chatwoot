<script setup>
import Popover from 'dashboard/components-next/popover/Popover.vue';

defineProps({
  label: { type: String, required: true },
  description: { type: String, required: true },
  note: { type: String, default: '' },
});
</script>

<template>
  <span class="inline-flex" @click.stop>
    <Popover align="start">
      <template #default="{ isOpen }">
        <button
          type="button"
          class="inline-flex p-0 transition-colors bg-transparent border-0 cursor-help"
          :class="
            isOpen ? 'text-n-slate-12' : 'text-n-slate-8 hover:text-n-slate-12'
          "
          :aria-label="label"
        >
          <span class="i-lucide-info size-3.5" />
        </button>
      </template>
      <template #content>
        <div class="flex flex-col gap-1.5 p-4 w-72 text-start">
          <p class="m-0 text-xs leading-5 text-n-slate-11">
            {{ description }}
          </p>
          <p v-if="note" class="m-0 text-xs leading-5 text-n-slate-10">
            {{ note }}
          </p>
        </div>
      </template>
    </Popover>
  </span>
</template>
