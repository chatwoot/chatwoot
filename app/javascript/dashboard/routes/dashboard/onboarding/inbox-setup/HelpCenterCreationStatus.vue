<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import { useTimeoutPoll } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import OnboardingAPI from 'dashboard/api/onboarding';
import CreationStatusRow from './CreationStatusRow.vue';

const { t } = useI18n();
const POLL_INTERVAL = 5000;

const generation = ref({
  generation_id: null,
  state: null,
  articles_count: 0,
  categories_count: 0,
});

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

const status = computed(
  () =>
    generation.value.state?.status ||
    (generation.value.generation_id ? 'generating' : 'not_started')
);
const isCompleted = computed(() => status.value === 'completed');
const isSkipped = computed(() => status.value === 'skipped');
const isNotStarted = computed(() => status.value === 'not_started');
const isTerminal = computed(
  () => isCompleted.value || isSkipped.value || isNotStarted.value
);
const articlesCount = computed(() => generation.value.articles_count || 0);
const categoriesCount = computed(() => generation.value.categories_count || 0);

// Poll the generation status until it reaches a terminal state. useTimeoutPoll
// waits for each request to settle before scheduling the next (so requests never
// overlap), fires immediately on mount, and stops on unmount.
const { pause: stopPolling } = useTimeoutPoll(
  async () => {
    try {
      const { data } = await OnboardingAPI.getHelpCenterGeneration();
      generation.value = data;
      if (isTerminal.value) stopPolling();
    } catch {
      // Keep polling; transient network failures should not strand onboarding.
    }
  },
  POLL_INTERVAL,
  { immediate: true }
);

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
  if (isCompleted.value) {
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
  if (articlesCount.value > 0) return articlesText.value;
  return generatingPhases.value[phaseIndex.value];
});

const isVisible = computed(() => !isSkipped.value && !isNotStarted.value);
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <CreationStatusRow
    v-if="isVisible"
    :ready="isCompleted"
    :title="t('ONBOARDING_INBOX_SETUP.CREATED_FOR_YOU.HELP_CENTER')"
    :description="
      t('ONBOARDING_INBOX_SETUP.CREATED_FOR_YOU.HELP_CENTER_DESCRIPTION')
    "
    :status="statusText"
  />
</template>
