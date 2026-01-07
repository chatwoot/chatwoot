<script setup>
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  headerTitle: {
    type: String,
    default: '',
  },
  buttonLabel: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['click', 'close']);

const handleButtonClick = () => {
  emit('click');
};
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-n-surface-1">
    <header
      class="sticky top-0 z-10 px-6 lg:px-0 after:absolute after:inset-x-0 after:-bottom-4 after:bg-gradient-to-b after:from-n-surface-1 after:from-10% after:dark:from-0% after:to-transparent after:h-4 after:pointer-events-none"
    >
      <div class="w-full max-w-5xl mx-auto lg:px-6">
        <div class="flex items-center justify-between w-full h-20 gap-2">
          <span class="text-heading-1 text-n-slate-12">
            {{ headerTitle }}
          </span>
          <div
            v-on-clickaway="() => emit('close')"
            class="relative group/campaign-button"
          >
            <Button
              :label="buttonLabel"
              icon="i-lucide-plus"
              size="sm"
              class="group-hover/campaign-button:brightness-110"
              @click="handleButtonClick"
            />
            <slot name="action" />
          </div>
        </div>
      </div>
    </header>
    <main class="flex-1 px-6 overflow-y-auto lg:px-0">
      <div class="w-full max-w-5xl mx-auto py-4 lg:px-6">
        <slot name="default" />
      </div>
    </main>
  </section>
</template>
