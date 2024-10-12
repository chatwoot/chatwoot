<script setup>
defineProps({
  title: {
    type: String,
    required: true,
  },
  subtitle: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <section
    class="relative flex flex-col items-center justify-center w-full h-full min-h-screen p-4 overflow-hidden"
  >
    <div
      class="relative w-full max-w-[940px] mx-auto overflow-hidden h-full max-h-[448px]"
    >
      <div
        class="w-full h-full space-y-4 overflow-y-hidden opacity-50 pointer-events-none"
      >
        <slot name="empty-state-item" />
      </div>
      <div
        class="absolute inset-x-0 bottom-0 flex flex-col items-center justify-end w-full h-full pb-9 bg-gradient-to-t from-white dark:from-slate-900 to-transparent font-interDisplay"
      >
        <div class="flex flex-col items-center justify-center gap-6">
          <div class="flex flex-col items-center justify-center gap-2">
            <h2
              class="text-3xl font-medium text-center text-slate-900 dark:text-white"
            >
              {{ title }}
            </h2>
            <p
              class="max-w-lg text-base text-center text-slate-600 dark:text-slate-300"
            >
              {{ subtitle }}
            </p>
          </div>
          <slot name="actions" />
        </div>
      </div>
    </div>
  </section>
</template>
