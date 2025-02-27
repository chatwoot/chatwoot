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
  <section class="flex flex-col w-full h-full overflow-hidden bg-n-background">
    <header class="sticky top-0 z-10 px-6 lg:px-0">
      <div class="w-full max-w-[60rem] mx-auto">
        <div class="flex items-center justify-between w-full h-20 gap-2">
          <span class="text-xl font-medium text-n-slate-12">
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
      <div class="w-full max-w-[60rem] mx-auto py-4">
        <slot name="default" />
      </div>
    </main>
  </section>
</template>
