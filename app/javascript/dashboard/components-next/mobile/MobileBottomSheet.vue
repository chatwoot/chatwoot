<script setup>
defineProps({
  title: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['close']);

const onOverlayClick = () => {
  emit('close');
};
</script>

<template>
  <Teleport to="body">
    <div class="fixed inset-0 z-[60] flex items-end">
      <div class="absolute inset-0 bg-black/40" @click="onOverlayClick" />
      <div
        class="relative w-full bg-white dark:bg-n-background rounded-t-2xl pb-[env(safe-area-inset-bottom)] max-h-[80vh] flex flex-col animate-slide-up"
      >
        <div
          class="flex items-center justify-between px-4 py-3 border-b border-n-weak flex-shrink-0"
        >
          <h3 class="text-base font-semibold text-n-slate-12">
            {{ title }}
          </h3>
          <button
            class="flex items-center justify-center size-8 rounded-lg text-n-slate-11 active:bg-n-alpha-2"
            @click="emit('close')"
          >
            <span class="i-lucide-x size-5" />
          </button>
        </div>
        <div class="overflow-y-auto px-4 py-4">
          <slot />
        </div>
      </div>
    </div>
  </Teleport>
</template>
