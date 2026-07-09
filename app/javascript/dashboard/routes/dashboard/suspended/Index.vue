<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { useMapGetter } from 'dashboard/composables/store';

const globalConfig = useMapGetter('globalConfig/get');

// Hide the CTA entirely when the installation has no support inbox — the widget
// SDK never loads there, so window.$chatwoot stays undefined and the button
// would be a no-op.
const canContactSupport = computed(() =>
  Boolean(globalConfig.value.chatwootInboxToken)
);

// The widget SDK loads asynchronously. Until it signals `chatwoot:ready` it
// can't be opened, and poking it early throws (its bubble DOM isn't mounted yet),
// so keep the button disabled with a loader till then.
const isWidgetReady = ref(Boolean(window.$chatwoot?.hasLoaded));

const showSupportBubble = () => {
  window.$chatwoot?.toggleBubbleVisibility('show');
};

const toggleSupportWidget = () => {
  window.$chatwoot?.toggle();
};

const onWidgetReady = () => {
  isWidgetReady.value = true;
  showSupportBubble();
};

onMounted(() => {
  // Reveal the support bubble once the widget is ready (immediately if it
  // already loaded before this view mounted), and keep it revealed whenever a
  // new support message comes in.
  if (isWidgetReady.value) {
    showSupportBubble();
  } else {
    window.addEventListener('chatwoot:ready', onWidgetReady);
  }
  window.addEventListener('chatwoot:on-message', showSupportBubble);
});

onBeforeUnmount(() => {
  window.removeEventListener('chatwoot:ready', onWidgetReady);
  window.removeEventListener('chatwoot:on-message', showSupportBubble);
});
</script>

<template>
  <div class="items-center bg-n-slate-2 flex justify-center h-full w-full">
    <EmptyState
      :title="$t('APP_GLOBAL.ACCOUNT_SUSPENDED.TITLE')"
      :message="$t('APP_GLOBAL.ACCOUNT_SUSPENDED.MESSAGE')"
    >
      <div v-if="canContactSupport" class="flex justify-center">
        <NextButton
          icon="i-lucide-life-buoy"
          :label="$t('SIDEBAR_ITEMS.CONTACT_SUPPORT')"
          :is-loading="!isWidgetReady"
          :disabled="!isWidgetReady"
          @click="toggleSupportWidget"
        />
      </div>
    </EmptyState>
  </div>
</template>
