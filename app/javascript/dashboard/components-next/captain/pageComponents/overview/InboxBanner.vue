<script setup>
import { computed, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';

const route = useRoute();
const router = useRouter();
const store = useStore();

const dismissed = ref(false);

const assistantId = computed(() => route.params.assistantId);
const inboxes = useMapGetter('captainInboxes/getRecords');
const uiFlags = useMapGetter('captainInboxes/getUIFlags');

// Only surface once we know the assistant has no connected inboxes.
const showBanner = computed(
  () =>
    !dismissed.value &&
    !uiFlags.value.fetchingList &&
    inboxes.value.length === 0
);

watch(
  assistantId,
  id => {
    dismissed.value = false;
    if (id) store.dispatch('captainInboxes/get', { assistantId: id });
  },
  { immediate: true }
);

const goToInboxes = () => {
  router.push({
    name: 'captain_assistants_inboxes_index',
    params: {
      accountId: route.params.accountId,
      assistantId: assistantId.value,
    },
  });
};
</script>

<template>
  <div
    v-if="showBanner"
    class="flex items-center justify-between gap-3 px-3 py-2 text-sm border rounded-xl bg-n-amber-3 border-n-amber-4 text-n-amber-11"
  >
    <div class="flex items-center gap-2 min-w-0">
      <span class="shrink-0 i-lucide-triangle-alert size-4" />
      <span class="truncate">
        {{ $t('CAPTAIN.OVERVIEW.INBOX_BANNER.TEXT') }}
      </span>
    </div>
    <div class="flex items-center gap-1 shrink-0">
      <button
        type="button"
        class="px-3 py-1 rounded-lg bg-n-amber-4 hover:bg-n-amber-5"
        @click="goToInboxes"
      >
        {{ $t('CAPTAIN.OVERVIEW.INBOX_BANNER.ACTION') }}
      </button>
      <button
        type="button"
        class="grid rounded-lg size-7 place-content-center hover:bg-n-amber-4"
        :aria-label="$t('CAPTAIN.OVERVIEW.INBOX_BANNER.DISMISS')"
        @click="dismissed = true"
      >
        <span class="i-lucide-x size-4" />
      </button>
    </div>
  </div>
</template>
