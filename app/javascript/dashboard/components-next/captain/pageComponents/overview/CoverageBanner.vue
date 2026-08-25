<script setup>
import { computed, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { LocalStorage } from 'shared/helpers/localStorage';

const props = defineProps({
  knowledge: {
    type: Object,
    default: () => ({
      approved: 0,
      suggestions: 0,
      documents: 0,
      coverage: 0,
    }),
  },
});

const route = useRoute();
const router = useRouter();

// Dismissal is remembered per assistant for 24 hours (setFlag's default expiry).
const DISMISS_STORE = 'captain_overview_coverage_banner';

const accountId = computed(() => route.params.accountId);
const assistantId = computed(() => route.params.assistantId);

// Re-read the stored flag whenever the assistant changes, otherwise the banner
// would keep the first assistant's dismissed state after switching.
const dismissed = ref(false);

watch(
  [accountId, assistantId],
  ([account, assistant]) => {
    dismissed.value = LocalStorage.getFlag(DISMISS_STORE, account, assistant);
  },
  { immediate: true }
);

// Thin coverage paired with a large review backlog: approving FAQ suggestions
// is the quickest lever to lift auto-resolution, so nudge the team to act.
const COVERAGE_THRESHOLD = 85;
const SUGGESTION_THRESHOLD = 100;

const showBanner = computed(
  () =>
    !dismissed.value &&
    (props.knowledge?.coverage ?? 0) < COVERAGE_THRESHOLD &&
    (props.knowledge?.suggestions ?? 0) > SUGGESTION_THRESHOLD
);

const dismiss = () => {
  LocalStorage.setFlag(DISMISS_STORE, accountId.value, assistantId.value);
  dismissed.value = true;
};

const goToSuggestions = () => {
  router.push({
    name: 'captain_assistants_faq_suggestions',
    params: {
      accountId: route.params.accountId,
      assistantId: route.params.assistantId,
    },
  });
};
</script>

<template>
  <div
    class="flex items-center justify-between gap-3 px-3 py-2 text-sm border rounded-xl bg-n-amber-3 border-n-amber-4 text-n-amber-11"
    :class="{ hidden: !showBanner }"
  >
    <div class="flex items-center gap-2 min-w-0">
      <span class="shrink-0 i-lucide-triangle-alert size-4" />
      <span class="truncate">
        {{
          $t('CAPTAIN.OVERVIEW.COVERAGE_BANNER.TEXT', {
            count: knowledge.suggestions,
            coverage: knowledge.coverage,
          })
        }}
      </span>
    </div>
    <div class="flex items-center gap-1 shrink-0">
      <button
        type="button"
        class="px-3 py-1 rounded-lg bg-n-amber-4 hover:bg-n-amber-5"
        @click="goToSuggestions"
      >
        {{ $t('CAPTAIN.OVERVIEW.COVERAGE_BANNER.ACTION') }}
      </button>
      <button
        type="button"
        class="grid rounded-lg size-7 place-content-center hover:bg-n-amber-4"
        :aria-label="$t('CAPTAIN.OVERVIEW.COVERAGE_BANNER.DISMISS')"
        @click="dismiss"
      >
        <span class="i-lucide-x size-4" />
      </button>
    </div>
  </div>
</template>
