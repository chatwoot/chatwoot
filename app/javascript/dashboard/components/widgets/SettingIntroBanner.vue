<script setup>
defineProps({
  headerTitle: {
    type: String,
    default: '',
  },
  headerContent: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <div class="border-b border-solid border-n-weak/60 min-w-0">
    <div class="max-w-7xl w-full mx-auto pt-4 pb-0 px-6">
      <div class="flex items-center justify-between gap-3 mb-2">
        <div class="flex flex-col gap-1 min-w-0">
          <h2 class="text-2xl text-n-slate-12 font-medium">
            <span :title="headerTitle" class="block truncate">
              {{ headerTitle }}
            </span>
          </h2>
          <div
            v-if="$slots.meta"
            class="flex items-center gap-1 min-w-0 text-body-main text-n-slate-11"
          >
            <slot name="meta" />
          </div>
        </div>
        <slot name="actions" />
      </div>
      <p v-if="headerContent" class="w-full text-n-slate-11 text-sm mb-2">
        {{ headerContent }}
      </p>
      <slot />
    </div>
  </div>
</template>
