<script setup>
import { computed, onMounted, ref } from 'vue';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import ContestForm from '../components/ContestForm.vue';
import ContestShow from './ContestShow.vue';

const store = useStore();
const { t } = useI18n();

const createDialogRef = ref(null);
const createFormKey = ref(0);
const deleteDialogRef = ref(null);
const deleteTarget = ref(null);
const editDialogRef = ref(null);
const editFormKey = ref(0);
const editTarget = ref(null);
const showDialogRef = ref(null);
const showDialogKey = ref(0);
const showContestId = ref(null);

const contests = computed(() => store.getters['contests/getRecords']);
const uiFlags = computed(() => store.getters['contests/getUIFlags']);
const hasLoaded = computed(() => store.getters['contests/hasLoaded']);
const totalContests = computed(() => contests.value.length);
const totalTriggerWords = computed(() =>
  contests.value.reduce((sum, contest) => {
    if (!Array.isArray(contest.trigger_words)) {
      return sum;
    }
    const validWords = contest.trigger_words.filter(word => !!word);
    return sum + validWords.length;
  }, 0)
);

const formatDate = value => {
  if (!value) return '—';
  return new Intl.DateTimeFormat(undefined, {
    year: 'numeric',
    month: 'short',
    day: '2-digit',
  }).format(new Date(value));
};

const toDateInputValue = value => {
  if (!value) return '';
  if (typeof value === 'string' && value.includes('T')) {
    return value.split('T')[0];
  }
  return value;
};

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

const openCreateDialog = () => {
  createFormKey.value += 1;
  createDialogRef.value?.open();
};

const closeCreateDialog = () => {
  createDialogRef.value?.close();
};

const handleCreate = async payload => {
  try {
    if (import.meta.env?.DEV) {
      // eslint-disable-next-line no-console
      console.debug('[contests] create:submit', payload);
    }
    await store.dispatch('contests/create', {
      payload,
    });
    useAlert(t('CONTESTS.CREATE_SUCCESS'));
    closeCreateDialog();
    if (import.meta.env?.DEV) {
      // eslint-disable-next-line no-console
      console.debug('[contests] create:success');
    }
  } catch (error) {
    useAlert(error.message || t('CONTESTS.ERROR_CREATE'));
    if (import.meta.env?.DEV) {
      // eslint-disable-next-line no-console
      console.error('[contests] create:error', error);
    }
  }
};

const handleDialogClosed = () => {
  createFormKey.value += 1;
};

const openDeleteDialog = contest => {
  deleteTarget.value = contest;
  deleteDialogRef.value?.open();
};

const closeDeleteDialog = () => {
  deleteDialogRef.value?.close();
};

const handleDeleteDialogClosed = () => {
  deleteTarget.value = null;
};

const handleDelete = async () => {
  if (!deleteTarget.value) return;
  const targetId = deleteTarget.value?.id;
  try {
    if (import.meta.env?.DEV) {
      // eslint-disable-next-line no-console
      console.debug('[contests] delete:submit', targetId);
    }
    await store.dispatch('contests/delete', {
      id: targetId,
    });
    useAlert(t('CONTESTS.DELETE_SUCCESS'));
    closeDeleteDialog();
    if (import.meta.env?.DEV && targetId) {
      // eslint-disable-next-line no-console
      console.debug('[contests] delete:success', targetId);
    }
  } catch (error) {
    useAlert(error.message || t('CONTESTS.ERROR_DELETE'));
    if (import.meta.env?.DEV) {
      // eslint-disable-next-line no-console
      console.error('[contests] delete:error', error);
    }
  }
};

const openEditDialog = contest => {
  editTarget.value = {
    ...contest,
    start_date: toDateInputValue(contest.start_date),
    end_date: toDateInputValue(contest.end_date),
  };
  editFormKey.value += 1;
  editDialogRef.value?.open();
};

const closeEditDialog = () => {
  editDialogRef.value?.close();
};

const handleEditDialogClosed = () => {
  editFormKey.value += 1;
  editTarget.value = null;
};

const handleEdit = async payload => {
  if (!editTarget.value) return;
  const targetId = editTarget.value?.id;
  try {
    if (import.meta.env?.DEV) {
      // eslint-disable-next-line no-console
      console.debug('[contests] update:submit', targetId, payload);
    }
    await store.dispatch('contests/update', {
      id: targetId,
      payload,
    });
    useAlert(t('CONTESTS.EDIT_SUCCESS'));
    closeEditDialog();
    if (import.meta.env?.DEV && targetId) {
      // eslint-disable-next-line no-console
      console.debug('[contests] update:success', targetId);
    }
  } catch (error) {
    useAlert(error.message || t('CONTESTS.ERROR_UPDATE'));
    if (import.meta.env?.DEV) {
      // eslint-disable-next-line no-console
      console.error('[contests] update:error', error);
    }
  }
};

const handleContestClick = contest => {
  showContestId.value = contest.id;
  showDialogKey.value += 1;
  showDialogRef.value?.open();
};

const handleShowDialogClosed = () => {
  showContestId.value = null;
  showDialogKey.value += 1;
};

const closeShowDialog = () => {
  showDialogRef.value?.close();
};

const handleShowEdit = contest => {
  closeShowDialog();
  openEditDialog(contest);
};
</script>

<template>
  <div class="flex h-[calc(100vh-4rem)] w-full overflow-hidden">
    <div
      class="mx-auto flex w-full min-w-full max-w-6xl flex-col px-6 pt-6 md:px-8 lg:min-w-[35rem]"
    >
      <div class="flex-shrink-0 pb-6">
        <div
          class="flex flex-col gap-4 md:flex-row md:items-center md:justify-between"
        >
          <div class="space-y-1">
            <h2 class="text-lg font-semibold text-n-slate-12">
              {{ t('CONTESTS.LIST_HEADING') }}
            </h2>
            <p class="text-sm text-n-slate-11">
              {{ t('CONTESTS.LIST_SUBHEADING') }}
            </p>
          </div>

          <div class="flex gap-3">
            <!-- <RouterLink :to="accountScopedRoute('contests_reports')">
              <Button outline slate>
                {{ t('CONTESTS.LIST_VIEW_REPORTS') }}
              </Button>
            </RouterLink> -->
            <Button @click="openCreateDialog">
              {{ t('CONTESTS.LIST_CREATE_BUTTON') }}
            </Button>
          </div>
        </div>

        <div class="mt-6 grid gap-4 md:grid-cols-2">
          <div
            class="flex items-center gap-3 rounded-2xl border border-n-gray-4 bg-white px-3 py-1 shadow-sm dark:bg-n-solid-2 md:px-5 md:py-4"
          >
            <div
              class="grid size-10 place-content-center rounded-full bg-n-blue-3 text-n-blue-10"
            >
              <Icon icon="i-lucide-trophy" class="size-5" />
            </div>
            <div>
              <p class="text-xs uppercase tracking-wide text-n-slate-10">
                {{ t('CONTESTS.METRICS_ACTIVE_CONTESTS') }}
              </p>
              <p class="text-2xl font-semibold text-n-slate-12">
                {{ totalContests }}
              </p>
            </div>
          </div>
          <div
            class="flex items-center gap-3 rounded-2xl border border-n-gray-4 bg-white px-3 py-1 shadow-sm dark:bg-n-solid-2 md:px-5 md:py-4"
          >
            <div
              class="grid size-10 place-content-center rounded-full bg-n-teal-3 text-n-teal-9"
            >
              <Icon icon="i-lucide-hash" class="size-5" />
            </div>
            <div>
              <p class="text-xs uppercase tracking-wide text-n-slate-10">
                {{ t('CONTESTS.METRICS_TRIGGER_WORDS') }}
              </p>
              <p class="text-2xl font-semibold text-n-slate-12">
                {{ totalTriggerWords }}
              </p>
            </div>
          </div>
        </div>
      </div>

      <div
        class="flex-1 overflow-y-auto pb-10 [scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden"
      >
        <div
          v-if="uiFlags.isFetching"
          class="rounded-2xl border border-n-alpha-2 bg-white px-6 py-10 text-center text-sm text-n-slate-11 dark:bg-n-solid-2"
        >
          {{ t('CONTESTS.LOADING') }}
        </div>
        <div v-else class="flex flex-col gap-3">
          <article
            v-for="contest in contests"
            :key="contest.id"
            class="flex flex-wrap items-start gap-3 rounded-2xl border border-n-gray-4 bg-white px-5 py-3 shadow-sm transition-colors hover:border-n-alpha-4 hover:bg-n-alpha-1 cursor-pointer dark:bg-n-solid-2 dark:hover:bg-n-solid-3 xl:grid xl:grid-cols-[1.3fr_1fr_0.9fr_1.2fr_1.2fr_auto] xl:gap-3"
            @click="handleContestClick(contest)"
          >
            <div
              class="min-w-[10rem] flex-1 space-y-1 pb-4 overflow-y-auto [scrollbar-width:thin] [&::-webkit-scrollbar]:w-1.5 xl:pb-0 xl:overflow-visible"
            >
              <span class="text-[11px] uppercase tracking-wide text-n-slate-10">
                {{ t('CONTESTS.TABLE_NAME') }}
              </span>
              <div
                class="flex flex-wrap items-center gap-2 text-sm font-semibold text-n-slate-12"
              >
                {{ contest.name }}
              </div>
            </div>

            <div
              class="min-w-[9rem] flex-1 space-y-1 pb-4 overflow-y-auto [scrollbar-width:thin] [&::-webkit-scrollbar]:w-1.5 xl:pb-0 xl:overflow-visible"
            >
              <p class="text-[11px] uppercase text-n-slate-10">
                {{ t('CONTESTS.TABLE_TRIGGER_WORDS') }}
              </p>
              <div
                class="flex max-h-12 max-w-48 flex-wrap gap-1 overflow-y-auto overflow-x-hidden text-[11px] text-n-slate-11 [scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden"
              >
                <span
                  v-for="word in contest.trigger_words"
                  :key="`${contest.id}-${word}`"
                  class="inline-flex items-center gap-1 rounded-full bg-n-alpha-2 px-2 py-0.5"
                >
                  <Icon icon="i-lucide-hash" class="size-3 text-n-slate-9" />
                  {{ word }}
                </span>
                <span v-if="!(contest.trigger_words || []).length">
                  {{ t('CONTESTS.TABLE_TRIGGER_WORDS_EMPTY') }}
                </span>
              </div>
            </div>

            <div
              class="min-w-[5rem] flex-1 pb-4 space-y-1 overflow-y-auto overflow-x-hidden text-sm text-n-slate-11 xl:pb-0 xl:overflow-visible"
            >
              <span class="text-[11px] uppercase tracking-wide text-n-slate-10">
                {{ t('CONTESTS.TABLE_DATES') }}
              </span>
              <p>
                {{
                  t('CONTESTS.TABLE_DATES_RANGE', {
                    start: formatDate(contest.start_date),
                    end: formatDate(contest.end_date),
                  })
                }}
              </p>
            </div>

            <div
              class="min-w-[12rem] md:min-w-[14rem] flex-1 space-y-1 overflow-y-auto overflow-x-hidden text-sm text-n-slate-11 [scrollbar-width:thin] [&::-webkit-scrollbar]:h-1 xl:overflow-visible"
            >
              <span class="text-[11px] uppercase tracking-wide text-n-slate-10">
                {{ t('CONTESTS.TABLE_DESCRIPTION') }}
              </span>
              <span
                class="block max-h-16 overflow-y-auto overflow-x-hidden break-words [scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden"
              >
                {{ contest.description || t('CONTESTS.CARD_NO_DESCRIPTION') }}
              </span>
            </div>

            <div
              class="min-w-[12rem] flex-1 space-y-1 overflow-y-auto overflow-x-hidden text-sm text-n-slate-11 [scrollbar-width:thin] [&::-webkit-scrollbar]:h-1 xl:overflow-visible"
            >
              <span class="text-[11px] uppercase tracking-wide text-n-slate-10">
                {{ t('CONTESTS.TABLE_TERMS') }}
              </span>
              <span
                class="block max-h-16 overflow-y-auto overflow-x-hidden break-words [scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden"
              >
                {{ contest.terms || t('CONTESTS.CARD_NO_TERMS') }}
              </span>
            </div>

            <div
              class="ml-auto flex items-center gap-1 xl:justify-end"
              @click.stop
            >
              <Button
                icon="i-lucide-pencil"
                slate
                ghost
                xs
                :aria-label="t('CONTESTS.TABLE_EDIT_ACTION')"
                @click="openEditDialog(contest)"
              />
              <Button
                icon="i-lucide-trash-2"
                ruby
                ghost
                xs
                :aria-label="t('CONTESTS.TABLE_DELETE_ACTION')"
                @click="openDeleteDialog(contest)"
              />
            </div>

            <div
              class="w-full space-y-1 overflow-y-auto overflow-x-hidden text-sm text-n-slate-11 [scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden xl:col-span-full"
            >
              <span class="text-[11px] uppercase tracking-wide text-n-slate-10">
                {{ t('CONTESTS.TABLE_QUESTIONNAIRE') }}
              </span>
              <div
                class="flex max-h-28 flex-col gap-1 overflow-y-auto overflow-x-hidden rounded-xl border border-n-alpha-3 bg-n-alpha-1/40 p-3 [scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden dark:border-n-alpha-4 dark:bg-n-solid-2/40"
              >
                <template
                  v-if="contest.questionnaire && contest.questionnaire.length"
                >
                  <div
                    v-for="(item, index) in contest.questionnaire"
                    :key="`${contest.id}-question-${index}`"
                    class="rounded-lg bg-white/80 px-3 py-2 text-sm font-medium text-n-slate-12 dark:bg-n-solid-3"
                  >
                    <p class="text-sm font-semibold text-n-slate-12">
                      {{ item.question }}
                    </p>
                    <p
                      v-if="item.description"
                      class="text-[11px] text-n-slate-11"
                    >
                      {{ item.description }}
                    </p>
                  </div>
                </template>
                <span v-else>
                  {{ t('CONTESTS.TABLE_QUESTIONNAIRE_EMPTY') }}
                </span>
              </div>
            </div>
          </article>

          <div
            v-if="!contests.length"
            class="col-span-full rounded-2xl border border-dashed border-n-alpha-3 bg-white py-16 text-center text-sm text-n-slate-11 dark:bg-n-solid-2"
          >
            {{ t('CONTESTS.EMPTY_MESSAGE') }}
          </div>
        </div>
      </div>

      <Dialog
        ref="createDialogRef"
        width="3xl"
        :show-cancel-button="false"
        :show-confirm-button="false"
        @close="handleDialogClosed"
      >
        <ContestForm
          :key="createFormKey"
          :heading="t('CONTESTS.CREATE_HEADING')"
          :submit-label="t('CONTESTS.CREATE_SUBMIT')"
          @submit="handleCreate"
          @cancel="closeCreateDialog"
        />
      </Dialog>

      <Dialog
        ref="deleteDialogRef"
        type="alert"
        :title="t('CONTESTS.DELETE_CONFIRM_TITLE')"
        :description="
          deleteTarget
            ? t('CONTESTS.DELETE_CONFIRM_MESSAGE', {
                name: deleteTarget.name,
              })
            : ''
        "
        :confirm-button-label="t('CONTESTS.DELETE_CONFIRM_SUBMIT')"
        :cancel-button-label="t('CONTESTS.DELETE_CONFIRM_CANCEL')"
        @confirm="handleDelete"
        @close="handleDeleteDialogClosed"
      />

      <Dialog
        ref="editDialogRef"
        width="3xl"
        :show-cancel-button="false"
        :show-confirm-button="false"
        @close="handleEditDialogClosed"
      >
        <template v-if="editTarget">
          <ContestForm
            :key="editFormKey"
            :contest="editTarget"
            :heading="t('CONTESTS.EDIT_HEADING')"
            :submit-label="t('CONTESTS.EDIT_SUBMIT')"
            @submit="handleEdit"
            @cancel="closeEditDialog"
          />
        </template>
      </Dialog>

      <Dialog
        ref="showDialogRef"
        width="3xl"
        :show-cancel-button="false"
        :show-confirm-button="false"
        @close="handleShowDialogClosed"
      >
        <ContestShow
          v-if="showContestId"
          :key="showDialogKey"
          :contest-id="showContestId"
          :show-back-button="false"
          @close="closeShowDialog"
          @edit="handleShowEdit"
        />
      </Dialog>
    </div>
  </div>
</template>
