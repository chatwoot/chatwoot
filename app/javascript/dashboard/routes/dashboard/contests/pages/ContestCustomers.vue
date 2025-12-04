<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const store = useStore();
const route = useRoute();
const router = useRouter();
const { accountScopedRoute } = useAccount();
const { t } = useI18n();

const formatInputDate = date => {
  if (!(date instanceof Date) || Number.isNaN(date.getTime())) {
    return '';
  }
  return date.toISOString().slice(0, 10);
};

const formatDateTime = value => {
  if (!value) return '—';
  return new Intl.DateTimeFormat(undefined, {
    year: 'numeric',
    month: 'short',
    day: '2-digit',
  }).format(new Date(value));
};

const formatDate = value => {
  if (!value) return '—';
  return new Intl.DateTimeFormat(undefined, {
    year: 'numeric',
    month: 'short',
    day: '2-digit',
  }).format(new Date(value));
};

const buildDefaultDateRange = () => {
  const end = new Date();
  const start = new Date(end);
  start.setMonth(start.getMonth() - 1);
  return {
    from: formatInputDate(start),
    to: formatInputDate(end),
  };
};

const defaultRange = buildDefaultDateRange();
const contestCustomers = ref([]);
const selectedFromDate = ref(defaultRange.from);
const selectedToDate = ref(defaultRange.to);
const hasFetchedCustomers = ref(false);
const selectedContestId = ref(route.query.contest_id || null);

const contests = computed(() => store.getters['contests/getRecords']);
const hasLoaded = computed(() => store.getters['contests/hasLoaded']);
const uiFlags = computed(() => store.getters['contests/getUIFlags']);
const isLoadingEntries = computed(
  () => uiFlags.value.isCustomersFetching && !hasFetchedCustomers.value
);

const selectedContest = computed(() =>
  contests.value.find(contest => contest.id === selectedContestId.value)
);

const headingLabel = computed(() => t('CONTESTS.NAV_CUSTOMERS'));

const fetchContests = async ({ force = false } = {}) => {
  if (!force && hasLoaded.value) return;
  try {
    await store.dispatch('contests/fetch', {
      force,
    });
  } catch (error) {
    useAlert(error.message || t('CONTESTS.ERROR_FETCHING'));
  }
};

onMounted(() => {
  fetchContests();
});

const contestNameById = computed(() =>
  contests.value.reduce((acc, contest) => {
    acc[contest.id] = contest.name;
    return acc;
  }, {})
);

const ensureContestSelection = () => {
  const routeId = route.query.contest_id;
  if (routeId && contests.value.some(item => item.id === routeId)) {
    selectedContestId.value = routeId;
    return;
  }
  if (
    selectedContestId.value &&
    contests.value.some(item => item.id === selectedContestId.value)
  ) {
    return;
  }
  selectedContestId.value = contests.value[0]?.id || null;
};

watch(
  () => contests.value,
  () => {
    ensureContestSelection();
  },
  { immediate: true }
);

watch(
  () => route.query.contest_id,
  () => {
    ensureContestSelection();
  }
);

const PRIMARY_QUESTIONS = ['name', 'email', 'phone', 'phone_number'];

const pickAnswer = (answers = [], keys = []) => {
  const normalizedKeys = Array.isArray(keys) ? keys : [keys];
  const match = answers.find(answer =>
    normalizedKeys.includes(answer.question)
  );
  return match?.answer || '';
};

const extraAnswers = answers =>
  answers
    .filter(answer => !PRIMARY_QUESTIONS.includes(answer.question))
    .map(answer => ({
      label: answer.question,
      value: answer.answer || '—',
    }));

const buildCustomerRecord = (payload, nameMap) => {
  if (!payload) return null;
  const answers = payload.questionnaire_answers || [];
  return {
    id: payload.id,
    name:
      pickAnswer(answers, 'name') ||
      t('CONTESTS.CUSTOMERS_UNKNOWN_PARTICIPANT'),
    email: pickAnswer(answers, 'email'),
    phone: pickAnswer(answers, ['phone', 'phone_number']),
    submittedAt: payload.created_at,
    status: payload.questionnaire_status,
    contestId: payload.contest_id,
    contestName:
      nameMap[payload.contest_id] || t('CONTESTS.CUSTOMERS_UNKNOWN_CONTEST'),
    extras: extraAnswers(answers),
  };
};

const handleBack = () => {
  router.push(accountScopedRoute('contests_index'));
};

const fetchContestCustomers = async () => {
  if (
    !selectedContestId.value ||
    !selectedFromDate.value ||
    !selectedToDate.value
  ) {
    return;
  }
  hasFetchedCustomers.value = false;
  contestCustomers.value = [];
  try {
    const params = {
      contest_id: selectedContestId.value,
      from_date: selectedFromDate.value,
      to_date: selectedToDate.value,
    };
    const response = await store.dispatch('contests/fetchContestCustomers', {
      params,
    });
    const payloadArray = Array.isArray(response) ? response : [response];
    const nameMap = contestNameById.value;
    contestCustomers.value = payloadArray
      .map(item => buildCustomerRecord(item, nameMap))
      .filter(Boolean);
  } catch (error) {
    useAlert(error.message || t('CONTESTS.ERROR_FETCHING_CUSTOMERS'));
  } finally {
    hasFetchedCustomers.value = true;
  }
};

watch(
  () => selectedContest.value,
  contest => {
    if (!contest) {
      contestCustomers.value = [];
      return;
    }
    fetchContestCustomers();
  },
  { immediate: true }
);

watch([selectedFromDate, selectedToDate], () => {
  fetchContestCustomers();
});
</script>

<template>
  <div class="flex h-[calc(100vh-4rem)] w-full overflow-hidden">
    <div
      class="mx-auto flex h-full w-full min-w-full max-w-6xl flex-col gap-5 px-6 pt-6 md:px-8 lg:min-w-[35rem]"
    >
      <div class="flex flex-col gap-4">
        <div
          class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between"
        >
          <div>
            <h2 class="text-xl font-semibold text-n-slate-12">
              {{ headingLabel }}
            </h2>
            <p class="text-sm text-n-slate-11">
              {{ t('CONTESTS.CUSTOMERS_SUBHEADING') }}
            </p>
          </div>
          <Button size="sm" variant="ghost" @click="handleBack">
            <Icon icon="i-lucide-arrow-left" class="mr-2 size-4" />
            {{ t('CONTESTS.BACK_TO_LIST') }}
          </Button>
        </div>
      </div>

      <div
        class="flex-1 flex flex-col gap-5 overflow-y-auto pb-12 [scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden"
      >
        <section
          class="rounded-2xl border border-n-gray-4 bg-white py-2 px-5 dark:bg-n-solid-3/80"
        >
          <template v-if="selectedContest">
            <div class="p-3">
              <p class="text-[11px] uppercase tracking-wide text-n-slate-10">
                {{ t('CONTESTS.CUSTOMERS_SELECTED_CONTEST') }}
              </p>
              <h3 class="text-lg font-semibold text-n-slate-12">
                {{ selectedContest.name }}
              </h3>
              <div class="mt-4 grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                <div>
                  <p
                    class="text-[11px] uppercase tracking-wide text-n-slate-10"
                  >
                    {{ t('CONTESTS.TABLE_DATES') }}
                  </p>
                  <p class="text-sm text-n-slate-12">
                    {{
                      t('CONTESTS.TABLE_DATES_RANGE', {
                        start: formatDate(selectedContest.start_date),
                        end: formatDate(selectedContest.end_date),
                      })
                    }}
                  </p>
                </div>
                <div>
                  <p
                    class="text-[11px] uppercase tracking-wide text-n-slate-10"
                  >
                    {{ t('CONTESTS.TABLE_TRIGGER_WORDS') }}
                  </p>
                  <div
                    class="mt-1 flex max-h-20 flex-wrap gap-1 overflow-y-scroll pr-1 text-xs text-n-slate-11 [scrollbar-width:none] [&::-webkit-scrollbar]:w-2 [&::-webkit-scrollbar-thumb]:rounded-full [&::-webkit-scrollbar-thumb]:bg-n-slate-7 [&::-webkit-scrollbar-track]:rounded-full [&::-webkit-scrollbar-track]:bg-n-alpha-3"
                  >
                    <span
                      v-for="word in selectedContest.trigger_words"
                      :key="`${selectedContest.id}-${word}`"
                      class="inline-flex items-center gap-1 rounded-full bg-n-alpha-2 px-2 py-0.5"
                    >
                      <Icon
                        icon="i-lucide-hash"
                        class="size-3 text-n-slate-9"
                      />
                      {{ word }}
                    </span>
                    <span v-if="!(selectedContest.trigger_words || []).length">
                      {{ t('CONTESTS.TABLE_TRIGGER_WORDS_EMPTY') }}
                    </span>
                  </div>
                </div>
                <div>
                  <p
                    class="text-[11px] uppercase tracking-wide text-n-slate-10"
                  >
                    {{ t('CONTESTS.TABLE_DESCRIPTION') }}
                  </p>
                  <p
                    class="max-h-20 overflow-y-scroll pr-1 text-sm text-n-slate-12 [scrollbar-width:none] [&::-webkit-scrollbar]:w-2 [&::-webkit-scrollbar-thumb]:rounded-full [&::-webkit-scrollbar-thumb]:bg-n-slate-7 [&::-webkit-scrollbar-track]:rounded-full [&::-webkit-scrollbar-track]:bg-n-alpha-3"
                  >
                    {{
                      selectedContest.description ||
                      t('CONTESTS.CARD_NO_DESCRIPTION')
                    }}
                  </p>
                </div>
                <div>
                  <p
                    class="text-[11px] uppercase tracking-wide text-n-slate-10"
                  >
                    {{ t('CONTESTS.TABLE_TERMS') }}
                  </p>
                  <p
                    class="max-h-20 overflow-y-scroll pr-1 text-sm text-n-slate-12 [scrollbar-width:none] [&::-webkit-scrollbar]:w-2 [&::-webkit-scrollbar-thumb]:rounded-full [&::-webkit-scrollbar-thumb]:bg-n-slate-7 [&::-webkit-scrollbar-track]:rounded-full [&::-webkit-scrollbar-track]:bg-n-alpha-3"
                  >
                    {{ selectedContest.terms || t('CONTESTS.CARD_NO_TERMS') }}
                  </p>
                </div>
              </div>
            </div>
          </template>
          <template v-else>
            <div class="py-10 text-center text-sm text-n-slate-11">
              {{ t('CONTESTS.CUSTOMERS_EMPTY') }}
            </div>
          </template>
        </section>

        <section
          class="rounded-2xl border border-n-gray-4 bg-white p-5 dark:bg-n-solid-3/80"
        >
          <header
            class="flex flex-col gap-2 border-b border-n-gray-3 pb-4 sm:flex-row sm:items-center sm:justify-between"
          >
            <div>
              <h3 class="text-base font-semibold text-n-slate-12">
                {{ t('CONTESTS.CUSTOMERS_SECTION_TITLE') }}
              </h3>
            </div>
            <p class="text-xs uppercase tracking-wide text-n-slate-10">
              {{
                t('CONTESTS.CUSTOMERS_COUNT_LABEL', {
                  count: contestCustomers.length || 0,
                })
              }}
            </p>
          </header>

          <div class="mt-4 flex flex-col gap-2 max-w-sm">
            <p class="text-[11px] uppercase tracking-wide text-n-slate-10">
              {{ t('CONTESTS.CUSTOMERS_DATE_RANGE_LABEL') }}
            </p>
            <div class="flex flex-row gap-2 max-[425px]:flex-col xs:flex-row">
              <input
                v-model="selectedFromDate"
                type="date"
                class="w-full rounded-md border border-n-alpha-3 bg-white px-4 py-2 text-sm text-n-slate-12 outline-none transition focus:border-n-blue-9 dark:bg-n-solid-3"
              />
              <input
                v-model="selectedToDate"
                type="date"
                class="w-full rounded-md border border-n-alpha-3 bg-white px-4 py-2 text-sm text-n-slate-12 outline-none transition focus:border-n-blue-9 dark:bg-n-solid-3"
              />
            </div>
          </div>

          <div
            v-if="isLoadingEntries"
            class="py-12 text-center text-sm text-n-slate-11"
          >
            {{ t('CONTESTS.CUSTOMERS_LOADING_CUSTOMERS') }}
          </div>
          <div v-else-if="contestCustomers.length" class="mt-4 space-y-3">
            <article
              v-for="customer in contestCustomers"
              :key="customer.id"
              class="rounded-xl border border-n-alpha-1 p-4 dark:border-n-alpha-4"
            >
              <div class="grid gap-3 sm:grid-cols-4">
                <div>
                  <p
                    class="text-[11px] uppercase tracking-wide text-n-slate-10"
                  >
                    {{ t('CONTESTS.CUSTOMERS_FIELD_NAME') }}
                  </p>
                  <p class="text-sm font-semibold text-n-slate-12">
                    {{ customer.name }}
                  </p>
                </div>
                <div>
                  <p
                    class="text-[11px] uppercase tracking-wide text-n-slate-10"
                  >
                    {{ t('CONTESTS.CUSTOMERS_FIELD_EMAIL') }}
                  </p>
                  <p class="text-sm text-n-slate-12 truncate">
                    {{ customer.email || '—' }}
                  </p>
                </div>
                <div>
                  <p
                    class="text-[11px] uppercase tracking-wide text-n-slate-10"
                  >
                    {{ t('CONTESTS.CUSTOMERS_FIELD_PHONE') }}
                  </p>
                  <p class="text-sm text-n-slate-12">
                    {{ customer.phone || '—' }}
                  </p>
                </div>
                <div>
                  <p
                    class="text-[11px] uppercase tracking-wide text-n-slate-10"
                  >
                    {{ t('CONTESTS.CUSTOMERS_FIELD_SUBMITTED_AT') }}
                  </p>
                  <p class="text-sm text-n-slate-12">
                    {{ formatDateTime(customer.submittedAt) }}
                  </p>
                </div>
              </div>
            </article>
          </div>
          <div
            v-else-if="hasFetchedCustomers"
            class="py-12 text-center text-sm text-n-slate-11"
          >
            {{ t('CONTESTS.CUSTOMERS_EMPTY') }}
          </div>
        </section>
      </div>
    </div>
  </div>
</template>
