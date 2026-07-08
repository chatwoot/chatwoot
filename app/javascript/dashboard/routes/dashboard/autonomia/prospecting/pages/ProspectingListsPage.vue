<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import AutonomiaProspectingAPI from 'dashboard/api/autonomiaProspecting';
import CampaignsAPI from 'dashboard/api/campaigns';
import CrmKanbanAPI from 'dashboard/api/crmKanban';
import ProspectingPriorityRing from '../components/ProspectingPriorityRing.vue';
import {
  leadPrioritySignals,
  priorityTheme,
  priorityValue,
} from '../utils/prospectingPriority';

const { t } = useI18n();
const route = useRoute();

const isLoading = ref(true);
const isCreating = ref(false);
const busyLeadId = ref(null);
const convertingLeadId = ref(null);
const convertingCrmLeadId = ref(null);
const verifyingWhatsAppLeadIds = ref([]);
const isCreatingCampaignSegment = ref(false);
const isAddingSelectedLeads = ref(false);
const lists = ref([]);
const selectedList = ref(null);
const allLeads = ref([]);
const campaigns = ref([]);
const settings = ref(null);
const crmPipelines = ref([]);
const crmStages = ref([]);
const addLeadStatusFilter = ref('');
const addLeadQuery = ref('');
const selectedAddLeadIds = ref([]);
const showCreateListModal = ref(false);
const showAddLeadsModal = ref(false);
const showCampaignModal = ref(false);
const campaignSegmentForm = ref({
  campaign_id: '',
  segment_name: '',
});
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
const whatsappVerificationRequested = new Set();

const formatDate = value => {
  if (!value) return '-';
  return new Date(value).toLocaleDateString();
};

const formatLeadAddress = lead =>
  [lead.address, [lead.city, lead.state].filter(Boolean).join(' ')]
    .filter(Boolean)
    .join(t('PROSPECTING.SEARCH.ADDRESS_SEPARATOR'));

const selectedLeadIds = computed(
  () => new Set((selectedList.value?.lead_ids || []).map(Number))
);
const listLeads = computed(() => selectedList.value?.leads || []);
const availableLeads = computed(() =>
  allLeads.value.filter(lead => {
    if (selectedLeadIds.value.has(Number(lead.id))) return false;

    return true;
  })
);
const filteredAvailableLeads = computed(() =>
  availableLeads.value.filter(lead => {
    if (
      addLeadStatusFilter.value &&
      lead.status !== addLeadStatusFilter.value
    ) {
      return false;
    }

    const query = addLeadQuery.value.trim().toLowerCase();
    if (!query) return true;

    return [lead.name, lead.phone, formatLeadAddress(lead), lead.category]
      .filter(Boolean)
      .some(value => value.toLowerCase().includes(query));
  })
);
const hasSelectedList = computed(() => Boolean(selectedList.value?.id));
const canCreateCrmCard = computed(() =>
  Boolean(crmForm.value.pipeline_id && crmForm.value.stage_id)
);
const leadHasVerifiedWhatsApp = lead => lead?.whatsapp_verified === true;
const campaignReadyLeads = computed(() =>
  (selectedList.value?.leads || []).filter(
    lead =>
      lead.status === 'ready_for_campaign' && leadHasVerifiedWhatsApp(lead)
  )
);
const campaignBlockedLeads = computed(() =>
  (selectedList.value?.leads || []).filter(
    lead =>
      lead.status !== 'ready_for_campaign' || !leadHasVerifiedWhatsApp(lead)
  )
);
const availableCampaigns = computed(() =>
  campaigns.value.filter(
    campaign =>
      campaign.campaign_type === 'one_off' &&
      campaign.campaign_status === 'active'
  )
);
const currentCampaignSegment = computed(
  () => selectedList.value?.campaign_segment || null
);
const selectedAddLeadsCount = computed(() => selectedAddLeadIds.value.length);
const selectedListContactCount = computed(
  () => (selectedList.value?.leads || []).filter(lead => lead.contact_id).length
);
const selectedListCrmCount = computed(
  () =>
    (selectedList.value?.leads || []).filter(lead => lead.crm_card_id).length
);
const hasSelectedAddLeads = computed(() => selectedAddLeadIds.value.length > 0);
const allFilteredAvailableLeadsSelected = computed(
  () =>
    filteredAvailableLeads.value.length > 0 &&
    filteredAvailableLeads.value.every(lead =>
      selectedAddLeadIds.value.map(Number).includes(Number(lead.id))
    )
);
const leadPriority = lead => priorityValue(lead);
const leadPriorityTheme = lead => {
  const priority = leadPriority(lead);
  return priority === null ? null : priorityTheme(priority);
};
const leadSignals = lead => leadPrioritySignals(lead);

const contactUrl = contactId =>
  `/app/accounts/${route.params.accountId}/contacts/${contactId}`;

const crmCardUrl = cardId =>
  `/app/accounts/${route.params.accountId}/crm?card_id=${cardId}`;

const googleMapsLeadUrl = lead => {
  const query =
    lead.latitude && lead.longitude
      ? `${lead.latitude},${lead.longitude}`
      : [lead.name, formatLeadAddress(lead)].filter(Boolean).join(' ');
  return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(query)}`;
};

const normalizedLeadPhone = lead => {
  const raw = String(lead?.whatsapp_phone || lead?.phone || '').trim();
  const digits = raw.replace(/\D/g, '');
  if (!digits) return '';
  if (raw.startsWith('+')) return `+${digits}`;
  if (digits.startsWith('55')) return `+${digits}`;
  if ([10, 11].includes(digits.length)) return `+55${digits}`;
  return `+${digits}`;
};

const leadPhoneUrl = lead => {
  const phone = normalizedLeadPhone(lead);
  return phone ? `tel:${phone}` : '';
};

const leadWhatsAppUrl = lead => {
  const verifiedUrl = lead?.whatsapp_url;
  if (verifiedUrl) return verifiedUrl;

  const phone = normalizedLeadPhone(lead);
  return phone ? `https://wa.me/${phone.replace(/\D/g, '')}` : '';
};

const isWhatsAppVerified = leadHasVerifiedWhatsApp;
const isWhatsAppUnavailable = lead =>
  lead?.whatsapp_verification_status === 'not_whatsapp';
const isWhatsAppChecking = lead =>
  verifyingWhatsAppLeadIds.value.map(Number).includes(Number(lead?.id));

const shouldVerifyWhatsApp = lead =>
  lead?.id &&
  normalizedLeadPhone(lead) &&
  !lead?.whatsapp_verification_status &&
  !whatsappVerificationRequested.has(Number(lead.id));

const alertError = (error, fallbackMessage) => {
  useAlert(error?.response?.data?.error || fallbackMessage);
};

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

const verifyLeadWhatsApp = async lead => {
  if (!shouldVerifyWhatsApp(lead)) return;

  const leadId = Number(lead.id);
  whatsappVerificationRequested.add(leadId);
  verifyingWhatsAppLeadIds.value = [...verifyingWhatsAppLeadIds.value, leadId];

  try {
    const { data } = await AutonomiaProspectingAPI.verifyLeadWhatsApp(lead.id);
    replaceLead(data.payload?.lead);
  } catch {
    // Falha de WAHA/configuração não deve bloquear listas.
  } finally {
    verifyingWhatsAppLeadIds.value = verifyingWhatsAppLeadIds.value.filter(
      id => Number(id) !== leadId
    );
  }
};

const verifyLeadsWhatsApp = leadsToVerify => {
  leadsToVerify
    .filter(shouldVerifyWhatsApp)
    .slice(0, 25)
    .reduce(
      (promise, lead) => promise.then(() => verifyLeadWhatsApp(lead)),
      Promise.resolve()
    );
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
  verifyLeadsWhatsApp(allLeads.value);
};

const fetchCampaigns = async () => {
  try {
    const { data } = await CampaignsAPI.get();
    campaigns.value = data || [];
  } catch {
    campaigns.value = [];
  }
};

const fetchSettings = async () => {
  const { data } = await AutonomiaProspectingAPI.getSettings();
  settings.value = data.payload || {};
};

const selectList = async list => {
  if (!list?.id) return;

  try {
    const { data } = await AutonomiaProspectingAPI.getList(list.id);
    selectedList.value = data.payload || null;
    verifyLeadsWhatsApp(selectedList.value?.leads || []);
    campaignSegmentForm.value = {
      campaign_id: currentCampaignSegment.value?.campaign_id || '',
      segment_name: selectedList.value?.name || '',
    };
  } catch {
    useAlert(t('PROSPECTING.ERRORS.LOAD_LIST'));
  }
};

const loadPage = async () => {
  isLoading.value = true;
  try {
    await fetchSettings();
    await Promise.all([
      fetchLists(),
      fetchAllLeads(),
      fetchCrmPipelines(),
      fetchCampaigns(),
    ]);
    if (lists.value.length) {
      await selectList(lists.value[0]);
    }
  } catch {
    useAlert(t('PROSPECTING.ERRORS.LOAD_LISTS'));
  } finally {
    isLoading.value = false;
  }
};

const createList = async () => {
  if (!form.value.name.trim() || isCreating.value) return;

  isCreating.value = true;
  try {
    const { data } = await AutonomiaProspectingAPI.createList({
      name: form.value.name.trim(),
      description: form.value.description.trim(),
    });
    form.value = { name: '', description: '' };
    await fetchLists();
    await selectList(data.payload);
    showCreateListModal.value = false;
    useAlert(t('PROSPECTING.LISTS.CREATED'));
  } catch (e) {
    alertError(e, t('PROSPECTING.ERRORS.CREATE_LIST'));
  } finally {
    isCreating.value = false;
  }
};

const openCreateListModal = () => {
  form.value = { name: '', description: '' };
  showCreateListModal.value = true;
};

const openAddLeadsModal = async list => {
  if (list?.id && list.id !== selectedList.value?.id) {
    await selectList(list);
  }
  selectedAddLeadIds.value = [];
  addLeadQuery.value = '';
  addLeadStatusFilter.value = '';
  showAddLeadsModal.value = true;
};

const openCampaignModal = async list => {
  if (list?.id && list.id !== selectedList.value?.id) {
    await selectList(list);
  }
  campaignSegmentForm.value = {
    campaign_id: currentCampaignSegment.value?.campaign_id || '',
    segment_name: selectedList.value?.name || '',
  };
  showCampaignModal.value = true;
};

const toggleAddLeadSelection = leadId => {
  const id = Number(leadId);
  const ids = new Set(selectedAddLeadIds.value.map(Number));
  if (ids.has(id)) {
    ids.delete(id);
  } else {
    ids.add(id);
  }
  selectedAddLeadIds.value = [...ids];
};

const toggleAllFilteredAvailableLeads = () => {
  if (allFilteredAvailableLeadsSelected.value) {
    const visibleIds = new Set(
      filteredAvailableLeads.value.map(lead => Number(lead.id))
    );
    selectedAddLeadIds.value = selectedAddLeadIds.value.filter(
      leadId => !visibleIds.has(Number(leadId))
    );
    return;
  }

  selectedAddLeadIds.value = [
    ...new Set([
      ...selectedAddLeadIds.value.map(Number),
      ...filteredAvailableLeads.value.map(lead => Number(lead.id)),
    ]),
  ];
};

const addSelectedLeads = async () => {
  if (
    !selectedList.value?.id ||
    isAddingSelectedLeads.value ||
    !selectedAddLeadIds.value.length
  ) {
    return;
  }

  isAddingSelectedLeads.value = true;
  try {
    const addedCount = selectedAddLeadIds.value.length;
    let payload = selectedList.value;
    await selectedAddLeadIds.value.reduce(async (previousRequest, leadId) => {
      await previousRequest;
      const { data } = await AutonomiaProspectingAPI.addLeadToList(
        selectedList.value.id,
        leadId
      );
      payload = data.payload || payload;
    }, Promise.resolve());
    selectedList.value = payload;
    await Promise.all([fetchLists(), fetchAllLeads()]);
    selectedAddLeadIds.value = [];
    showAddLeadsModal.value = false;
    useAlert(
      t('PROSPECTING.LISTS.LEADS_ADDED', {
        count: addedCount,
      })
    );
  } catch (e) {
    alertError(e, t('PROSPECTING.ERRORS.ADD_LEAD_TO_LIST'));
  } finally {
    isAddingSelectedLeads.value = false;
  }
};

const removeLead = async lead => {
  if (!selectedList.value?.id || !lead?.id || busyLeadId.value) return;

  busyLeadId.value = lead.id;
  try {
    const { data } = await AutonomiaProspectingAPI.removeLeadFromList(
      selectedList.value.id,
      lead.id
    );
    selectedList.value = data.payload || selectedList.value;
    await fetchLists();
    useAlert(t('PROSPECTING.LISTS.LEAD_REMOVED'));
  } catch (e) {
    alertError(e, t('PROSPECTING.ERRORS.REMOVE_LEAD_FROM_LIST'));
  } finally {
    busyLeadId.value = null;
  }
};

const createContact = async lead => {
  if (!lead?.id || lead.contact_id || convertingLeadId.value) return;

  convertingLeadId.value = lead.id;
  try {
    const { data } = await AutonomiaProspectingAPI.createLeadContact(lead.id);
    replaceLead(data.payload?.lead);
    useAlert(t('PROSPECTING.SEARCH.CONTACT_CREATED'));
  } catch (e) {
    alertError(e, t('PROSPECTING.ERRORS.CREATE_CONTACT'));
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
  try {
    const { data } = await AutonomiaProspectingAPI.createLeadCrmCard(lead.id, {
      pipeline_id: crmForm.value.pipeline_id,
      stage_id: crmForm.value.stage_id,
    });
    replaceLead(data.payload?.lead);
    useAlert(t('PROSPECTING.SEARCH.CRM_CARD_CREATED'));
  } catch (e) {
    alertError(e, t('PROSPECTING.ERRORS.CREATE_CRM_CARD'));
  } finally {
    convertingCrmLeadId.value = null;
  }
};

const createCampaignSegment = async () => {
  if (
    !selectedList.value?.id ||
    isCreatingCampaignSegment.value ||
    !campaignReadyLeads.value.length
  ) {
    return;
  }

  isCreatingCampaignSegment.value = true;
  try {
    const { data } = await AutonomiaProspectingAPI.createCampaignSegment(
      selectedList.value.id,
      {
        campaign_id: campaignSegmentForm.value.campaign_id,
        segment_name:
          campaignSegmentForm.value.segment_name || selectedList.value.name,
      }
    );
    selectedList.value = data.payload?.list || selectedList.value;
    await fetchLists();
    useAlert(
      t('PROSPECTING.LISTS.CAMPAIGN_SEGMENT_CREATED', {
        label: data.payload?.segment?.label?.title || '-',
      })
    );
    showCampaignModal.value = false;
  } catch (e) {
    alertError(e, t('PROSPECTING.ERRORS.CREATE_CAMPAIGN_SEGMENT'));
  } finally {
    isCreatingCampaignSegment.value = false;
  }
};

onMounted(loadPage);
</script>

<template>
  <main
    class="flex h-full min-h-0 w-full flex-col overflow-hidden bg-n-background"
  >
    <header
      class="flex items-center justify-between gap-4 border-b border-n-weak px-6 py-4"
    >
      <div class="min-w-0">
        <h1 class="text-xl font-semibold text-n-slate-12">
          {{ t('PROSPECTING.LISTS.TITLE') }}
        </h1>
        <p class="mt-1 text-sm text-n-slate-10">
          {{
            t('PROSPECTING.LISTS.HEADER_SUMMARY', {
              lists: lists.length,
              leads: allLeads.length,
            })
          }}
        </p>
      </div>
      <button
        type="button"
        class="inline-flex h-9 items-center gap-2 rounded-md bg-n-brand px-3 text-sm font-medium text-white hover:opacity-90 disabled:cursor-not-allowed disabled:opacity-60"
        :title="t('PROSPECTING.LISTS.NEW_LIST')"
        @click="openCreateListModal"
      >
        <span class="i-lucide-plus size-4" />
        <span>{{ t('PROSPECTING.LISTS.NEW_LIST') }}</span>
      </button>
    </header>

    <section
      class="flex min-h-0 w-full flex-1 flex-col gap-4 overflow-hidden px-6 py-5"
    >
      <div
        class="grid min-h-0 w-full flex-1 gap-4 xl:grid-cols-[22rem_minmax(0,1fr)]"
      >
        <aside class="flex min-h-0 flex-col overflow-hidden">
          <div class="mb-3 flex items-center justify-between gap-3">
            <h2 class="text-sm font-semibold text-n-slate-12">
              {{ t('PROSPECTING.LISTS.ALL_LISTS') }}
            </h2>
            <span class="text-xs text-n-slate-10">
              {{
                t('PROSPECTING.LISTS.LISTS_COUNT', {
                  count: lists.length,
                })
              }}
            </span>
          </div>
          <div
            v-if="isLoading"
            class="rounded-md border border-n-weak bg-n-solid-1 px-4 py-8 text-sm text-n-slate-11"
          >
            {{ t('PROSPECTING.STATES.LOADING') }}
          </div>
          <div
            v-else-if="!lists.length"
            class="rounded-md border border-n-weak bg-n-solid-1 px-4 py-8 text-sm text-n-slate-11"
          >
            {{ t('PROSPECTING.LISTS.EMPTY') }}
          </div>
          <div v-else class="min-h-0 flex-1 overflow-y-auto pr-1">
            <article
              v-for="list in lists"
              :key="list.id"
              class="relative mb-3 overflow-hidden rounded-md border border-n-weak bg-n-solid-1 transition last:mb-0 hover:border-n-slate-7 hover:bg-n-solid-2"
              :class="{
                'border-n-brand bg-n-brand-2 shadow-sm ring-1 ring-n-brand/30':
                  selectedList?.id === list.id,
              }"
            >
              <span
                v-if="selectedList?.id === list.id"
                class="absolute inset-y-0 left-0 w-1 bg-n-brand"
              />
              <button
                type="button"
                class="grid w-full gap-2 p-3 pl-4 text-left"
                @click="selectList(list)"
              >
                <div class="flex items-start justify-between gap-3">
                  <div class="min-w-0">
                    <h3 class="truncate text-sm font-semibold text-n-slate-12">
                      {{ list.name }}
                    </h3>
                    <p class="mt-1 truncate text-xs text-n-slate-10">
                      {{
                        list.description ||
                        t('PROSPECTING.LISTS.NO_DESCRIPTION')
                      }}
                    </p>
                  </div>
                  <span
                    class="rounded-md bg-n-solid-3 px-2 py-1 text-xs text-n-slate-11"
                    :class="{
                      'bg-n-brand text-white': selectedList?.id === list.id,
                    }"
                  >
                    {{ list.leads_count || 0 }}
                  </span>
                </div>
                <div
                  class="flex flex-wrap items-center gap-2 text-xs text-n-slate-10"
                >
                  <span>{{ formatDate(list.created_at) }}</span>
                  <span v-if="list.campaign_segment">·</span>
                  <span v-if="list.campaign_segment" class="text-n-teal-11">
                    {{ t('PROSPECTING.LISTS.SEGMENT_READY') }}
                  </span>
                </div>
              </button>
              <div
                class="flex items-center gap-1 border-t border-n-weak px-2 py-2"
              >
                <button
                  type="button"
                  class="flex size-8 items-center justify-center rounded-md text-n-slate-11 hover:bg-n-solid-3"
                  :title="t('PROSPECTING.LISTS.ADD_LEADS_TITLE')"
                  @click.stop="openAddLeadsModal(list)"
                >
                  <span class="i-lucide-user-plus size-4" />
                </button>
                <button
                  type="button"
                  class="flex size-8 items-center justify-center rounded-md text-n-slate-11 hover:bg-n-solid-3"
                  :title="t('PROSPECTING.LISTS.CAMPAIGN_SEGMENT_TITLE')"
                  @click.stop="openCampaignModal(list)"
                >
                  <span class="i-lucide-megaphone size-4" />
                </button>
              </div>
            </article>
          </div>
        </aside>

        <section
          class="flex min-h-0 flex-col overflow-hidden rounded-md border border-n-weak bg-n-solid-1"
        >
          <div class="border-b border-n-weak px-4 py-3">
            <div
              class="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between"
            >
              <div class="min-w-0">
                <h2 class="truncate text-base font-semibold text-n-slate-12">
                  {{
                    hasSelectedList
                      ? selectedList.name
                      : t('PROSPECTING.LISTS.DETAIL_TITLE')
                  }}
                </h2>
                <p
                  v-if="selectedList?.description"
                  class="mt-1 truncate text-sm text-n-slate-10"
                >
                  {{ selectedList.description }}
                </p>
              </div>
            </div>
            <div
              v-if="hasSelectedList"
              class="mt-4 grid gap-2 sm:grid-cols-2 lg:grid-cols-4"
            >
              <div
                class="rounded-md border border-n-weak bg-n-solid-2 px-3 py-2"
              >
                <div class="text-xs text-n-slate-10">
                  {{ t('PROSPECTING.LISTS.METRICS.LEADS') }}
                </div>
                <div class="text-sm font-semibold text-n-slate-12">
                  {{ selectedList.leads_count || 0 }}
                </div>
              </div>
              <div
                class="rounded-md border border-n-weak bg-n-solid-2 px-3 py-2"
              >
                <div class="text-xs text-n-slate-10">
                  {{ t('PROSPECTING.LISTS.METRICS.READY') }}
                </div>
                <div class="text-sm font-semibold text-n-teal-11">
                  {{ campaignReadyLeads.length }}
                </div>
              </div>
              <div
                class="rounded-md border border-n-weak bg-n-solid-2 px-3 py-2"
              >
                <div class="text-xs text-n-slate-10">
                  {{ t('PROSPECTING.LISTS.METRICS.CONTACTS') }}
                </div>
                <div class="text-sm font-semibold text-n-slate-12">
                  {{ selectedListContactCount }}
                </div>
              </div>
              <div
                class="rounded-md border border-n-weak bg-n-solid-2 px-3 py-2"
              >
                <div class="text-xs text-n-slate-10">
                  {{ t('PROSPECTING.LISTS.METRICS.CRM') }}
                </div>
                <div class="text-sm font-semibold text-n-slate-12">
                  {{ selectedListCrmCount }}
                </div>
              </div>
            </div>
          </div>

          <div class="min-h-0 flex-1 overflow-y-auto">
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
            <div v-else class="grid min-w-0 gap-3 p-4">
              <article
                v-for="lead in listLeads"
                :key="lead.id"
                class="grid min-w-0 gap-3 overflow-hidden rounded-lg border border-n-weak bg-n-solid-1 text-sm transition-colors hover:border-n-slate-5"
              >
                <div class="flex min-w-0 items-start gap-3 p-4 pb-2">
                  <ProspectingPriorityRing
                    :priority="leadPriority(lead)"
                    :size="56"
                  />
                  <div class="min-w-0 flex-1">
                    <div class="flex flex-wrap items-center gap-1.5">
                      <span
                        v-if="lead.search_rank"
                        class="inline-flex items-center rounded bg-n-amber-2 px-1.5 py-0.5 text-[10px] font-bold leading-tight text-n-amber-11 ring-1 ring-n-amber-5"
                      >
                        {{
                          t('PROSPECTING.SEARCH.PRIORITY_GOOGLE_RANK', {
                            rank: lead.search_rank,
                          })
                        }}
                      </span>
                      <span
                        v-if="lead.priority_position"
                        class="text-[11px] text-n-slate-10"
                      >
                        {{
                          t('PROSPECTING.SEARCH.PRIORITY_POSITION', {
                            position: lead.priority_position,
                          })
                        }}
                      </span>
                      <span
                        v-if="lead.priority_position === 1"
                        class="inline-flex items-center gap-0.5 rounded-full bg-n-teal-2 px-1.5 py-0.5 text-[10px] font-semibold leading-tight text-n-teal-11 ring-1 ring-n-teal-5"
                      >
                        <span class="i-lucide-zap size-3" />
                        {{ t('PROSPECTING.SEARCH.PRIORITY_FIRST_CALL_SHORT') }}
                      </span>
                    </div>
                    <h3
                      class="mt-1 break-words text-base font-semibold leading-tight text-n-slate-12"
                    >
                      {{ lead.name }}
                    </h3>
                    <div
                      class="mt-1 grid min-w-0 max-w-full grid-cols-[auto_auto_minmax(0,1fr)] items-baseline gap-1.5 overflow-hidden"
                    >
                      <span
                        v-if="leadPriorityTheme(lead)"
                        class="text-xs font-medium"
                        :class="leadPriorityTheme(lead).titleClass"
                      >
                        {{ leadPriorityTheme(lead).title }}
                      </span>
                      <span
                        v-if="leadPriorityTheme(lead)"
                        class="text-n-slate-6"
                      >
                        ·
                      </span>
                      <span
                        class="min-w-0 flex-1 truncate text-sm text-n-slate-10"
                      >
                        {{ formatLeadAddress(lead) || '-' }}
                      </span>
                    </div>
                  </div>
                </div>

                <div
                  v-if="leadSignals(lead).length"
                  class="flex flex-wrap gap-1.5 px-4 pb-2"
                >
                  <a
                    v-for="signal in leadSignals(lead)"
                    v-show="signal.key === 'website' && lead.website"
                    :key="`${signal.key}-link`"
                    :href="lead.website"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="inline-flex items-center gap-1 rounded-full border px-2 py-0.5 text-[11px] font-medium hover:underline"
                    :class="signal.card"
                  >
                    <span
                      :class="[signal.icon, signal.iconClass]"
                      class="size-3"
                    />
                    {{ signal.label }}
                  </a>
                  <span
                    v-for="signal in leadSignals(lead).filter(
                      item => item.key !== 'website' || !lead.website
                    )"
                    :key="signal.key"
                    class="inline-flex items-center gap-1 rounded-full border px-2 py-0.5 text-[11px] font-medium"
                    :class="signal.card"
                  >
                    <span
                      :class="[signal.icon, signal.iconClass]"
                      class="size-3"
                    />
                    {{ signal.label }}
                  </span>
                </div>

                <div
                  class="flex flex-wrap items-center gap-2 border-t border-n-weak px-4 pb-4 pt-3"
                >
                  <a
                    :href="googleMapsLeadUrl(lead)"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="inline-flex h-8 items-center gap-1 rounded-md border border-n-weak px-3 text-xs font-medium text-n-slate-12 hover:bg-n-solid-2"
                  >
                    <span class="i-lucide-map-pin size-3.5" />
                    {{ t('PROSPECTING.SEARCH.OPEN_MAP') }}
                  </a>
                  <span
                    v-if="lead.phone && isWhatsAppChecking(lead)"
                    class="inline-flex h-8 items-center gap-1.5 rounded-md border border-n-weak bg-n-solid-2 px-3 text-xs font-medium text-n-slate-10"
                  >
                    <span
                      class="size-3 animate-spin rounded-full border-2 border-n-slate-5 border-t-n-slate-11"
                    />
                    {{ t('PROSPECTING.SEARCH.CHECKING_WHATSAPP') }}
                  </span>
                  <a
                    v-else-if="
                      lead.phone &&
                      !isWhatsAppUnavailable(lead) &&
                      leadWhatsAppUrl(lead)
                    "
                    :href="leadWhatsAppUrl(lead)"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="inline-flex h-8 items-center gap-1 rounded-md px-3 text-xs font-semibold transition-colors"
                    :class="
                      isWhatsAppVerified(lead)
                        ? 'bg-n-teal-9 text-white shadow-sm hover:bg-n-teal-10'
                        : 'border border-n-teal-5 bg-n-solid-1 text-n-teal-11 hover:bg-n-teal-2'
                    "
                  >
                    <span class="i-lucide-message-circle size-3.5" />
                    {{ t('PROSPECTING.SEARCH.WHATSAPP') }}
                  </a>
                  <span
                    v-else
                    class="inline-flex h-8 cursor-not-allowed items-center gap-1 rounded-md border border-n-weak bg-n-solid-2 px-3 text-xs font-medium text-n-slate-8"
                  >
                    <span class="i-lucide-message-circle size-3.5" />
                    {{ t('PROSPECTING.SEARCH.NO_WHATSAPP') }}
                  </span>
                  <a
                    v-if="leadPhoneUrl(lead)"
                    :href="leadPhoneUrl(lead)"
                    class="inline-flex h-8 items-center gap-1 rounded-md border border-n-weak px-3 text-xs font-semibold text-n-slate-12 transition-colors hover:bg-n-solid-2"
                  >
                    <span class="i-lucide-phone size-3.5" />
                    {{ t('PROSPECTING.SEARCH.CALL') }}
                  </a>
                  <a
                    v-if="lead.contact_id"
                    :href="contactUrl(lead.contact_id)"
                    class="inline-flex h-8 items-center rounded-md border border-n-weak px-3 text-xs font-medium text-n-brand underline"
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
                  <a
                    v-if="lead.crm_card_id"
                    :href="crmCardUrl(lead.crm_card_id)"
                    class="inline-flex h-8 items-center rounded-md border border-n-weak px-3 text-xs font-medium text-n-brand underline"
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
                  <button
                    type="button"
                    class="flex size-8 items-center justify-center rounded-md border border-n-weak text-n-slate-12 hover:bg-n-solid-2 disabled:cursor-not-allowed disabled:opacity-60"
                    :title="t('PROSPECTING.LISTS.REMOVE_LEAD')"
                    :disabled="busyLeadId === lead.id"
                    @click="removeLead(lead)"
                  >
                    <span class="i-lucide-trash-2 size-4" />
                  </button>
                </div>
              </article>
            </div>
          </div>
        </section>
      </div>
    </section>

    <div
      v-if="showCreateListModal"
      class="fixed inset-0 z-40 flex items-center justify-center bg-n-slate-12/40 p-4"
      @click.self="showCreateListModal = false"
    >
      <form
        class="grid w-full max-w-md gap-4 rounded-md border border-n-weak bg-n-solid-1 p-4 shadow-xl"
        @submit.prevent="createList"
      >
        <div class="flex items-start justify-between gap-3">
          <h2 class="text-base font-semibold text-n-slate-12">
            {{ t('PROSPECTING.LISTS.CREATE_MODAL_TITLE') }}
          </h2>
          <button
            type="button"
            class="flex size-8 items-center justify-center rounded-md text-n-slate-11 hover:bg-n-solid-2"
            :title="t('PROSPECTING.LISTS.CLOSE')"
            @click="showCreateListModal = false"
          >
            <span class="i-lucide-x size-4" />
          </button>
        </div>
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
        <div class="flex justify-end gap-2">
          <button
            type="button"
            class="h-9 rounded-md border border-n-weak px-3 text-sm font-medium text-n-slate-12 hover:bg-n-solid-2"
            @click="showCreateListModal = false"
          >
            {{ t('PROSPECTING.LISTS.CANCEL') }}
          </button>
          <button
            type="submit"
            class="h-9 rounded-md bg-n-brand px-3 text-sm font-medium text-white disabled:cursor-not-allowed disabled:opacity-60"
            :disabled="isCreating || !form.name.trim()"
          >
            {{
              isCreating
                ? t('PROSPECTING.LISTS.CREATING')
                : t('PROSPECTING.LISTS.CREATE')
            }}
          </button>
        </div>
      </form>
    </div>

    <div
      v-if="showAddLeadsModal"
      class="fixed inset-0 z-40 flex items-center justify-center bg-n-slate-12/40 p-4"
      @click.self="showAddLeadsModal = false"
    >
      <section
        class="flex max-h-[85vh] w-full max-w-3xl flex-col overflow-hidden rounded-md border border-n-weak bg-n-solid-1 shadow-xl"
      >
        <header
          class="flex items-start justify-between gap-3 border-b border-n-weak px-4 py-3"
        >
          <div class="min-w-0">
            <h2 class="truncate text-base font-semibold text-n-slate-12">
              {{ t('PROSPECTING.LISTS.ADD_LEADS_TITLE') }}
            </h2>
            <p class="mt-1 truncate text-xs text-n-slate-10">
              {{ selectedList?.name }}
            </p>
          </div>
          <button
            type="button"
            class="flex size-8 items-center justify-center rounded-md text-n-slate-11 hover:bg-n-solid-2"
            :title="t('PROSPECTING.LISTS.CLOSE')"
            @click="showAddLeadsModal = false"
          >
            <span class="i-lucide-x size-4" />
          </button>
        </header>
        <div
          class="grid gap-3 border-b border-n-weak p-4 md:grid-cols-[minmax(0,1fr)_12rem]"
        >
          <input
            v-model="addLeadQuery"
            class="h-9 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
            :placeholder="t('PROSPECTING.LISTS.SEARCH_AVAILABLE_LEADS')"
          />
          <select
            v-model="addLeadStatusFilter"
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
        </div>
        <div class="min-h-0 flex-1 overflow-y-auto p-4">
          <div
            v-if="!filteredAvailableLeads.length"
            class="py-8 text-sm text-n-slate-11"
          >
            {{ t('PROSPECTING.LISTS.NO_AVAILABLE_LEADS') }}
          </div>
          <div v-else class="grid min-w-0 gap-3">
            <div
              class="flex flex-wrap items-center justify-between gap-2 text-xs"
            >
              <div class="flex flex-wrap items-center gap-3">
                <button
                  type="button"
                  class="font-medium text-n-brand hover:underline disabled:cursor-not-allowed disabled:opacity-60"
                  :disabled="!filteredAvailableLeads.length"
                  @click="toggleAllFilteredAvailableLeads"
                >
                  {{ t('PROSPECTING.SEARCH.SELECT_VISIBLE') }}
                </button>
                <span v-if="hasSelectedAddLeads" class="text-n-slate-10">
                  {{
                    t('PROSPECTING.SEARCH.SELECTED_COUNT', {
                      count: selectedAddLeadsCount,
                    })
                  }}
                </span>
              </div>
              <span class="text-n-slate-10">
                {{
                  t('PROSPECTING.SEARCH.VISIBLE_COUNT', {
                    count: filteredAvailableLeads.length,
                  })
                }}
              </span>
            </div>
            <label
              v-for="lead in filteredAvailableLeads"
              :key="lead.id"
              class="grid min-w-0 cursor-pointer gap-2 overflow-hidden rounded-lg border border-n-weak bg-n-solid-1 p-3 text-sm transition-colors hover:border-n-slate-5 hover:bg-n-solid-2"
            >
              <span class="flex min-w-0 items-start gap-3">
                <input
                  type="checkbox"
                  class="mt-1 size-4 shrink-0"
                  :checked="
                    selectedAddLeadIds.map(Number).includes(Number(lead.id))
                  "
                  @change="toggleAddLeadSelection(lead.id)"
                />
                <ProspectingPriorityRing
                  :priority="leadPriority(lead)"
                  :size="44"
                />
                <span class="min-w-0 flex-1">
                  <span class="flex flex-wrap items-center gap-1.5">
                    <span
                      v-if="lead.search_rank"
                      class="inline-flex items-center rounded bg-n-amber-2 px-1.5 py-0.5 text-[10px] font-bold leading-tight text-n-amber-11 ring-1 ring-n-amber-5"
                    >
                      {{
                        t('PROSPECTING.SEARCH.PRIORITY_GOOGLE_RANK', {
                          rank: lead.search_rank,
                        })
                      }}
                    </span>
                    <span
                      v-if="lead.priority_position"
                      class="text-[11px] text-n-slate-10"
                    >
                      {{
                        t('PROSPECTING.SEARCH.PRIORITY_POSITION', {
                          position: lead.priority_position,
                        })
                      }}
                    </span>
                    <span
                      v-if="lead.priority_position === 1"
                      class="inline-flex items-center gap-0.5 rounded-full bg-n-teal-2 px-1.5 py-0.5 text-[10px] font-semibold leading-tight text-n-teal-11 ring-1 ring-n-teal-5"
                    >
                      <span class="i-lucide-zap size-3" />
                      {{ t('PROSPECTING.SEARCH.PRIORITY_FIRST_CALL_SHORT') }}
                    </span>
                  </span>
                  <span
                    class="mt-1 block break-words text-sm font-semibold leading-tight text-n-slate-12"
                  >
                    {{ lead.name }}
                  </span>
                  <span
                    class="mt-1 grid min-w-0 max-w-full grid-cols-[auto_auto_minmax(0,1fr)] items-baseline gap-1.5 overflow-hidden"
                  >
                    <span
                      v-if="leadPriorityTheme(lead)"
                      class="text-xs font-medium"
                      :class="leadPriorityTheme(lead).titleClass"
                    >
                      {{ leadPriorityTheme(lead).title }}
                    </span>
                    <span v-if="leadPriorityTheme(lead)" class="text-n-slate-6">
                      ·
                    </span>
                    <span
                      class="min-w-0 flex-1 truncate text-xs text-n-slate-10"
                    >
                      {{ formatLeadAddress(lead) || lead.phone || '-' }}
                    </span>
                  </span>
                </span>
              </span>
              <span
                v-if="leadSignals(lead).length"
                class="flex flex-wrap gap-1.5 pl-20"
              >
                <span
                  v-for="signal in leadSignals(lead)"
                  :key="signal.key"
                  class="inline-flex items-center gap-1 rounded-full border px-2 py-0.5 text-[11px] font-medium"
                  :class="signal.card"
                >
                  <span
                    :class="[signal.icon, signal.iconClass]"
                    class="size-3"
                  />
                  {{ signal.label }}
                </span>
              </span>
            </label>
          </div>
        </div>
        <footer
          class="flex flex-wrap items-center justify-between gap-3 border-t border-n-weak px-4 py-3"
        >
          <span class="text-xs text-n-slate-10">
            {{
              t('PROSPECTING.LISTS.SELECTED_LEADS_COUNT', {
                count: selectedAddLeadsCount,
              })
            }}
          </span>
          <div class="flex gap-2">
            <button
              type="button"
              class="h-9 rounded-md border border-n-weak px-3 text-sm font-medium text-n-slate-12 hover:bg-n-solid-2"
              @click="showAddLeadsModal = false"
            >
              {{ t('PROSPECTING.LISTS.CANCEL') }}
            </button>
            <button
              type="button"
              class="h-9 rounded-md bg-n-brand px-3 text-sm font-medium text-white disabled:cursor-not-allowed disabled:opacity-60"
              :disabled="isAddingSelectedLeads || !selectedAddLeadsCount"
              @click="addSelectedLeads"
            >
              {{
                isAddingSelectedLeads
                  ? t('PROSPECTING.LISTS.ADDING_LEADS')
                  : t('PROSPECTING.LISTS.ADD_SELECTED_LEADS')
              }}
            </button>
          </div>
        </footer>
      </section>
    </div>

    <div
      v-if="showCampaignModal"
      class="fixed inset-0 z-40 flex items-center justify-center bg-n-slate-12/40 p-4"
      @click.self="showCampaignModal = false"
    >
      <section
        class="grid w-full max-w-2xl gap-5 rounded-md border border-n-weak bg-n-solid-1 p-5 shadow-xl"
      >
        <div class="flex items-start justify-between gap-3">
          <div class="min-w-0">
            <h2 class="text-base font-semibold text-n-slate-12">
              {{ t('PROSPECTING.LISTS.CAMPAIGN_SEGMENT_TITLE') }}
            </h2>
            <p class="mt-1 text-sm text-n-slate-10">
              {{ selectedList?.name }}
            </p>
          </div>
          <button
            type="button"
            class="flex size-8 items-center justify-center rounded-md text-n-slate-11 hover:bg-n-solid-2"
            :title="t('PROSPECTING.LISTS.CLOSE')"
            @click="showCampaignModal = false"
          >
            <span class="i-lucide-x size-4" />
          </button>
        </div>
        <div class="grid gap-2 sm:grid-cols-3">
          <div class="rounded-md border border-n-weak bg-n-solid-2 px-3 py-2">
            <div class="text-xs text-n-slate-10">
              {{ t('PROSPECTING.LISTS.METRICS.READY') }}
            </div>
            <div class="text-base font-semibold text-n-teal-11">
              {{ campaignReadyLeads.length }}
            </div>
          </div>
          <div class="rounded-md border border-n-weak bg-n-solid-2 px-3 py-2">
            <div class="text-xs text-n-slate-10">
              {{ t('PROSPECTING.LISTS.METRICS.BLOCKED') }}
            </div>
            <div class="text-base font-semibold text-n-amber-11">
              {{ campaignBlockedLeads.length }}
            </div>
          </div>
          <div class="rounded-md border border-n-weak bg-n-solid-2 px-3 py-2">
            <div class="text-xs text-n-slate-10">
              {{ t('PROSPECTING.LISTS.METRICS.SEGMENT') }}
            </div>
            <div class="truncate text-base font-semibold text-n-slate-12">
              {{ currentCampaignSegment?.label_title || '-' }}
            </div>
          </div>
        </div>
        <div class="grid gap-4 md:grid-cols-2">
          <div class="grid content-start gap-1">
            <label
              for="prospecting-campaign-segment-name"
              class="text-xs font-medium text-n-slate-11"
            >
              {{ t('PROSPECTING.LISTS.FIELDS.SEGMENT_NAME') }}
            </label>
            <input
              id="prospecting-campaign-segment-name"
              v-model="campaignSegmentForm.segment_name"
              class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
              :placeholder="selectedList?.name"
            />
          </div>
          <div class="grid content-start gap-1">
            <label
              for="prospecting-campaign-id"
              class="text-xs font-medium text-n-slate-11"
            >
              {{ t('PROSPECTING.LISTS.FIELDS.CAMPAIGN') }}
            </label>
            <select
              id="prospecting-campaign-id"
              v-model="campaignSegmentForm.campaign_id"
              class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-2 text-sm text-n-slate-12"
            >
              <option value="">
                {{ t('PROSPECTING.LISTS.CAMPAIGN_SEGMENT_ONLY_LABEL') }}
              </option>
              <option
                v-for="campaign in availableCampaigns"
                :key="campaign.id"
                :value="campaign.id"
              >
                {{ campaign.title }}
              </option>
            </select>
          </div>
        </div>
        <p class="text-xs text-n-slate-10">
          {{ t('PROSPECTING.LISTS.CAMPAIGN_SEGMENT_HINT') }}
        </p>
        <div class="flex justify-end gap-2">
          <button
            type="button"
            class="h-9 rounded-md border border-n-weak px-3 text-sm font-medium text-n-slate-12 hover:bg-n-solid-2"
            @click="showCampaignModal = false"
          >
            {{ t('PROSPECTING.LISTS.CANCEL') }}
          </button>
          <button
            type="button"
            class="h-9 rounded-md bg-n-brand px-3 text-sm font-medium text-white disabled:cursor-not-allowed disabled:opacity-60"
            :disabled="isCreatingCampaignSegment || !campaignReadyLeads.length"
            @click="createCampaignSegment"
          >
            {{
              isCreatingCampaignSegment
                ? t('PROSPECTING.LISTS.CAMPAIGN_SEGMENT_CREATING')
                : t('PROSPECTING.LISTS.CAMPAIGN_SEGMENT_CREATE')
            }}
          </button>
        </div>
      </section>
    </div>
  </main>
</template>
