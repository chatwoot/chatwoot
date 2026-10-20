<script setup>
import Breadcrumb from 'dashboard/components-next/breadcrumb/Breadcrumb.vue';

defineProps({
  breadcrumbItems: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['breadcrumbClick']);
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-n-surface-1">
    <header class="sticky top-0 z-10 px-6">
      <div class="w-full max-w-5xl mx-auto">
        <div class="flex items-center justify-between w-full h-20 gap-4">
          <Breadcrumb
            :items="breadcrumbItems"
            @click="(item, index) => emit('breadcrumbClick', item, index)"
          />
        </div>
      </div>
    </header>
    <main class="flex-1 px-6 overflow-y-auto">
      <div class="w-full max-w-5xl mx-auto py-4">
        <slot />
      </div>
    </main>
  </section>
</template>
