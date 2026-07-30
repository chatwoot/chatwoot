<script setup>
import Popover from 'dashboard/components-next/popover/Popover.vue';

defineProps({
  title: { type: String, required: true },
  description: { type: String, required: true },
  // Muted footnote for caveats (measurement windows, estimates, exclusions).
  note: { type: String, default: '' },
});
</script>

<template>
  <!-- The stop keeps the click from reaching clickable metric cards, which
       would otherwise open the drilldown alongside the popover. -->
  <span class="inline-flex" @click.stop>
    <Popover align="start">
      <template #default="{ isOpen }">
        <button
          type="button"
          class="inline-flex p-0 transition-colors bg-transparent border-0 cursor-help"
          :class="
            isOpen ? 'text-n-slate-12' : 'text-n-slate-8 hover:text-n-slate-12'
          "
        >
          <span class="i-lucide-info size-3.5" />
        </button>
      </template>
      <template #content>
        <div class="flex flex-col gap-1.5 p-4 w-72 text-start">
          <span class="text-xs font-medium text-n-slate-12">{{ title }}</span>
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
