<script setup>
import { computed, onMounted, ref } from 'vue';
import { useStore } from 'vuex';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import ContestForm from '../components/ContestForm.vue';

const store = useStore();
const { accountScopedRoute } = useAccount();
const { t } = useI18n();

const createDialogRef = ref(null);
const createFormKey = ref(0);
const deleteDialogRef = ref(null);
const deleteTarget = ref(null);
const editDialogRef = ref(null);
const editFormKey = ref(0);
const editTarget = ref(null);

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
</script>

<template>
  <div
    class="mx-auto flex w-full max-w-8xl flex-col gap-6 px-6 pb-10 pt-6 md:px-8"
  >
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
        <RouterLink :to="accountScopedRoute('contests_reports')">
          <Button outline slate>
            {{ t('CONTESTS.LIST_VIEW_REPORTS') }}
          </Button>
        </RouterLink>
        <Button @click="openCreateDialog">
          {{ t('CONTESTS.LIST_CREATE_BUTTON') }}
        </Button>
      </div>
    </div>

    <div class="grid gap-4 md:grid-cols-2">
      <div
        class="flex items-center gap-3 rounded-2xl border border-n-alpha-3 bg-white px-5 py-4 shadow-sm dark:bg-n-solid-2"
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
        class="flex items-center gap-3 rounded-2xl border border-n-alpha-3 bg-white px-5 py-4 shadow-sm dark:bg-n-solid-2"
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

    <div
      v-if="uiFlags.isFetching"
      class="rounded-2xl border border-n-alpha-2 bg-white px-6 py-10 text-center text-sm text-n-slate-11 dark:bg-n-solid-2"
    >
      {{ t('CONTESTS.LOADING') }}
    </div>
    <div
      v-else
      class="rounded-2xl border border-n-alpha-2 bg-white shadow-sm dark:bg-n-solid-2"
    >
      <div
        class="max-h-[46rem] overflow-y-auto scrollbar-thin scrollbar-track-transparent scrollbar-thumb-transparent [scrollbar-width:none] [-ms-overflow-style:none]"
      >
        <table class="min-w-full divide-y divide-n-alpha-2 text-left text-sm">
          <thead
            class="bg-n-alpha-1/60 uppercase tracking-wide text-n-slate-11"
          >
            <tr>
              <th class="px-6 py-3 font-medium">
                {{ t('CONTESTS.TABLE_NAME') }}
              </th>
              <th class="px-6 py-3 font-medium">
                {{ t('CONTESTS.TABLE_TRIGGER_WORDS') }}
              </th>
              <th class="px-6 py-3 font-medium">
                {{ t('CONTESTS.TABLE_DATES') }}
              </th>
              <th class="px-6 py-3 font-medium">
                {{ t('CONTESTS.TABLE_DESCRIPTION') }}
              </th>
              <th class="px-6 py-3 font-medium">
                {{ t('CONTESTS.TABLE_TERMS') }}
              </th>
              <th class="px-6 py-3 font-medium">
                {{ t('CONTESTS.TABLE_ACTIONS') }}
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-n-alpha-2 text-n-slate-12">
            <tr
              v-for="contest in contests"
              :key="contest.id"
              class="group transition hover:bg-n-alpha-1/50"
            >
              <td class="px-6 py-4">
                <div class="font-medium text-n-slate-12">
                  {{ contest.name }}
                </div>
              </td>
              <td class="px-6 py-4">
                <div
                  class="relative flex flex-wrap items-center gap-2 max-w-60 max-h-20 overflow-y-auto scrollbar-thin scrollbar-track-transparent scrollbar-thumb-transparent [scrollbar-width:none] hover:[scrollbar-width:thin] [-ms-overflow-style:none] hover:[-ms-overflow-style:auto] [&::-webkit-scrollbar]:hidden hover:[&::-webkit-scrollbar]:block hover:[&::-webkit-scrollbar-thumb]:bg-n-slate-7/70 after:absolute after:right-0 after:top-0 after:h-full after:w-px after:bg-n-slate-8/30 after:opacity-0 after:transition-opacity hover:after:opacity-80"
                >
                  <span
                    v-for="word in contest.trigger_words"
                    :key="`${contest.id}-${word}`"
                    class="inline-flex items-center gap-1 rounded-full bg-n-alpha-2 px-2 py-0.5 text-xs text-n-slate-11"
                  >
                    <Icon
                      icon="i-lucide-hash"
                      class="size-3.5 text-n-slate-10"
                    />
                    <span>{{ word }}</span>
                  </span>
                  <span
                    v-if="!(contest.trigger_words || []).length"
                    class="text-xs text-n-slate-10"
                  >
                    {{ t('CONTESTS.TABLE_TRIGGER_WORDS_EMPTY') }}
                  </span>
                </div>
              </td>
              <td class="px-6 py-4">
                <div class="text-sm text-n-slate-12">
                  {{
                    t('CONTESTS.TABLE_DATES_RANGE', {
                      start: formatDate(contest.start_date),
                      end: formatDate(contest.end_date),
                    })
                  }}
                </div>
              </td>
              <td class="px-6 py-4">
                <div
                  class="relative max-w-72 min-w-32 max-h-20 overflow-y-auto pr-1 text-sm text-n-slate-11 whitespace-pre-line break-words scrollbar-thin scrollbar-track-transparent scrollbar-thumb-transparent [scrollbar-width:none] hover:[scrollbar-width:thin] [-ms-overflow-style:none] hover:[-ms-overflow-style:auto] [&::-webkit-scrollbar]:hidden hover:[&::-webkit-scrollbar]:block hover:[&::-webkit-scrollbar-thumb]:bg-n-slate-7/70 after:absolute after:right-0 after:top-0 after:h-full after:w-px after:bg-n-slate-8/30 after:opacity-0 after:transition-opacity hover:after:opacity-80"
                >
                  {{ contest.description || t('CONTESTS.CARD_NO_DESCRIPTION') }}
                </div>
              </td>
              <td class="px-6 py-4">
                <div
                  class="relative max-w-72 min-w-32 max-h-20 overflow-y-auto pr-1 text-sm text-n-slate-11 whitespace-pre-line break-words scrollbar-thin scrollbar-track-transparent scrollbar-thumb-transparent [scrollbar-width:none] hover:[scrollbar-width:thin] [-ms-overflow-style:none] hover:[-ms-overflow-style:auto] [&::-webkit-scrollbar]:hidden hover:[&::-webkit-scrollbar]:block hover:[&::-webkit-scrollbar-thumb]:bg-n-slate-7/70 after:absolute after:right-0 after:top-0 after:h-full after:w-px after:bg-n-slate-8/30 after:opacity-0 after:transition-opacity hover:after:opacity-80"
                >
                  {{ contest.terms || t('CONTESTS.CARD_NO_TERMS') }}
                </div>
              </td>
              <td class="px-6 py-4">
                <div class="flex items-center gap-1">
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
              </td>
            </tr>
            <tr v-if="!contests.length">
              <td
                class="px-6 py-6 text-center text-sm text-n-slate-11"
                colspan="6"
              >
                {{ t('CONTESTS.EMPTY_MESSAGE') }}
              </td>
            </tr>
          </tbody>
        </table>
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
  </div>
</template>
