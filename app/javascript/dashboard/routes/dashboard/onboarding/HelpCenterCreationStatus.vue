<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue';
import { storeToRefs } from 'pinia';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useHelpCenterGenerationStore } from 'dashboard/stores/helpCenterGeneration';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const { t } = useI18n();
const store = useStore();

const { isCompleted, isSkipped, articlesCount } = storeToRefs(
  useHelpCenterGenerationStore()
);

// On completion, fetch the onboarding portal to surface its real category
// count (the article count comes from the generation events). The portals
// index is the only place the store exposes meta.categories_count.
const portals = useMapGetter('portals/allPortals');
const categoriesCount = computed(
  () => portals.value?.[0]?.meta?.categories_count ?? null
);

watch(
  isCompleted,
  completed => {
    if (completed) store.dispatch('portals/index');
  },
  { immediate: true }
);

// Before the first article arrives, advance through phases so the spinner
// label doesn't sit on a single line through the whole curation step.
const generatingPhases = computed(() => [
  t('ONBOARDING_INBOX_SETUP.CREATED_FOR_YOU.HELP_CENTER_GENERATING'),
  t('ONBOARDING_INBOX_SETUP.CREATED_FOR_YOU.HELP_CENTER_ANALYZING_WEBSITE'),
  t('ONBOARDING_INBOX_SETUP.CREATED_FOR_YOU.HELP_CENTER_SETTING_UP_CATEGORIES'),
  t('ONBOARDING_INBOX_SETUP.CREATED_FOR_YOU.HELP_CENTER_CURATING_ARTICLES'),
]);
const PHASE_DELAY_BASE = 4000;
const PHASE_DELAY_JITTER = 2000;

const phaseIndex = ref(0);
let phaseTimer = null;

// Advance one phase after a jittered delay; stop once we reach the last line
// (it then holds until the first article arrives).
const scheduleNextPhase = () => {
  if (phaseIndex.value >= generatingPhases.value.length - 1) return;
  const delay = PHASE_DELAY_BASE + Math.random() * PHASE_DELAY_JITTER;
  phaseTimer = setTimeout(() => {
    phaseIndex.value += 1;
    scheduleNextPhase();
  }, delay);
};

onMounted(scheduleNextPhase);

onBeforeUnmount(() => clearTimeout(phaseTimer));

const articlesText = computed(() =>
  t(
    'ONBOARDING_INBOX_SETUP.CREATED_FOR_YOU.HELP_CENTER_ARTICLES',
    { count: articlesCount.value },
    articlesCount.value
  )
);

const statusText = computed(() => {
  if (isCompleted.value && categoriesCount.value != null) {
    const categories = t(
      'ONBOARDING_INBOX_SETUP.CREATED_FOR_YOU.HELP_CENTER_CATEGORIES',
      { count: categoriesCount.value },
      categoriesCount.value
    );
    return t(
      'ONBOARDING_INBOX_SETUP.CREATED_FOR_YOU.HELP_CENTER_SUMMARY',
      { count: articlesCount.value, categories },
      articlesCount.value
    );
  }
  if (isCompleted.value || articlesCount.value > 0) return articlesText.value;
  return generatingPhases.value[phaseIndex.value];
});
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <div
    v-if="!isSkipped"
    class="flex items-center justify-between gap-3 px-3 py-3 border-t border-n-weak"
  >
    <div class="flex items-center gap-2 min-w-0">
      <Icon
        v-if="isCompleted"
        icon="i-lucide-check"
        class="size-4 text-n-teal-11 flex-shrink-0"
      />
      <Spinner v-else :size="16" class="text-n-slate-9 flex-shrink-0" />
      <span class="text-sm font-medium text-n-slate-12 flex-shrink-0">
        {{ t('ONBOARDING_INBOX_SETUP.CREATED_FOR_YOU.HELP_CENTER') }}
      </span>
      <span class="w-px h-4 bg-n-weak flex-shrink-0" />
      <span class="text-sm text-n-slate-11 truncate">
        {{
          t('ONBOARDING_INBOX_SETUP.CREATED_FOR_YOU.HELP_CENTER_DESCRIPTION')
        }}
      </span>
    </div>
    <span class="text-sm text-n-slate-11 flex-shrink-0">
      {{ statusText }}
    </span>
  </div>
</template>
