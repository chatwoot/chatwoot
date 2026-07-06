<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import AutonomiaProspectingAPI from 'dashboard/api/autonomiaProspecting';
import CrmKanbanAPI from 'dashboard/api/crmKanban';

const { t } = useI18n();
const route = useRoute();

const isLoading = ref(true);
const isSearching = ref(false);
const convertingLeadId = ref(null);
const convertingCrmLeadId = ref(null);
const error = ref('');
const searches = ref([]);
const leads = ref([]);
const settings = ref(null);
const crmPipelines = ref([]);
const crmStages = ref([]);
const selectedSearchId = ref(null);
const form = ref({
  query: '',
  location: '',
  radius: 5000,
  requested_limit: 20,
  provider: 'mock',
});
const crmForm = ref({
  pipeline_id: '',
  stage_id: '',
});

const hasResults = computed(() => leads.value.length > 0);
const canCreateCrmCard = computed(() =>
  Boolean(crmForm.value.pipeline_id && crmForm.value.stage_id)
);
const canSearch = computed(
  () => form.value.query.trim().length > 0 && !isSearching.value
);
const resultsEmptyText = computed(() =>
  selectedSearchId.value
    ? t('PROSPECTING.SEARCH.RESULTS_EMPTY_AFTER_SEARCH')
    : t('PROSPECTING.SEARCH.RESULTS_EMPTY')
);

const fetchSearches = async () => {
  isLoading.value = true;
  error.value = '';
  try {
    const { data } = await AutonomiaProspectingAPI.getSearches();
    searches.value = data.payload || [];
  } catch {
    error.value = t('PROSPECTING.ERRORS.LOAD_SEARCHES');
  } finally {
    isLoading.value = false;
  }
};

const fetchSettings = async () => {
  try {
    const { data } = await AutonomiaProspectingAPI.getSettings();
    settings.value = data.payload || {};
    form.value.provider = settings.value.provider || 'mock';
    form.value.requested_limit =
      settings.value.default_limit || form.value.requested_limit;
  } catch {
    settings.value = null;
  }
};

const fetchCrmStages = async pipelineId => {
  crmStages.value = [];
  crmForm.value.stage_id = '';
  if (!pipelineId) return;

  const { data } = await CrmKanbanAPI.getStages(pipelineId);
  crmStages.value = data.payload || [];
  crmForm.value.stage_id = crmStages.value[0]?.id || '';
};

const fetchCrmPipelines = async () => {
  try {
    const { data } = await CrmKanbanAPI.getPipelines();
    crmPipelines.value = data.payload || [];
    crmForm.value.pipeline_id = crmPipelines.value[0]?.id || '';
    await fetchCrmStages(crmForm.value.pipeline_id);
  } catch {
    crmPipelines.value = [];
    crmStages.value = [];
  }
};

const submitSearch = async () => {
  if (!canSearch.value) return;

  isSearching.value = true;
  error.value = '';
  leads.value = [];

  try {
    const { data } = await AutonomiaProspectingAPI.createSearch({
      query: form.value.query,
      location: form.value.location,
      radius: Number(form.value.radius),
      requested_limit: Number(form.value.requested_limit),
      provider: form.value.provider,
    });

    const payload = data.payload || {};
    leads.value = payload.leads || [];
    selectedSearchId.value = payload.search?.id;
    await fetchSearches();
  } catch (e) {
    error.value =
      e?.response?.data?.error || t('PROSPECTING.ERRORS.CREATE_SEARCH');
  } finally {
    isSearching.value = false;
  }
};

const openSearch = async search => {
  selectedSearchId.value = search.id;
  error.value = '';
  isLoading.value = true;

  try {
    const { data } = await AutonomiaProspectingAPI.getSearch(search.id);
    leads.value = data.payload?.leads || [];
  } catch {
    error.value = t('PROSPECTING.ERRORS.LOAD_SEARCH');
  } finally {
    isLoading.value = false;
  }
};

const formatDate = value => {
  if (!value) return '-';
  return new Date(value).toLocaleString();
};

const formatLeadAddress = lead => {
  const cityState = [lead.city, lead.state].filter(Boolean).join(' ');
  return [lead.address, cityState]
    .filter(Boolean)
    .join(t('PROSPECTING.SEARCH.ADDRESS_SEPARATOR'));
};

const contactUrl = contactId =>
  `/app/accounts/${route.params.accountId}/contacts/${contactId}`;

const crmCardUrl = cardId =>
  `/app/accounts/${route.params.accountId}/crm?card_id=${cardId}`;

const replaceLead = updatedLead => {
  if (!updatedLead?.id) return;
  leads.value = leads.value.map(item =>
    item.id === updatedLead.id ? updatedLead : item
  );
};

const createContact = async lead => {
  if (!lead?.id || lead.contact_id || convertingLeadId.value) return;

  convertingLeadId.value = lead.id;
  error.value = '';

  try {
    const { data } = await AutonomiaProspectingAPI.createLeadContact(lead.id);
    replaceLead(data.payload?.lead);
  } catch (e) {
    error.value =
      e?.response?.data?.error || t('PROSPECTING.ERRORS.CREATE_CONTACT');
  } finally {
    convertingLeadId.value = null;
  }
};

const createCrmCard = async lead => {
  if (
    !lead?.id ||
    lead.crm_card_id ||
    convertingCrmLeadId.value ||
    !canCreateCrmCard.value
  ) {
    return;
  }

  convertingCrmLeadId.value = lead.id;
  error.value = '';

  try {
    const { data } = await AutonomiaProspectingAPI.createLeadCrmCard(lead.id, {
      pipeline_id: crmForm.value.pipeline_id,
      stage_id: crmForm.value.stage_id,
    });
    replaceLead(data.payload?.lead);
  } catch (e) {
    error.value =
      e?.response?.data?.error || t('PROSPECTING.ERRORS.CREATE_CRM_CARD');
  } finally {
    convertingCrmLeadId.value = null;
  }
};

onMounted(async () => {
  await Promise.all([fetchSettings(), fetchCrmPipelines()]);
  await fetchSearches();
});
</script>

<template>
  <main class="flex h-full min-h-0 flex-col overflow-hidden bg-n-background">
    <header class="border-b border-n-weak px-6 py-4">
      <h1 class="text-xl font-semibold text-n-slate-12">
        {{ t('PROSPECTING.SEARCH.TITLE') }}
      </h1>
    </header>

    <section
      class="flex min-h-0 flex-1 flex-col gap-4 overflow-y-auto px-6 py-5"
    >
      <form
        class="grid gap-3 rounded-lg border border-n-weak bg-n-solid-1 p-4 md:grid-cols-[minmax(12rem,1fr)_minmax(14rem,1fr)_8rem_8rem_10rem_10rem]"
        @submit.prevent="submitSearch"
      >
        <label class="grid grid-rows-[1.25rem_2.5rem] gap-1">
          <span class="flex items-end text-xs font-medium text-n-slate-11">
            {{ t('PROSPECTING.SEARCH.FIELDS.PROVIDER') }}
          </span>
          <select
            v-model="form.provider"
            class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
          >
            <option value="mock">
              {{ t('PROSPECTING.SETTINGS.PROVIDERS.MOCK') }}
            </option>
            <option value="google_places">
              {{ t('PROSPECTING.SETTINGS.PROVIDERS.GOOGLE_PLACES') }}
            </option>
          </select>
        </label>
        <label class="grid grid-rows-[1.25rem_2.5rem] gap-1">
          <span class="flex items-end text-xs font-medium text-n-slate-11">
            {{ t('PROSPECTING.SEARCH.FIELDS.QUERY') }}
          </span>
          <input
            v-model="form.query"
            class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
            :placeholder="t('PROSPECTING.SEARCH.QUERY_PLACEHOLDER')"
          />
        </label>
        <label class="grid grid-rows-[1.25rem_2.5rem] gap-1">
          <span class="flex items-end text-xs font-medium text-n-slate-11">
            {{ t('PROSPECTING.SEARCH.FIELDS.LOCATION') }}
          </span>
          <input
            v-model="form.location"
            class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
            :placeholder="t('PROSPECTING.SEARCH.LOCATION_PLACEHOLDER')"
          />
        </label>
        <label class="grid grid-rows-[1.25rem_2.5rem] gap-1">
          <span class="flex items-end text-xs font-medium text-n-slate-11">
            {{ t('PROSPECTING.SEARCH.FIELDS.RADIUS') }}
          </span>
          <input
            v-model="form.radius"
            type="number"
            min="100"
            step="100"
            class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
          />
        </label>
        <label class="grid grid-rows-[1.25rem_2.5rem] gap-1">
          <span class="flex items-end text-xs font-medium text-n-slate-11">
            {{ t('PROSPECTING.SEARCH.FIELDS.LIMIT') }}
          </span>
          <input
            v-model="form.requested_limit"
            type="number"
            min="1"
            max="50"
            class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
          />
        </label>
        <div class="grid grid-rows-[1.25rem_2.5rem] gap-1">
          <span aria-hidden="true" />
          <button
            type="submit"
            class="h-10 rounded-md bg-n-brand px-3 text-sm font-medium text-white disabled:cursor-not-allowed disabled:opacity-60"
            :disabled="!canSearch"
          >
            {{
              isSearching
                ? t('PROSPECTING.SEARCH.SEARCHING')
                : t('PROSPECTING.SEARCH.ACTION')
            }}
          </button>
        </div>
      </form>

      <div
        v-if="error"
        class="rounded-md bg-n-ruby-3 px-4 py-3 text-sm text-n-ruby-11"
      >
        {{ error }}
      </div>

      <div
        class="flex min-h-[16rem] max-h-[calc(100vh-18rem)] flex-col overflow-hidden rounded-lg border border-n-weak bg-n-solid-1"
      >
        <div
          class="flex flex-col gap-3 border-b border-n-weak px-4 py-3 lg:flex-row lg:items-end lg:justify-between"
        >
          <h2 class="text-sm font-semibold text-n-slate-12">
            {{ t('PROSPECTING.SEARCH.RESULTS_TITLE') }}
          </h2>
          <div class="grid gap-2 sm:grid-cols-2">
            <label class="grid gap-1">
              <span class="text-xs font-medium text-n-slate-11">
                {{ t('PROSPECTING.SEARCH.FIELDS.CRM_PIPELINE') }}
              </span>
              <select
                v-model="crmForm.pipeline_id"
                class="h-9 rounded-md border border-n-weak bg-n-solid-2 px-2 text-sm text-n-slate-12"
                @change="fetchCrmStages(crmForm.pipeline_id)"
              >
                <option value="">
                  {{ t('PROSPECTING.SEARCH.CRM_DISABLED') }}
                </option>
                <option
                  v-for="pipeline in crmPipelines"
                  :key="pipeline.id"
                  :value="pipeline.id"
                >
                  {{ pipeline.name }}
                </option>
              </select>
            </label>
            <label class="grid gap-1">
              <span class="text-xs font-medium text-n-slate-11">
                {{ t('PROSPECTING.SEARCH.FIELDS.CRM_STAGE') }}
              </span>
              <select
                v-model="crmForm.stage_id"
                class="h-9 rounded-md border border-n-weak bg-n-solid-2 px-2 text-sm text-n-slate-12"
                :disabled="!crmStages.length"
              >
                <option
                  v-for="stage in crmStages"
                  :key="stage.id"
                  :value="stage.id"
                >
                  {{ stage.name }}
                </option>
              </select>
            </label>
          </div>
        </div>
        <div class="min-h-0 flex-1 overflow-y-auto">
          <div v-if="isSearching" class="px-4 py-8 text-sm text-n-slate-11">
            {{ t('PROSPECTING.STATES.LOADING') }}
          </div>
          <div
            v-else-if="!hasResults"
            class="px-4 py-8 text-sm text-n-slate-11"
          >
            {{ resultsEmptyText }}
          </div>
          <div v-else class="divide-y divide-n-weak">
            <article
              v-for="lead in leads"
              :key="lead.id"
              class="grid gap-2 px-4 py-4 text-sm md:grid-cols-[1.4fr_.8fr_1fr_7rem_9rem_9rem]"
            >
              <div class="min-w-0">
                <h3 class="truncate font-medium text-n-slate-12">
                  {{ lead.name }}
                </h3>
                <p class="truncate text-n-slate-10">
                  {{ formatLeadAddress(lead) }}
                </p>
              </div>
              <div class="text-n-slate-11">
                <div>{{ lead.category || '-' }}</div>
                <div>{{ lead.provider }}</div>
              </div>
              <div class="text-n-slate-11">
                <a
                  v-if="lead.website"
                  :href="lead.website"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="text-n-brand underline"
                >
                  {{ t('PROSPECTING.SEARCH.OPEN_SITE') }}
                </a>
                <div>{{ lead.phone || '-' }}</div>
              </div>
              <div class="text-n-slate-11">
                <div>
                  {{
                    t('PROSPECTING.SEARCH.RATING_LABEL', {
                      rating: lead.rating || '-',
                    })
                  }}
                </div>
                <div>
                  {{
                    t('PROSPECTING.SEARCH.REVIEWS_LABEL', {
                      count: lead.reviews_count || 0,
                    })
                  }}
                </div>
              </div>
              <div class="flex flex-col items-start gap-1 text-n-slate-11">
                <a
                  v-if="lead.contact_id"
                  :href="contactUrl(lead.contact_id)"
                  class="text-n-brand underline"
                >
                  {{ t('PROSPECTING.SEARCH.OPEN_CONTACT') }}
                </a>
                <button
                  v-else
                  type="button"
                  class="h-8 rounded-md bg-n-brand px-3 text-xs font-medium text-white disabled:cursor-not-allowed disabled:opacity-60"
                  :disabled="convertingLeadId === lead.id"
                  @click="createContact(lead)"
                >
                  {{
                    convertingLeadId === lead.id
                      ? t('PROSPECTING.SEARCH.CREATING_CONTACT')
                      : t('PROSPECTING.SEARCH.CREATE_CONTACT')
                  }}
                </button>
                <span v-if="lead.contact_id" class="text-xs text-n-slate-10">
                  {{ t('PROSPECTING.SEARCH.CONTACT_CREATED') }}
                </span>
              </div>
              <div class="flex flex-col items-start gap-1 text-n-slate-11">
                <a
                  v-if="lead.crm_card_id"
                  :href="crmCardUrl(lead.crm_card_id)"
                  class="text-n-brand underline"
                >
                  {{ t('PROSPECTING.SEARCH.OPEN_CRM_CARD') }}
                </a>
                <button
                  v-else
                  type="button"
                  class="h-8 rounded-md bg-n-brand px-3 text-xs font-medium text-white disabled:cursor-not-allowed disabled:opacity-60"
                  :disabled="
                    convertingCrmLeadId === lead.id || !canCreateCrmCard
                  "
                  @click="createCrmCard(lead)"
                >
                  {{
                    convertingCrmLeadId === lead.id
                      ? t('PROSPECTING.SEARCH.CREATING_CRM_CARD')
                      : t('PROSPECTING.SEARCH.CREATE_CRM_CARD')
                  }}
                </button>
                <span v-if="lead.crm_card_id" class="text-xs text-n-slate-10">
                  {{ t('PROSPECTING.SEARCH.CRM_CARD_CREATED') }}
                </span>
              </div>
            </article>
          </div>
        </div>
      </div>

      <div
        class="flex min-h-[12rem] max-h-[24rem] flex-col overflow-hidden rounded-lg border border-n-weak bg-n-solid-1"
      >
        <div class="border-b border-n-weak px-4 py-3">
          <h2 class="text-sm font-semibold text-n-slate-12">
            {{ t('PROSPECTING.SEARCH.HISTORY_TITLE') }}
          </h2>
        </div>
        <div
          class="grid grid-cols-[1fr_9rem_8rem_8rem_11rem] border-b border-n-weak px-4 py-3 text-xs font-medium uppercase text-n-slate-10"
        >
          <span>{{ t('PROSPECTING.SEARCH.COLUMNS.QUERY') }}</span>
          <span>{{ t('PROSPECTING.SEARCH.COLUMNS.PROVIDER') }}</span>
          <span>{{ t('PROSPECTING.SEARCH.COLUMNS.STATUS') }}</span>
          <span>{{ t('PROSPECTING.SEARCH.COLUMNS.RESULTS') }}</span>
          <span>{{ t('PROSPECTING.SEARCH.COLUMNS.CREATED_AT') }}</span>
        </div>
        <div class="min-h-0 flex-1 overflow-y-auto">
          <div v-if="isLoading" class="px-4 py-8 text-sm text-n-slate-11">
            {{ t('PROSPECTING.STATES.LOADING') }}
          </div>
          <div
            v-else-if="!searches.length"
            class="px-4 py-8 text-sm text-n-slate-11"
          >
            {{ t('PROSPECTING.SEARCH.EMPTY') }}
          </div>
          <template v-else>
            <button
              v-for="search in searches"
              :key="search.id"
              type="button"
              class="grid w-full grid-cols-[1fr_9rem_8rem_8rem_11rem] border-b border-n-weak px-4 py-3 text-left text-sm text-n-slate-12 last:border-b-0 hover:bg-n-solid-2"
              :class="{ 'bg-n-solid-2': selectedSearchId === search.id }"
              @click="openSearch(search)"
            >
              <span class="truncate">{{ search.query }}</span>
              <span>{{ search.provider }}</span>
              <span>{{ search.status }}</span>
              <span>{{ search.results_count || 0 }}</span>
              <span>{{ formatDate(search.created_at) }}</span>
            </button>
          </template>
        </div>
      </div>
    </section>
  </main>
</template>
