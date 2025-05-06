<script setup>
import Policy from 'dashboard/components/policy.vue';

defineProps({
  title: {
    type: String,
    required: true,
  },
  subtitle: {
    type: String,
    required: true,
  },
  actionPerms: {
    type: Array,
    default: () => [],
  },
});
</script>

<template>
  <section
    class="relative flex flex-col items-center justify-center w-full h-full overflow-hidden"
  >
    <div
      class="relative w-full max-w-[60rem] mx-auto overflow-hidden h-full max-h-[36rem]"
    >
      <div
        class="w-full h-full space-y-4 overflow-y-hidden opacity-50 pointer-events-none"
      >
        <slot name="empty-state-item" />
      </div>
      <div
        class="absolute inset-x-0 bottom-0 flex flex-col items-center justify-end w-full h-full bg-gradient-to-t from-n-background from-0% via-n-background/95 via-25% to-transparent"
      >
        <div class="flex flex-col items-center justify-center gap-6 w-full max-w-4xl mx-auto px-4">
          <div class="flex flex-col items-center justify-center gap-3">
            <h2
              class="text-3xl font-medium text-center text-slate-900 dark:text-white font-interDisplay"
            >
              {{ title }}
            </h2>
            <p
              class="max-w-2xl mx-auto text-base text-center text-slate-600 dark:text-slate-300 font-interDisplay tracking-[0.3px]"
            >
              {{ subtitle }}
            </p>
          </div>
          <Policy :permissions="actionPerms">
            <slot name="actions" />
          </Policy>
        </div>
      </div>
    </div>
  </section>
</template>