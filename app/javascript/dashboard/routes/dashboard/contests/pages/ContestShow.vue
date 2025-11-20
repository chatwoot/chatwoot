<script setup>
import { computed, watch } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  contestId: {
    type: [String, Number],
    default: null,
  },
});

const emit = defineEmits(['close', 'edit']);

const store = useStore();
const route = useRoute();
const { t } = useI18n();

const resolvedContestId = computed(
  () => props.contestId ?? route.params.contestId
);

const contest = computed(() => {
  if (!resolvedContestId.value) {
    return null;
  }
  const contests = store.getters['contests/getRecords'];
  return contests.find(c => String(c.id) === String(resolvedContestId.value));
});

const uiFlags = computed(() => store.getters['contests/getUIFlags']);

const formatDate = value => {
  if (!value) return '—';
  return new Intl.DateTimeFormat(undefined, {
    year: 'numeric',
    month: 'short',
    day: '2-digit',
  }).format(new Date(value));
};

const fetchContest = async () => {
  if (!resolvedContestId.value) return;
  try {
    await store.dispatch('contests/show', {
      id: resolvedContestId.value,
    });
  } catch (error) {
    useAlert(error.message || t('CONTESTS.ERROR_FETCHING'));
    emit('close');
  }
};

watch(
  () => resolvedContestId.value,
  () => {
    fetchContest();
  },
  { immediate: true }
);

const descriptionTextClass =
  'max-h-56 overflow-y-auto whitespace-pre-wrap text-sm text-n-slate-11 [scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden';

const handleEdit = () => {
  if (!contest.value) return;
  emit('edit', contest.value);
};
</script>

<template>
  <div class="w-full flex justify-center">
    <div
      class="w-full max-w-3xl md:max-w-4xl lg:max-w-5xl px-4 py-4 sm:px-6 max-h-[85vh] overflow-y-auto [scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden"
    >
      <div
        v-if="uiFlags.isFetchingItem"
        class="rounded-2xl border border-n-alpha-2 bg-white px-6 py-10 text-center text-sm text-n-slate-11 dark:bg-n-solid-2"
      >
        {{ t('CONTESTS.LOADING') }}
      </div>
      <div
        v-else-if="!contest"
        class="rounded-2xl border border-n-alpha-2 bg-white px-6 py-10 text-center text-sm text-n-slate-11 dark:bg-n-solid-2"
      >
        {{ t('CONTESTS.SHOW_NOT_FOUND') }}
      </div>
      <div v-else class="space-y-8">
        <div
          class="flex flex-col gap-4 rounded-2xl bg-n-alpha-1 px-4 py-5 dark:bg-n-solid-3/40 md:flex-row md:items-center md:justify-between md:px-6"
        >
          <div>
            <p class="text-xs uppercase tracking-widest text-n-slate-9">
              {{ t('CONTESTS.TABLE_NAME') }}
            </p>
            <p class="text-2xl font-semibold text-n-slate-12 md:text-3xl">
              {{ contest.name }}
            </p>
          </div>
          <div class="flex flex-wrap gap-3">
            <div
              class="flex items-center gap-3 rounded-2xl bg-white px-4 py-2 text-sm text-n-slate-12 shadow-sm dark:bg-n-solid-3"
            >
              <Icon icon="i-lucide-calendar" class="size-5 text-n-slate-10" />
              <div>
                <p class="text-[11px] uppercase tracking-wide text-n-slate-9">
                  {{ t('CONTESTS.FORM_START_DATE_LABEL') }}
                </p>
                <p class="font-semibold">
                  {{ formatDate(contest.start_date) }}
                </p>
              </div>
            </div>
            <div
              class="flex items-center gap-3 rounded-2xl bg-white px-4 py-2 text-sm text-n-slate-12 shadow-sm dark:bg-n-solid-3"
            >
              <Icon icon="i-lucide-flag" class="size-5 text-n-slate-10" />
              <div>
                <p class="text-[11px] uppercase tracking-wide text-n-slate-9">
                  {{ t('CONTESTS.FORM_END_DATE_LABEL') }}
                </p>
                <p class="font-semibold">
                  {{ formatDate(contest.end_date) }}
                </p>
              </div>
            </div>
          </div>
        </div>

        <div>
          <h2
            class="mb-3 text-sm font-semibold uppercase tracking-wide text-n-slate-10"
          >
            {{ t('CONTESTS.TABLE_TRIGGER_WORDS') }}
          </h2>
          <div
            v-if="contest.trigger_words && contest.trigger_words.length"
            class="flex flex-wrap gap-2"
          >
            <span
              v-for="word in contest.trigger_words"
              :key="word"
              class="inline-flex items-center gap-1 rounded-full bg-n-alpha-2 px-3 py-1.5 text-sm text-n-slate-11"
            >
              <Icon icon="i-lucide-hash" class="size-4 text-n-slate-9" />
              {{ word }}
            </span>
          </div>
          <p v-else class="text-sm text-n-slate-11">
            {{ t('CONTESTS.TABLE_TRIGGER_WORDS_EMPTY') }}
          </p>
        </div>

        <div class="grid gap-5 md:grid-cols-2">
          <section class="rounded-2xl border border-n-gray-5 p-5">
            <h3 class="text-xs uppercase tracking-wide text-n-slate-9">
              {{ t('CONTESTS.TABLE_DESCRIPTION') }}
            </h3>
            <p class="mt-3" :class="descriptionTextClass">
              <template v-if="contest.description">
                {{ contest.description }}
              </template>
              <template v-else>
                {{ t('CONTESTS.CARD_NO_DESCRIPTION') }}
              </template>
            </p>
          </section>

          <section class="rounded-2xl border border-n-gray-5 p-5">
            <h3 class="text-xs uppercase tracking-wide text-n-slate-9">
              {{ t('CONTESTS.TABLE_TERMS') }}
            </h3>
            <p class="mt-3" :class="descriptionTextClass">
              <template v-if="contest.terms">
                {{ contest.terms }}
              </template>
              <template v-else>
                {{ t('CONTESTS.CARD_NO_TERMS') }}
              </template>
            </p>
          </section>
        </div>

        <section class="rounded-2xl border border-n-gray-5 p-5">
          <h3 class="text-xs uppercase tracking-wide text-n-slate-9">
            {{ t('CONTESTS.TABLE_QUESTIONNAIRE') }}
          </h3>
          <div class="mt-3 space-y-3">
            <div
              v-if="contest.questionnaire && contest.questionnaire.length"
              class="space-y-3"
            >
              <div
                v-for="(item, index) in contest.questionnaire"
                :key="`${contest.id}-question-${index}`"
                class="rounded-xl border border-n-alpha-3 bg-n-alpha-1 p-4 dark:bg-n-solid-3"
              >
                <p class="text-sm font-semibold text-n-slate-12">
                  {{ item.question }}
                </p>
                <p
                  v-if="item.description"
                  class="mt-1 text-sm text-n-slate-11 whitespace-pre-wrap"
                >
                  {{ item.description }}
                </p>
              </div>
            </div>
            <p v-else class="text-sm text-n-slate-11">
              {{ t('CONTESTS.TABLE_QUESTIONNAIRE_EMPTY') }}
            </p>
          </div>
        </section>

        <div class="flex justify-end">
          <Button
            icon="i-lucide-pencil"
            sm
            type="button"
            :disabled="!contest"
            @click="handleEdit"
          >
            {{ t('CONTESTS.TABLE_EDIT_ACTION') }}
          </Button>
        </div>
      </div>
    </div>
  </div>
</template>
