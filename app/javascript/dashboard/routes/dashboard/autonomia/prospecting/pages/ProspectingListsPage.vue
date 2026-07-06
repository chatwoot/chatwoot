<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import AutonomiaProspectingAPI from 'dashboard/api/autonomiaProspecting';
import CrmKanbanAPI from 'dashboard/api/crmKanban';

const { t } = useI18n();
const route = useRoute();

const isLoading = ref(true);
const isCreating = ref(false);
const busyLeadId = ref(null);
const convertingLeadId = ref(null);
const convertingCrmLeadId = ref(null);
const error = ref('');
const notice = ref('');
const lists = ref([]);
const selectedList = ref(null);
const allLeads = ref([]);
const settings = ref(null);
const crmPipelines = ref([]);
const crmStages = ref([]);
const statusFilter = ref('');
const form = ref({
  name: '',
  description: '',
});
const crmForm = ref({
  pipeline_id: '',
  stage_id: '',
});
const statusOptions = [
  'new_lead',
  'qualified',
  'discarded',
  'no_consent',
  'ready_for_campaign',
];

const selectedLeadIds = computed(
  () => new Set((selectedList.value?.lead_ids || []).map(Number))
);
const listLeads = computed(() => {
  const leads = selectedList.value?.leads || [];
  if (!statusFilter.value) return leads;

  return leads.filter(lead => lead.status === statusFilter.value);
});
const availableLeads = computed(() =>
  allLeads.value.filter(lead => {
    if (selectedLeadIds.value.has(Number(lead.id))) return false;
    if (!statusFilter.value) return true;

    return lead.status === statusFilter.value;
  })
);
const hasSelectedList = computed(() => Boolean(selectedList.value?.id));
const canCreateCrmCard = computed(() =>
  Boolean(crmForm.value.pipeline_id && crmForm.value.stage_id)
);

const formatDate = value => {
  if (!value) return '-';
  return new Date(value).toLocaleDateString();
};

const formatLeadAddress = lead =>
  [lead.address, [lead.city, lead.state].filter(Boolean).join(' ')]
    .filter(Boolean)
    .join(t('PROSPECTING.SEARCH.ADDRESS_SEPARATOR'));

const contactUrl = contactId =>
  `/app/accounts/${route.params.accountId}/contacts/${contactId}`;

const crmCardUrl = cardId =>
  `/app/accounts/${route.params.accountId}/crm?card_id=${cardId}`;

const replaceLead = updatedLead => {
  if (!updatedLead?.id) return;

  allLeads.value = allLeads.value.map(lead =>
    lead.id === updatedLead.id ? updatedLead : lead
  );

  if (selectedList.value?.leads) {
    selectedList.value = {
      ...selectedList.value,
      leads: selectedList.value.leads.map(lead =>
        lead.id === updatedLead.id ? updatedLead : lead
      ),
    };
  }
};

const fetchCrmStages = async (pipelineId, preferredStageId = '') => {
  crmStages.value = [];
  crmForm.value.stage_id = '';
  if (!pipelineId) return;

  const { data } = await CrmKanbanAPI.getStages(pipelineId);
  crmStages.value = data.payload || [];
  crmForm.value.stage_id =
    preferredStageId ||
    settings.value?.default_crm_stage_id ||
    crmStages.value[0]?.id ||
    '';
};

const fetchCrmPipelines = async () => {
  try {
    const { data } = await CrmKanbanAPI.getPipelines();
    crmPipelines.value = data.payload || [];
    crmForm.value.pipeline_id = settings.value?.default_crm_pipeline_id || '';
    await fetchCrmStages(
      crmForm.value.pipeline_id,
      settings.value?.default_crm_stage_id
    );
  } catch {
    crmPipelines.value = [];
    crmStages.value = [];
  }
};

const fetchLists = async () => {
  const { data } = await AutonomiaProspectingAPI.getLists();
  lists.value = data.payload || [];
};

const fetchAllLeads = async () => {
  const { data } = await AutonomiaProspectingAPI.getLeads();
  allLeads.value = data.payload || [];
};

const fetchSettings = async () => {
  const { data } = await AutonomiaProspectingAPI.getSettings();
  settings.value = data.payload || {};
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
    await fetchSettings();
    await Promise.all([fetchLists(), fetchAllLeads(), fetchCrmPipelines()]);
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

const createContact = async lead => {
  if (!lead?.id || lead.contact_id || convertingLeadId.value) return;

  convertingLeadId.value = lead.id;
  error.value = '';
  notice.value = '';
  try {
    const { data } = await AutonomiaProspectingAPI.createLeadContact(lead.id);
    replaceLead(data.payload?.lead);
    notice.value = t('PROSPECTING.SEARCH.CONTACT_CREATED');
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
  notice.value = '';
  try {
    const { data } = await AutonomiaProspectingAPI.createLeadCrmCard(lead.id, {
      pipeline_id: crmForm.value.pipeline_id,
      stage_id: crmForm.value.stage_id,
    });
    replaceLead(data.payload?.lead);
    notice.value = t('PROSPECTING.SEARCH.CRM_CARD_CREATED');
  } catch (e) {
    error.value =
      e?.response?.data?.error || t('PROSPECTING.ERRORS.CREATE_CRM_CARD');
  } finally {
    convertingCrmLeadId.value = null;
  }
};

const updateLeadQuality = async (lead, status) => {
  if (!lead?.id || lead.status === status) return;

  let discardReason = lead.discard_reason || '';
  if (status === 'discarded' && !discardReason) {
    discardReason =
      window.prompt(t('PROSPECTING.QUALITY.DISCARD_REASON_PROMPT')) || '';
    if (!discardReason.trim()) return;
  }

  try {
    const { data } = await AutonomiaProspectingAPI.updateLead(lead.id, {
      status,
      discard_reason: discardReason,
    });
    replaceLead(data.payload);
  } catch (e) {
    error.value =
      e?.response?.data?.error || t('PROSPECTING.ERRORS.UPDATE_LEAD');
  }
};

const updateDiscardReason = async lead => {
  if (!lead?.id || lead.status !== 'discarded') return;

  try {
    const { data } = await AutonomiaProspectingAPI.updateLead(lead.id, {
      status: lead.status,
      discard_reason: lead.discard_reason,
    });
    replaceLead(data.payload);
  } catch (e) {
    error.value =
      e?.response?.data?.error || t('PROSPECTING.ERRORS.UPDATE_LEAD');
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
              <div class="mt-3 grid gap-2 sm:grid-cols-3">
                <label class="grid gap-1">
                  <span class="text-xs font-medium text-n-slate-11">
                    {{ t('PROSPECTING.QUALITY.STATUS_FILTER') }}
                  </span>
                  <select
                    v-model="statusFilter"
                    class="h-9 rounded-md border border-n-weak bg-n-solid-2 px-2 text-sm text-n-slate-12"
                  >
                    <option value="">
                      {{ t('PROSPECTING.QUALITY.ALL_STATUSES') }}
                    </option>
                    <option
                      v-for="status in statusOptions"
                      :key="status"
                      :value="status"
                    >
                      {{ t(`PROSPECTING.QUALITY.STATUSES.${status}`) }}
                    </option>
                  </select>
                </label>
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
                class="grid gap-3 border-b border-n-weak px-4 py-4 text-sm last:border-b-0 md:grid-cols-[minmax(0,1fr)_8rem_8rem_8rem_10rem]"
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
                  <p class="truncate text-xs text-n-slate-10">
                    {{ t('PROSPECTING.QUALITY.SOURCE') }}:
                    {{ lead.source_label || lead.provider }}
                    {{
                      lead.provider_place_id
                        ? `- ${lead.provider_place_id}`
                        : ''
                    }}
                  </p>
                </div>
                <div class="flex flex-col items-start gap-1">
                  <a
                    v-if="lead.contact_id"
                    :href="contactUrl(lead.contact_id)"
                    class="text-xs font-medium text-n-brand underline"
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
                <div class="flex flex-col items-start gap-1">
                  <a
                    v-if="lead.crm_card_id"
                    :href="crmCardUrl(lead.crm_card_id)"
                    class="text-xs font-medium text-n-brand underline"
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
                <button
                  type="button"
                  class="h-8 rounded-md border border-n-weak px-3 text-xs font-medium text-n-slate-12 hover:bg-n-solid-2 disabled:cursor-not-allowed disabled:opacity-60"
                  :disabled="busyLeadId === lead.id"
                  @click="removeLead(lead)"
                >
                  {{ t('PROSPECTING.LISTS.REMOVE_LEAD') }}
                </button>
                <div class="flex flex-col gap-1">
                  <select
                    :value="lead.status"
                    class="h-8 rounded-md border border-n-weak bg-n-solid-2 px-2 text-xs text-n-slate-12"
                    @change="updateLeadQuality(lead, $event.target.value)"
                  >
                    <option
                      v-for="status in statusOptions"
                      :key="status"
                      :value="status"
                    >
                      {{ t(`PROSPECTING.QUALITY.STATUSES.${status}`) }}
                    </option>
                  </select>
                  <input
                    v-if="lead.status === 'discarded'"
                    v-model="lead.discard_reason"
                    class="h-8 rounded-md border border-n-weak bg-n-solid-2 px-2 text-xs text-n-slate-12"
                    :placeholder="t('PROSPECTING.QUALITY.DISCARD_REASON')"
                    @blur="updateDiscardReason(lead)"
                  />
                </div>
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
                  <p class="truncate text-xs text-n-slate-10">
                    {{ t('PROSPECTING.QUALITY.SOURCE') }}:
                    {{ lead.source_label || lead.provider }}
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
