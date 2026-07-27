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
</script>

<template>
  <header
    class="flex items-center gap-2 px-4 h-16 shrink-0 bg-cw-background border-b border-cw-border"
  >
    <button
      v-if="showBack"
      type="button"
      class="flex items-center justify-center w-8 h-8 -ml-2 rounded-full text-cw-text-muted hover:bg-cw-muted outline-none focus-visible:ring-2 focus-visible:ring-cw-primary"
      :aria-label="$t('COMMON.BACK')"
      @click="router.back()"
    >
      <span class="i-lucide-arrow-left text-lg" />
    </button>

    <slot name="leading" />

    <div class="flex-1 min-w-0">
      <h1 class="text-sm font-semibold text-cw-text truncate leading-tight">
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
      class="flex items-center justify-center w-8 h-8 -mr-1 rounded-full text-cw-text-muted hover:bg-cw-muted outline-none focus-visible:ring-2 focus-visible:ring-cw-primary"
      :aria-label="$t('COMMON.CLOSE')"
      @click="uiStore.close()"
    >
      <span class="i-lucide-x text-lg" />
    </button>
  </header>
</template>
