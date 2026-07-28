<script setup>
import { useRouter } from 'vue-router';
import { useUiStore } from 'widget-v2/stores/ui';

defineProps({
  title: { type: String, default: '' },
  subtitle: { type: String, default: '' },
  showBack: { type: Boolean, default: false },
});

const router = useRouter();
const uiStore = useUiStore();

// A restored session (or a deep link) has nothing to pop, so fall back to the
// hub rather than leaving the visitor stranded.
const goBack = () => {
  if (router.options.history.state?.back) router.back();
  else router.push({ name: 'home' });
};
</script>

<template>
  <header
    class="flex items-center gap-2 px-4 h-16 shrink-0 bg-cw-solid border-b border-cw-hairline"
  >
    <button
      v-if="showBack"
      type="button"
      class="flex items-center justify-center w-8 h-8 -ml-2 rounded-full text-cw-text-muted hover:bg-cw-muted outline-none transition-colors focus-visible:ring-[3px] focus-visible:ring-cw-ring"
      :aria-label="$t('COMMON.BACK')"
      @click="goBack"
    >
      <span class="i-ph-arrow-left text-lg" />
    </button>

    <slot name="leading" />

    <div class="flex-1 min-w-0">
      <h1
        class="text-base font-520 text-cw-text truncate leading-tight type-display"
      >
        {{ title }}
      </h1>
      <p
        v-if="subtitle"
        class="text-xs text-cw-text-muted truncate leading-tight mt-0.5"
      >
        {{ subtitle }}
      </p>
    </div>

    <slot name="actions" />

    <button
      type="button"
      class="flex items-center justify-center w-8 h-8 -mr-1 rounded-full text-cw-text-muted hover:bg-cw-muted outline-none transition-colors focus-visible:ring-[3px] focus-visible:ring-cw-ring"
      :aria-label="$t('COMMON.CLOSE')"
      @click="uiStore.close()"
    >
      <span class="i-ph-x text-lg" />
    </button>
  </header>
</template>
