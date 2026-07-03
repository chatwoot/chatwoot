<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import AutonomiaProspectingAPI from 'dashboard/api/autonomiaProspecting';

const { t } = useI18n();

const isLoading = ref(true);
const isCreating = ref(false);
const busyLeadId = ref(null);
const error = ref('');
const notice = ref('');
const lists = ref([]);
const selectedList = ref(null);
const allLeads = ref([]);
const form = ref({
  name: '',
  description: '',
});

const selectedLeadIds = computed(
  () => new Set((selectedList.value?.lead_ids || []).map(Number))
);
const listLeads = computed(() => selectedList.value?.leads || []);
const availableLeads = computed(() =>
  allLeads.value.filter(lead => !selectedLeadIds.value.has(Number(lead.id)))
);
const hasSelectedList = computed(() => Boolean(selectedList.value?.id));

const formatDate = value => {
  if (!value) return '-';
  return new Date(value).toLocaleDateString();
};

const formatLeadAddress = lead =>
  [lead.address, [lead.city, lead.state].filter(Boolean).join(' ')]
    .filter(Boolean)
    .join(t('PROSPECTING.SEARCH.ADDRESS_SEPARATOR'));

const fetchLists = async () => {
  const { data } = await AutonomiaProspectingAPI.getLists();
  lists.value = data.payload || [];
};

const fetchAllLeads = async () => {
  const { data } = await AutonomiaProspectingAPI.getLeads();
  allLeads.value = data.payload || [];
};

const selectList = async list => {
  if (!list?.id) return;

  error.value = '';
  notice.value = '';
  try {
    const { data } = await AutonomiaProspectingAPI.getList(list.id);
    selectedList.value = data.payload || null;
  } catch {
    error.value = t('PROSPECTING.ERRORS.LOAD_LIST');
  }
};

const loadPage = async () => {
  isLoading.value = true;
  error.value = '';
  try {
    await Promise.all([fetchLists(), fetchAllLeads()]);
    if (lists.value.length) {
      await selectList(lists.value[0]);
    }
  } catch {
    error.value = t('PROSPECTING.ERRORS.LOAD_LISTS');
  } finally {
    isLoading.value = false;
  }
};

const createList = async () => {
  if (!form.value.name.trim() || isCreating.value) return;

  isCreating.value = true;
  error.value = '';
  notice.value = '';
  try {
    const { data } = await AutonomiaProspectingAPI.createList({
      name: form.value.name.trim(),
      description: form.value.description.trim(),
    });
    form.value = { name: '', description: '' };
    await fetchLists();
    await selectList(data.payload);
    notice.value = t('PROSPECTING.LISTS.CREATED');
  } catch (e) {
    error.value =
      e?.response?.data?.error || t('PROSPECTING.ERRORS.CREATE_LIST');
  } finally {
    isCreating.value = false;
  }
};

const addLead = async lead => {
  if (!selectedList.value?.id || !lead?.id || busyLeadId.value) return;

  busyLeadId.value = lead.id;
  error.value = '';
  notice.value = '';
  try {
    const { data } = await AutonomiaProspectingAPI.addLeadToList(
      selectedList.value.id,
      lead.id
    );
    selectedList.value = data.payload || selectedList.value;
    await fetchLists();
    notice.value = t('PROSPECTING.LISTS.LEAD_ADDED');
  } catch (e) {
    error.value =
      e?.response?.data?.error || t('PROSPECTING.ERRORS.ADD_LEAD_TO_LIST');
  } finally {
    busyLeadId.value = null;
  }
};

const removeLead = async lead => {
  if (!selectedList.value?.id || !lead?.id || busyLeadId.value) return;

  busyLeadId.value = lead.id;
  error.value = '';
  notice.value = '';
  try {
    const { data } = await AutonomiaProspectingAPI.removeLeadFromList(
      selectedList.value.id,
      lead.id
    );
    selectedList.value = data.payload || selectedList.value;
    await fetchLists();
    notice.value = t('PROSPECTING.LISTS.LEAD_REMOVED');
  } catch (e) {
    error.value =
      e?.response?.data?.error || t('PROSPECTING.ERRORS.REMOVE_LEAD_FROM_LIST');
  } finally {
    busyLeadId.value = null;
  }
};

onMounted(loadPage);
</script>

<template>
  <main class="flex min-h-full flex-col bg-n-background">
    <header class="border-b border-n-weak px-6 py-4">
      <h1 class="text-xl font-semibold text-n-slate-12">
        {{ t('PROSPECTING.LISTS.TITLE') }}
      </h1>
    </header>

    <section
      class="flex min-h-0 flex-1 flex-col gap-4 overflow-y-auto px-6 py-5"
    >
      <form
        class="grid gap-3 rounded-lg border border-n-weak bg-n-solid-1 p-4 md:grid-cols-[minmax(12rem,1fr)_minmax(18rem,2fr)_9rem]"
        @submit.prevent="createList"
      >
        <label class="grid gap-1">
          <span class="text-xs font-medium text-n-slate-11">
            {{ t('PROSPECTING.LISTS.FIELDS.NAME') }}
          </span>
          <input
            v-model="form.name"
            class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
            :placeholder="t('PROSPECTING.LISTS.NAME_PLACEHOLDER')"
          />
        </label>
        <label class="grid gap-1">
          <span class="text-xs font-medium text-n-slate-11">
            {{ t('PROSPECTING.LISTS.FIELDS.DESCRIPTION') }}
          </span>
          <input
            v-model="form.description"
            class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
            :placeholder="t('PROSPECTING.LISTS.DESCRIPTION_PLACEHOLDER')"
          />
        </label>
        <button
          type="submit"
          class="self-end rounded-md bg-n-brand px-4 text-sm font-medium text-white disabled:cursor-not-allowed disabled:opacity-60 md:h-10"
          :disabled="isCreating || !form.name.trim()"
        >
          {{
            isCreating
              ? t('PROSPECTING.LISTS.CREATING')
              : t('PROSPECTING.LISTS.CREATE')
          }}
        </button>
      </form>

      <div
        v-if="notice"
        class="rounded-md bg-n-teal-3 px-4 py-3 text-sm text-n-teal-11"
      >
        {{ notice }}
      </div>
      <div
        v-if="error"
        class="rounded-md bg-n-ruby-3 px-4 py-3 text-sm text-n-ruby-11"
      >
        {{ error }}
      </div>

      <div
        class="grid min-h-[32rem] gap-4 lg:grid-cols-[minmax(16rem,22rem)_minmax(0,1fr)]"
      >
        <aside
          class="overflow-hidden rounded-lg border border-n-weak bg-n-solid-1"
        >
          <div class="border-b border-n-weak px-4 py-3">
            <h2 class="text-sm font-semibold text-n-slate-12">
              {{ t('PROSPECTING.LISTS.ALL_LISTS') }}
            </h2>
          </div>
          <div v-if="isLoading" class="px-4 py-8 text-sm text-n-slate-11">
            {{ t('PROSPECTING.STATES.LOADING') }}
          </div>
          <div
            v-else-if="!lists.length"
            class="px-4 py-8 text-sm text-n-slate-11"
          >
            {{ t('PROSPECTING.LISTS.EMPTY') }}
          </div>
          <div v-else class="max-h-[36rem] overflow-y-auto">
            <button
              v-for="list in lists"
              :key="list.id"
              type="button"
              class="grid w-full gap-1 border-b border-n-weak px-4 py-3 text-left text-sm last:border-b-0 hover:bg-n-solid-2"
              :class="{ 'bg-n-solid-2': selectedList?.id === list.id }"
              @click="selectList(list)"
            >
              <span class="truncate font-medium text-n-slate-12">
                {{ list.name }}
              </span>
              <span class="text-xs text-n-slate-10">
                {{
                  t('PROSPECTING.LISTS.LEADS_COUNT', {
                    count: list.leads_count || 0,
                  })
                }}
              </span>
              <span class="text-xs text-n-slate-10">
                {{ formatDate(list.created_at) }}
              </span>
            </button>
          </div>
        </aside>

        <section
          class="grid min-h-0 gap-4 lg:grid-cols-[minmax(0,1fr)_minmax(18rem,24rem)]"
        >
          <div
            class="overflow-hidden rounded-lg border border-n-weak bg-n-solid-1"
          >
            <div class="border-b border-n-weak px-4 py-3">
              <h2 class="text-sm font-semibold text-n-slate-12">
                {{
                  hasSelectedList
                    ? selectedList.name
                    : t('PROSPECTING.LISTS.DETAIL_TITLE')
                }}
              </h2>
              <p
                v-if="selectedList?.description"
                class="mt-1 text-sm text-n-slate-10"
              >
                {{ selectedList.description }}
              </p>
            </div>
            <div
              v-if="!hasSelectedList"
              class="px-4 py-8 text-sm text-n-slate-11"
            >
              {{ t('PROSPECTING.LISTS.SELECT_EMPTY') }}
            </div>
            <div
              v-else-if="!listLeads.length"
              class="px-4 py-8 text-sm text-n-slate-11"
            >
              {{ t('PROSPECTING.LISTS.LEADS_EMPTY') }}
            </div>
            <div v-else class="max-h-[36rem] overflow-y-auto">
              <article
                v-for="lead in listLeads"
                :key="lead.id"
                class="grid gap-3 border-b border-n-weak px-4 py-4 text-sm last:border-b-0 md:grid-cols-[minmax(0,1fr)_8rem]"
              >
                <div class="min-w-0">
                  <h3 class="truncate font-medium text-n-slate-12">
                    {{ lead.name }}
                  </h3>
                  <p class="truncate text-n-slate-10">
                    {{ formatLeadAddress(lead) }}
                  </p>
                  <p class="truncate text-n-slate-10">
                    {{ lead.phone || '-' }}
                  </p>
                </div>
                <button
                  type="button"
                  class="h-8 rounded-md border border-n-weak px-3 text-xs font-medium text-n-slate-12 hover:bg-n-solid-2 disabled:cursor-not-allowed disabled:opacity-60"
                  :disabled="busyLeadId === lead.id"
                  @click="removeLead(lead)"
                >
                  {{ t('PROSPECTING.LISTS.REMOVE_LEAD') }}
                </button>
              </article>
            </div>
          </div>

          <div
            class="overflow-hidden rounded-lg border border-n-weak bg-n-solid-1"
          >
            <div class="border-b border-n-weak px-4 py-3">
              <h2 class="text-sm font-semibold text-n-slate-12">
                {{ t('PROSPECTING.LISTS.ADD_LEADS_TITLE') }}
              </h2>
            </div>
            <div
              v-if="!hasSelectedList"
              class="px-4 py-8 text-sm text-n-slate-11"
            >
              {{ t('PROSPECTING.LISTS.SELECT_TO_ADD') }}
            </div>
            <div
              v-else-if="!availableLeads.length"
              class="px-4 py-8 text-sm text-n-slate-11"
            >
              {{ t('PROSPECTING.LISTS.NO_AVAILABLE_LEADS') }}
            </div>
            <div v-else class="max-h-[36rem] overflow-y-auto">
              <article
                v-for="lead in availableLeads"
                :key="lead.id"
                class="grid gap-3 border-b border-n-weak px-4 py-4 text-sm last:border-b-0"
              >
                <div class="min-w-0">
                  <h3 class="truncate font-medium text-n-slate-12">
                    {{ lead.name }}
                  </h3>
                  <p class="truncate text-n-slate-10">
                    {{ formatLeadAddress(lead) }}
                  </p>
                </div>
                <button
                  type="button"
                  class="h-8 rounded-md bg-n-brand px-3 text-xs font-medium text-white disabled:cursor-not-allowed disabled:opacity-60"
                  :disabled="busyLeadId === lead.id"
                  @click="addLead(lead)"
                >
                  {{ t('PROSPECTING.LISTS.ADD_LEAD') }}
                </button>
              </article>
            </div>
          </div>
        </section>
      </div>
    </section>
  </main>
</template>
