<script setup>
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  headerTitle: {
    type: String,
    default: '',
  },
  headerSubtitle: {
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
  <section
    class="flex h-full w-full flex-col overflow-hidden text-on-surface antialiased selection:bg-secondary/30"
  >
    <header class="sticky top-0 z-10 px-6 pb-3 lg:px-0">
      <div class="mx-auto w-full max-w-[60rem] lg:px-6">
        <div
          class="flex min-h-20 flex-col gap-3 pt-2 sm:flex-row sm:items-start sm:justify-between sm:gap-4"
        >
          <div class="min-w-0 flex-1 space-y-1">
            <h1 class="text-3xl font-bold tracking-tight text-on-surface">
              {{ headerTitle }}
            </h1>
            <p
              v-if="headerSubtitle"
              class="mb-0 text-lg text-on-primary-container"
            >
              {{ headerSubtitle }}
            </p>
          </div>
          <div
            v-on-clickaway="() => emit('close')"
            class="group/campaign-button relative shrink-0"
          >
            <Button
              solid
              teal
              sm
              :label="buttonLabel"
              icon="i-lucide-plus"
              class="font-semibold"
              @click="handleButtonClick"
            />
            <slot name="action" />
          </div>
        </div>
      </div>
    </header>
    <main class="flex-1 overflow-y-auto px-6 lg:px-0">
      <div class="mx-auto w-full max-w-[60rem] py-4 lg:px-6">
        <slot />
      </div>
    </main>
  </section>
</template>
