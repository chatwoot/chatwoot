<script setup>
defineProps({
  toolset: {
    type: Object,
    required: true,
  },
});
</script>

<template>
  <div class="flex items-center w-full min-w-0 gap-3">
    <div
      class="flex items-center justify-center overflow-hidden rounded-lg size-10 shrink-0 bg-n-alpha-2"
    >
      <template v-if="toolset.logo_url">
        <img
          :src="toolset.logo_url"
          alt=""
          class="object-contain size-full dark:hidden"
        />
        <img
          :src="toolset.logo_dark_url || toolset.logo_url"
          alt=""
          class="hidden object-contain size-full dark:block"
        />
      </template>
      <i v-else class="i-lucide-blocks size-5 text-n-slate-11" />
    </div>
    <div class="flex flex-col min-w-0">
      <span class="text-sm font-medium truncate text-n-slate-12">
        {{ toolset.name }}
      </span>
      <span class="text-xs truncate text-n-slate-11">
        {{ toolset.author }}
      </span>
    </div>
  </div>
</template>
