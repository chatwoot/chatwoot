<script setup>
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

defineProps({
  headerTitle: {
    type: String,
    default: '',
  },
  buttonLabel: {
    type: String,
    default: '',
  },
  buttonDisabled: {
    type: Boolean,
    default: false,
  },
  buttonLoading: {
    type: Boolean,
    default: false,
  },
  showButton: {
    type: Boolean,
    default: true,
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
      <div class="w-full max-w-7xl mx-auto">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between w-full min-h-20 py-4 sm:py-0 gap-3 sm:gap-2">
          <span class="text-xl font-medium text-n-slate-12">
            {{ headerTitle }}
          </span>
          <div class="flex items-center flex-wrap gap-2">
            <slot name="header-actions" />
            <div
              v-if="buttonLabel && showButton"
              v-on-clickaway="() => emit('close')"
              class="relative group/kb-button"
            >
              <Button
                :label="buttonLabel"
                :disabled="buttonDisabled"
                icon="i-lucide-plus"
                size="sm"
                class="group-hover/kb-button:brightness-110"
                @click="handleButtonClick"
              >
                <template v-if="buttonLoading" #default>
                  <span class="min-w-0 truncate">{{ buttonLabel }}</span>
                  <Spinner class="!w-4 !h-4 flex-shrink-0 ml-1" />
                </template>
              </Button>
              <slot name="action" />
            </div>
          </div>
        </div>
      </div>
    </header>
    <main class="flex-1 px-6 overflow-y-auto lg:px-0">
      <div class="w-full max-w-7xl mx-auto py-4">
        <slot name="default" />
      </div>
    </main>
  </section>
</template>
