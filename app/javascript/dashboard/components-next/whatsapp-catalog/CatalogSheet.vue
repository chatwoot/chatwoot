<script setup>
import { watch, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SheetHandle from 'dashboard/components-next/sheet-handle/SheetHandle.vue';

const props = defineProps({
  show: { type: Boolean, default: false },
  title: { type: String, default: '' },
  backButton: { type: Boolean, default: false },
  size: {
    type: String,
    default: 'md',
    validator: value => ['md', 'lg'].includes(value),
  },
});

const emit = defineEmits(['close']);

const { t } = useI18n();

const SIZE_CLASSES = { md: 'sm:max-w-2xl', lg: 'sm:max-w-lg' };

const onKeydown = event => {
  if (event.key === 'Escape') emit('close');
};

const stopListening = () => document.removeEventListener('keydown', onKeydown);

watch(
  () => props.show,
  show => {
    stopListening();
    if (show) document.addEventListener('keydown', onKeydown);
  },
  { immediate: true }
);

onBeforeUnmount(stopListening);
</script>

<template>
  <Teleport to="body">
    <div
      v-if="show"
      class="fixed inset-0 z-[10000] flex items-end justify-center bg-n-alpha-black1 backdrop-blur-sm sm:items-center sm:p-4"
      data-test-id="catalog-sheet-backdrop"
      @click.self.stop.prevent="emit('close')"
    >
      <div
        role="dialog"
        aria-modal="true"
        :aria-label="title"
        class="relative flex flex-col w-full max-h-[90dvh] overflow-hidden border bg-n-solid-2 border-n-weak shadow-lg max-sm:rounded-t-2xl sm:rounded-xl"
        :class="SIZE_CLASSES[size]"
        data-test-id="catalog-sheet"
      >
        <SheetHandle @close="emit('close')" />
        <div
          class="flex items-center justify-between gap-2 px-4 pt-6 pb-3 shrink-0 border-b border-n-weak sm:py-3"
          data-test-id="catalog-sheet-header"
        >
          <NextButton
            v-if="backButton"
            icon="i-lucide-chevron-left"
            slate
            faded
            sm
            class="!rounded-full sm:hidden"
            :aria-label="t('CATALOG.ACTIONS.BACK')"
            data-test-id="catalog-sheet-back"
            @click="emit('close')"
          />
          <h2 class="flex-1 text-base font-medium truncate text-n-slate-12">
            {{ title }}
          </h2>
          <NextButton
            icon="i-lucide-x"
            slate
            faded
            sm
            class="!rounded-full max-sm:hidden"
            :aria-label="t('CATALOG.ACTIONS.CLOSE')"
            data-test-id="catalog-sheet-close"
            @click="emit('close')"
          />
        </div>
        <div class="flex flex-col flex-1 min-h-0 overflow-y-auto">
          <slot />
        </div>
        <div v-if="$slots.footer" class="shrink-0 border-t border-n-weak">
          <slot name="footer" />
        </div>
      </div>
    </div>
  </Teleport>
</template>
