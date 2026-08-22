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
  fullWidth: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['click']);

const handleButtonClick = () => {
  emit('click');
};
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-n-surface-1">
    <header class="sticky top-0 z-10 px-6">
      <div
        class="w-full mx-auto"
        :class="fullWidth ? 'max-w-full' : 'max-w-5xl'"
      >
        <div class="flex items-center justify-between w-full h-20 gap-2">
          <span class="text-heading-1 text-n-slate-12">
            {{ headerTitle }}
          </span>
          <Button
            :label="buttonLabel"
            icon="i-lucide-plus"
            size="sm"
            class="hover:brightness-110"
            @click="handleButtonClick"
          />
        </div>
      </div>
    </header>
    <main class="flex-1 px-6 overflow-y-auto">
      <div
        class="w-full mx-auto py-4"
        :class="fullWidth ? 'max-w-full' : 'max-w-5xl'"
      >
        <slot name="default" />
      </div>
    </main>
  </section>
</template>
