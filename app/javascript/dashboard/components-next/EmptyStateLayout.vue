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
    class="relative flex flex-col items-center justify-center w-full h-full overflow-hidden"
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
        class="absolute inset-x-0 bottom-0 flex flex-col items-center justify-end w-full h-full pb-20 bg-gradient-to-t from-n-background from-25% dark:from-n-background to-transparent"
      >
        <div class="flex flex-col items-center justify-center gap-6">
          <div class="flex flex-col items-center justify-center gap-3">
            <h2
              class="text-3xl font-medium text-center text-slate-900 dark:text-white font-interDisplay"
            >
              {{ title }}
            </h2>
            <p
              class="max-w-xl text-base text-center text-slate-600 dark:text-slate-300 font-interDisplay tracking-[0.3px]"
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
