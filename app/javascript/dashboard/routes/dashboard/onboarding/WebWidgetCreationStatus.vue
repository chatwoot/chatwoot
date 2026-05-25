<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const POLL_INTERVAL = 5000;

const { t } = useI18n();
const store = useStore();

// The web widget inbox is created asynchronously during account setup. We poll
// the inboxes endpoint until it shows up, then stop — much simpler than the
// event-driven help center flow.
const websiteInboxes = useMapGetter('inboxes/getWebsiteInboxes');
const isReady = computed(() => websiteInboxes.value.length > 0);

let timer = null;
const isFetching = ref(false);

const stopPolling = () => {
  if (timer) {
    clearInterval(timer);
    timer = null;
  }
};

const poll = async () => {
  if (isFetching.value) return;
  isFetching.value = true;
  try {
    await store.dispatch('inboxes/get');
  } finally {
    isFetching.value = false;
  }
  if (isReady.value) stopPolling();
};

onMounted(() => {
  poll();
  if (!isReady.value) timer = setInterval(poll, POLL_INTERVAL);
});

onBeforeUnmount(stopPolling);
</script>

<template>
  <div class="flex items-center justify-between gap-3 px-3 py-3">
    <div class="flex items-center gap-2 min-w-0">
      <Icon
        v-if="isReady"
        icon="i-lucide-check"
        class="size-4 text-n-teal-11 flex-shrink-0"
      />
      <Spinner v-else :size="16" class="text-n-slate-9 flex-shrink-0" />
      <span class="text-sm font-medium text-n-slate-12 flex-shrink-0">
        {{ t('ONBOARDING_INBOX_SETUP.CREATED_FOR_YOU.LIVE_CHAT') }}
      </span>
      <span class="w-px h-4 bg-n-weak flex-shrink-0" />
      <span class="text-sm text-n-slate-11 truncate">
        {{ t('ONBOARDING_INBOX_SETUP.CREATED_FOR_YOU.LIVE_CHAT_DESCRIPTION') }}
      </span>
    </div>
    <span class="text-sm text-n-slate-11 flex-shrink-0">
      {{
        isReady
          ? t('ONBOARDING_INBOX_SETUP.CREATED_FOR_YOU.LIVE_CHAT_READY')
          : t('ONBOARDING_INBOX_SETUP.CREATED_FOR_YOU.LIVE_CHAT_STATUS')
      }}
    </span>
  </div>
</template>
