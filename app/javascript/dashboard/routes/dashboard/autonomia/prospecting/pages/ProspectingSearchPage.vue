<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import AutonomiaProspectingAPI from 'dashboard/api/autonomiaProspecting';
import CrmKanbanAPI from 'dashboard/api/crmKanban';
import ProspectingGoogleMap from '../components/ProspectingGoogleMap.vue';
import ProspectingPriorityRing from '../components/ProspectingPriorityRing.vue';
import {
  leadPrioritySignals,
  priorityTheme,
  priorityValue,
} from '../utils/prospectingPriority';

const { t } = useI18n();
const route = useRoute();

const isLoading = ref(true);
const isSearching = ref(false);
const isSuggestingLocations = ref(false);
const convertingLeadId = ref(null);
const convertingCrmLeadId = ref(null);
const verifyingWhatsAppLeadIds = ref([]);
const selectedLeadIds = ref([]);
const bulkAction = ref('');
const searches = ref([]);
const leads = ref([]);
const settings = ref(null);
const crmPipelines = ref([]);
const crmStages = ref([]);
const searchConfigStages = ref([]);
const locationSuggestions = ref([]);
const locationDetails = ref(null);
const confirmedLocation = ref('');
const selectedSearchId = ref(null);
const selectedLeadDetailId = ref(null);
const sortKey = ref('priority_desc');
const editingSearchConfigId = ref(null);
const showNewSearch = ref(false);
const showFilters = ref(false);
const deletingSearchId = ref(null);
let locationSuggestionTimer;
const whatsappVerificationRequested = new Set();
let replaceLead = () => {};
let verifyLeadsWhatsApp = () => {};

const form = ref({
  query: '',
  location: '',
  radius_km: 5,
  requested_limit: 20,
});
const crmForm = ref({
  pipeline_id: '',
  stage_id: '',
});
const advancedFilters = ref({
  has_website: '',
  has_phone: '',
  rating_min: '',
  reviews_min: '',
});
const searchConfigForm = ref({
  crm_pipeline_id: '',
  crm_stage_id: '',
});

const hasResults = computed(() => leads.value.length > 0);
const filteredLeads = computed(() => {
  return leads.value.filter(lead => {
    if (advancedFilters.value.has_website === 'yes' && !lead.website)
      return false;
    if (advancedFilters.value.has_website === 'no' && lead.website)
      return false;
    if (advancedFilters.value.has_phone === 'yes' && !lead.phone) return false;
    if (advancedFilters.value.has_phone === 'no' && lead.phone) return false;

    const ratingMin = Number(advancedFilters.value.rating_min || 0);
    if (ratingMin > 0 && Number(lead.rating || 0) < ratingMin) return false;

    const reviewsMin = Number(advancedFilters.value.reviews_min || 0);
    if (reviewsMin > 0 && Number(lead.reviews_count || 0) < reviewsMin) {
      return false;
    }

    return true;
  });
});
const sortedLeads = computed(() => {
  const leadsToSort = [...filteredLeads.value];
  const numberValue = (lead, key, fallback = 0) =>
    Number(lead[key] || fallback);

  return leadsToSort.sort((first, second) => {
    if (sortKey.value === 'priority_desc') {
      const firstPosition = numberValue(
        first,
        'priority_position',
        Number.MAX_SAFE_INTEGER
      );
      const secondPosition = numberValue(
        second,
        'priority_position',
        Number.MAX_SAFE_INTEGER
      );
      if (firstPosition !== secondPosition) {
        return firstPosition - secondPosition;
      }

      return (
        numberValue(second, 'priority_score') -
        numberValue(first, 'priority_score')
      );
    }
    if (sortKey.value === 'score_desc') {
      return numberValue(second, 'score') - numberValue(first, 'score');
    }
    if (sortKey.value === 'rating_desc') {
      return numberValue(second, 'rating') - numberValue(first, 'rating');
    }
    if (sortKey.value === 'reviews_desc') {
      return (
        numberValue(second, 'reviews_count') -
        numberValue(first, 'reviews_count')
      );
    }
    if (sortKey.value === 'name_asc') {
      return String(first.name || '').localeCompare(String(second.name || ''));
    }
    if (sortKey.value === 'created_asc') {
      return (
        new Date(first.created_at).getTime() -
        new Date(second.created_at).getTime()
      );
    }

    return (
      new Date(second.created_at).getTime() -
      new Date(first.created_at).getTime()
    );
  });
});
const selectedSearch = computed(() =>
  searches.value.find(search => search.id === selectedSearchId.value)
);
const selectedSearchConfig = computed(() =>
  searches.value.find(search => search.id === editingSearchConfigId.value)
);
const selectedLeadDetail = computed(() =>
  leads.value.find(lead => lead.id === selectedLeadDetailId.value)
);
const canCreateCrmCard = computed(() =>
  Boolean(crmForm.value.pipeline_id && crmForm.value.stage_id)
);
const canSearch = computed(
  () =>
    form.value.query.trim().length > 0 &&
    confirmedLocation.value.trim().length > 0 &&
    !isSearching.value
);
const hasSelectedLeads = computed(() => selectedLeadIds.value.length > 0);
const selectedStageName = computed(() => {
  const stage = crmStages.value.find(
    item => Number(item.id) === Number(crmForm.value.stage_id)
  );
  return stage?.name || t('PROSPECTING.SEARCH.CRM_STAGE_EMPTY');
});
const selectedLeadObjects = computed(() => {
  const ids = new Set(selectedLeadIds.value.map(Number));
  return sortedLeads.value.filter(lead => ids.has(Number(lead.id)));
});
const activeAdvancedFiltersCount = computed(
  () => Object.values(advancedFilters.value).filter(Boolean).length
);
const activeFiltersCount = computed(() => activeAdvancedFiltersCount.value);
const autocompleteHint = computed(() => {
  if (isSuggestingLocations.value) {
    return t('PROSPECTING.SEARCH.SUGGESTING_LOCATIONS');
  }

  if (confirmedLocation.value) {
    return t('PROSPECTING.SEARCH.LOCATION_CONFIRMED');
  }

  return settings.value?.has_google_places_api_key
    ? t('PROSPECTING.SEARCH.AUTOCOMPLETE_READY_HINT')
    : t('PROSPECTING.SEARCH.AUTOCOMPLETE_DISABLED_HINT');
});
const selectedLocationLabel = computed(
  () => locationDetails.value?.label || confirmedLocation.value
);
const combinedLocationSuggestions = computed(() => {
  const seen = new Set();
  return locationSuggestions.value.filter(item => {
    const key = item.place_id || item.text;
    if (!key || seen.has(key)) return false;
    seen.add(key);
    return true;
  });
});
const mapLeads = computed(() =>
  sortedLeads.value.filter(lead => lead.latitude && lead.longitude)
);
const leadPriority = lead => priorityValue(lead);
const leadPriorityTheme = lead => {
  const priority = leadPriority(lead);
  return priority === null ? null : priorityTheme(priority);
};
const leadSignals = lead => leadPrioritySignals(lead);
const googleMapsApiKey = computed(
  () => settings.value?.google_maps_api_key || ''
);
const previewMapCenter = computed(() => {
  if (!locationDetails.value?.latitude || !locationDetails.value?.longitude) {
    return null;
  }

  return {
    lat: Number(locationDetails.value.latitude),
    lng: Number(locationDetails.value.longitude),
  };
});
const resultsMapCenter = computed(() => {
  if (
    selectedSearch.value?.location_latitude &&
    selectedSearch.value?.location_longitude
  ) {
    return {
      lat: Number(selectedSearch.value.location_latitude),
      lng: Number(selectedSearch.value.location_longitude),
    };
  }

  return null;
});

const fetchSettings = async () => {
  try {
    const { data } = await AutonomiaProspectingAPI.getSettings();
    settings.value = data.payload || {};
    form.value.requested_limit =
      settings.value.default_limit || form.value.requested_limit;
  } catch {
    settings.value = null;
  }
};

const fetchSearches = async () => {
  const { data } = await AutonomiaProspectingAPI.getSearches();
  searches.value = data.payload || [];
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

const fetchLocationSuggestions = () => {
  window.clearTimeout(locationSuggestionTimer);
  locationSuggestionTimer = window.setTimeout(async () => {
    const query = form.value.location.trim();
    if (query.length < 3) {
      locationSuggestions.value = [];
      return;
    }

    isSuggestingLocations.value = true;
    try {
      const { data } =
        await AutonomiaProspectingAPI.getLocationSuggestions(query);
      locationSuggestions.value = data.payload || [];
    } catch {
      locationSuggestions.value = [];
    } finally {
      isSuggestingLocations.value = false;
    }
  }, 280);
};

const handleLocationInput = () => {
  confirmedLocation.value = '';
  locationDetails.value = null;
  fetchLocationSuggestions();
};

const fetchLocationDetails = async suggestion => {
  if (!suggestion?.place_id) {
    locationDetails.value = suggestion?.text
      ? {
          label: suggestion.label || suggestion.text,
          place_id: '',
          latitude: suggestion.latitude,
          longitude: suggestion.longitude,
        }
      : null;
    confirmedLocation.value = suggestion?.label || suggestion?.text || '';
    return;
  }

  try {
    const { data } = await AutonomiaProspectingAPI.getLocationDetails(
      suggestion.place_id
    );
    locationDetails.value = data.payload || null;
    if (locationDetails.value?.label) {
      form.value.location = locationDetails.value.label;
      confirmedLocation.value = locationDetails.value.label;
    } else {
      confirmedLocation.value = suggestion.text || form.value.location.trim();
    }
  } catch {
    locationDetails.value = null;
    confirmedLocation.value = '';
  }
};

const confirmLocationSuggestion = async suggestion => {
  if (!suggestion?.text) return;

  form.value.location = suggestion.text;
  await fetchLocationDetails(suggestion);
  locationSuggestions.value = [];
};

const applyCrmTarget = async search => {
  const pipelineId =
    search?.crm_pipeline_id || settings.value?.default_crm_pipeline_id || '';
  const stageId =
    search?.crm_stage_id || settings.value?.default_crm_stage_id || '';

  crmForm.value.pipeline_id = pipelineId;
  await fetchCrmStages(pipelineId, stageId);
};

const selectSearchPayload = async payload => {
  leads.value = payload.leads || [];
  selectedSearchId.value = payload.id || payload.search?.id;
  selectedLeadIds.value = [];
  selectedLeadDetailId.value = null;
  await applyCrmTarget(payload.search || payload);
  verifyLeadsWhatsApp(leads.value);
};

const alertError = (error, fallbackMessage) => {
  useAlert(error?.response?.data?.error || fallbackMessage);
};

const submitSearch = async () => {
  if (!canSearch.value) return;

  isSearching.value = true;
  leads.value = [];

  try {
    const { data } = await AutonomiaProspectingAPI.createSearch({
      query: form.value.query.trim(),
      location: form.value.location.trim(),
      radius: Number(form.value.radius_km) * 1000,
      requested_limit: Number(form.value.requested_limit),
      crm_pipeline_id: crmForm.value.pipeline_id,
      crm_stage_id: crmForm.value.stage_id,
      metadata: {
        location_place_id: locationDetails.value?.place_id,
        location_latitude: locationDetails.value?.latitude,
        location_longitude: locationDetails.value?.longitude,
        location_label:
          selectedLocationLabel.value || form.value.location.trim(),
      },
    });

    const payload = data.payload || {};
    await fetchSearches();
    await selectSearchPayload(payload);
    showNewSearch.value = false;
  } catch (e) {
    alertError(e, t('PROSPECTING.ERRORS.CREATE_SEARCH'));
  } finally {
    isSearching.value = false;
  }
};

const openSearch = async search => {
  selectedSearchId.value = search.id;
  selectedLeadIds.value = [];
  selectedLeadDetailId.value = null;
  isLoading.value = true;

  try {
    const { data } = await AutonomiaProspectingAPI.getSearch(search.id);
    await selectSearchPayload(data.payload || {});
  } catch {
    useAlert(t('PROSPECTING.ERRORS.LOAD_SEARCH'));
  } finally {
    isLoading.value = false;
  }
};

const toggleNewSearch = () => {
  selectedLeadDetailId.value = null;
  showNewSearch.value = !showNewSearch.value;
};

const deleteSearch = async search => {
  if (!search?.id || deletingSearchId.value) return;

  deletingSearchId.value = search.id;
  try {
    await AutonomiaProspectingAPI.deleteSearch(search.id);
    searches.value = searches.value.filter(item => item.id !== search.id);
    if (selectedSearchId.value === search.id) {
      leads.value = [];
      selectedLeadIds.value = [];
      selectedLeadDetailId.value = null;
      selectedSearchId.value = searches.value[0]?.id || null;
      if (selectedSearchId.value) await openSearch(searches.value[0]);
    }
  } catch (e) {
    alertError(e, t('PROSPECTING.ERRORS.DELETE_SEARCH'));
  } finally {
    deletingSearchId.value = null;
  }
};

const formatShortDate = value => {
  if (!value) return '-';
  return new Date(value).toLocaleDateString();
};

const formatRelativeTime = value => {
  if (!value) return '-';

  const diff = Date.now() - new Date(value).getTime();
  const minutes = Math.floor(diff / 60000);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);
  if (minutes < 1) return t('PROSPECTING.SEARCH.TIME_NOW');
  if (minutes < 60) {
    return t('PROSPECTING.SEARCH.TIME_MINUTES_AGO', { count: minutes });
  }
  if (hours < 24) {
    return t('PROSPECTING.SEARCH.TIME_HOURS_AGO', { count: hours });
  }
  if (days < 7) return t('PROSPECTING.SEARCH.TIME_DAYS_AGO', { count: days });
  return formatShortDate(value);
};

const formatRadius = radius => {
  const kilometers = Number(radius || 0) / 1000;
  return t('PROSPECTING.SEARCH.RADIUS_KM_VALUE', {
    value: Number.isInteger(kilometers) ? kilometers : kilometers.toFixed(1),
  });
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

const isWhatsAppVerified = lead => lead?.whatsapp_verified === true;
const isWhatsAppUnavailable = lead =>
  lead?.whatsapp_verification_status === 'not_whatsapp';
const isWhatsAppChecking = lead =>
  verifyingWhatsAppLeadIds.value.map(Number).includes(Number(lead?.id));

const shouldVerifyWhatsApp = lead =>
  lead?.id &&
  normalizedLeadPhone(lead) &&
  !lead?.whatsapp_verification_status &&
  !whatsappVerificationRequested.has(Number(lead.id));

async function verifyLeadWhatsApp(lead) {
  if (!shouldVerifyWhatsApp(lead)) return;

  const leadId = Number(lead.id);
  whatsappVerificationRequested.add(leadId);
  verifyingWhatsAppLeadIds.value = [...verifyingWhatsAppLeadIds.value, leadId];

  try {
    const { data } = await AutonomiaProspectingAPI.verifyLeadWhatsApp(lead.id);
    replaceLead(data.payload?.lead);
  } catch {
    // Falha de WAHA/configuração não deve bloquear o trabalho com o lead.
  } finally {
    verifyingWhatsAppLeadIds.value = verifyingWhatsAppLeadIds.value.filter(
      id => Number(id) !== leadId
    );
  }
}

verifyLeadsWhatsApp = leadsToVerify => {
  leadsToVerify
    .filter(shouldVerifyWhatsApp)
    .slice(0, 25)
    .reduce(
      (promise, lead) => promise.then(() => verifyLeadWhatsApp(lead)),
      Promise.resolve()
    );
};

replaceLead = updatedLead => {
  if (!updatedLead?.id) return;
  leads.value = leads.value.map(item =>
    item.id === updatedLead.id ? updatedLead : item
  );
};

const createContact = async (lead, options = {}) => {
  if (!lead?.id || lead.contact_id || convertingLeadId.value) return;

  convertingLeadId.value = lead.id;

  try {
    const { data } = await AutonomiaProspectingAPI.createLeadContact(lead.id);
    replaceLead(data.payload?.lead);
    if (options.showAlert !== false) {
      useAlert(t('PROSPECTING.SEARCH.CONTACT_CREATED'));
    }
  } catch (e) {
    alertError(e, t('PROSPECTING.ERRORS.CREATE_CONTACT'));
  } finally {
    convertingLeadId.value = null;
  }
};

const createCrmCard = async (lead, options = {}) => {
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
    if (options.showAlert !== false) {
      useAlert(t('PROSPECTING.SEARCH.CRM_CARD_CREATED'));
    }
  } catch (e) {
    alertError(e, t('PROSPECTING.ERRORS.CREATE_CRM_CARD'));
  } finally {
    convertingCrmLeadId.value = null;
  }
};

const runBulkAction = async action => {
  if (!hasSelectedLeads.value || bulkAction.value) return;

  bulkAction.value = action;

  try {
    if (action === 'contacts') {
      await selectedLeadObjects.value
        .filter(item => !item.contact_id)
        .reduce(
          (promise, lead) =>
            promise.then(() => createContact(lead, { showAlert: false })),
          Promise.resolve()
        );
      useAlert(t('PROSPECTING.SEARCH.CONTACT_CREATED'));
    }

    if (action === 'crm_cards') {
      await selectedLeadObjects.value
        .filter(item => !item.crm_card_id)
        .reduce(
          (promise, lead) =>
            promise.then(() => createCrmCard(lead, { showAlert: false })),
          Promise.resolve()
        );
      useAlert(t('PROSPECTING.SEARCH.CRM_CARD_CREATED'));
    }
  } finally {
    bulkAction.value = '';
  }
};

const csvValueFor = (lead, key) => {
  if (key === 'source') return lead.source_label || lead.provider;
  if (key === 'address') return formatLeadAddress(lead);
  return lead[key] || '';
};

const exportCsv = () => {
  const rows = selectedLeadObjects.value.length
    ? selectedLeadObjects.value
    : sortedLeads.value;
  const header = ['name', 'phone', 'website', 'address', 'status', 'source'];
  const csvRows = rows.map(lead =>
    header
      .map(key => {
        const value = csvValueFor(lead, key);
        return `"${String(value).replaceAll('"', '""')}"`;
      })
      .join(',')
  );
  const blob = new Blob([[header.join(','), ...csvRows].join('\n')], {
    type: 'text/csv;charset=utf-8;',
  });
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = `prospeccao-${selectedSearchId.value || 'leads'}.csv`;
  link.click();
  URL.revokeObjectURL(link.href);
};

const toggleLeadSelection = leadId => {
  const ids = new Set(selectedLeadIds.value.map(Number));
  if (ids.has(Number(leadId))) {
    ids.delete(Number(leadId));
  } else {
    ids.add(Number(leadId));
  }
  selectedLeadIds.value = [...ids];
};

const toggleAllVisibleLeads = () => {
  if (selectedLeadIds.value.length === sortedLeads.value.length) {
    selectedLeadIds.value = [];
    return;
  }

  selectedLeadIds.value = sortedLeads.value.map(lead => lead.id);
};

const fetchSearchConfigStages = async (pipelineId, options = {}) => {
  searchConfigStages.value = [];
  if (!options.keepStage) searchConfigForm.value.crm_stage_id = '';
  if (!pipelineId) return;

  const { data } = await CrmKanbanAPI.getStages(pipelineId);
  searchConfigStages.value = data.payload || [];
  searchConfigForm.value.crm_stage_id =
    searchConfigForm.value.crm_stage_id ||
    searchConfigStages.value[0]?.id ||
    '';
};

const openSearchConfig = async search => {
  editingSearchConfigId.value = search.id;
  searchConfigForm.value = {
    crm_pipeline_id:
      search.crm_pipeline_id || settings.value?.default_crm_pipeline_id || '',
    crm_stage_id:
      search.crm_stage_id || settings.value?.default_crm_stage_id || '',
  };
  await fetchSearchConfigStages(searchConfigForm.value.crm_pipeline_id, {
    keepStage: true,
  });
};

const saveSearchConfig = async search => {
  if (!search?.id) return;

  try {
    const { data } = await AutonomiaProspectingAPI.updateSearch(search.id, {
      crm_pipeline_id: searchConfigForm.value.crm_pipeline_id,
      crm_stage_id: searchConfigForm.value.crm_stage_id,
    });
    searches.value = searches.value.map(item =>
      item.id === search.id ? data.payload : item
    );
    editingSearchConfigId.value = null;
    if (selectedSearchId.value === search.id) {
      await applyCrmTarget(data.payload);
    }
  } catch (e) {
    alertError(e, t('PROSPECTING.ERRORS.UPDATE_SEARCH'));
  }
};

onMounted(async () => {
  isLoading.value = true;
  try {
    await fetchSettings();
    await fetchCrmPipelines();
    await fetchSearches();
    if (searches.value.length) await openSearch(searches.value[0]);
  } catch {
    useAlert(t('PROSPECTING.ERRORS.LOAD_SEARCHES'));
  } finally {
    isLoading.value = false;
  }
});
</script>

<template>
  <main
    class="flex h-full min-h-0 w-full flex-col overflow-hidden bg-n-background"
  >
    <header
      class="flex flex-col gap-3 border-b border-n-weak px-6 py-4 sm:flex-row sm:items-center sm:justify-between"
    >
      <div>
        <h1 class="text-xl font-semibold text-n-slate-12">
          {{ t('PROSPECTING.SEARCH.TITLE') }}
        </h1>
        <p class="mt-1 text-sm text-n-slate-10">
          {{ t('PROSPECTING.SEARCH.SUBTITLE') }}
        </p>
      </div>
      <button
        type="button"
        class="inline-flex h-10 items-center justify-center gap-2 rounded-md bg-n-brand px-4 text-sm font-medium text-white"
        @click="toggleNewSearch"
      >
        <span
          class="size-4"
          :class="showNewSearch ? 'i-lucide-arrow-left' : 'i-lucide-plus'"
        />
        {{
          showNewSearch
            ? t('PROSPECTING.SEARCH.BACK_TO_RESULTS')
            : t('PROSPECTING.SEARCH.NEW_SEARCH')
        }}
      </button>
    </header>

    <section
      class="flex min-h-0 w-full flex-1 flex-col overflow-hidden px-6 py-5"
    >
      <form
        v-if="showNewSearch"
        class="min-h-0 overflow-y-auto rounded-lg border border-n-weak bg-n-solid-1"
        @submit.prevent="submitSearch"
      >
        <section class="border-b border-n-weak px-5 py-4">
          <div
            class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between"
          >
            <div>
              <h2 class="text-base font-semibold text-n-slate-12">
                {{ t('PROSPECTING.SEARCH.SECTIONS.WHERE') }}
              </h2>
              <p class="mt-1 text-sm text-n-slate-10">
                {{ t('PROSPECTING.SEARCH.LOCATION_HINT') }}
              </p>
            </div>
            <button
              type="submit"
              class="inline-flex h-10 items-center justify-center gap-2 rounded-md bg-n-brand px-4 text-sm font-medium text-white disabled:cursor-not-allowed disabled:opacity-60"
              :disabled="!canSearch"
            >
              <span class="i-lucide-search size-4" />
              {{
                isSearching
                  ? t('PROSPECTING.SEARCH.SEARCHING')
                  : t('PROSPECTING.SEARCH.ACTION')
              }}
            </button>
          </div>
        </section>

        <section class="grid gap-5 p-5 xl:grid-cols-[minmax(0,1fr)_20rem]">
          <div class="grid content-start gap-5">
            <div class="grid gap-4">
              <label class="grid gap-1">
                <span class="text-xs font-medium text-n-slate-11">
                  {{ t('PROSPECTING.SEARCH.FIELDS.QUERY') }}
                </span>
                <input
                  v-model="form.query"
                  class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
                  :placeholder="t('PROSPECTING.SEARCH.QUERY_PLACEHOLDER')"
                />
              </label>

              <div class="grid gap-2">
                <label class="grid gap-1">
                  <span class="text-xs font-medium text-n-slate-11">
                    {{ t('PROSPECTING.SEARCH.FIELDS.LOCATION') }}
                  </span>
                  <input
                    v-model="form.location"
                    class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
                    :placeholder="t('PROSPECTING.SEARCH.LOCATION_PLACEHOLDER')"
                    autocomplete="off"
                    @input="handleLocationInput"
                  />
                </label>
                <div class="flex items-center justify-between gap-3">
                  <span class="text-xs text-n-slate-10">
                    {{ autocompleteHint }}
                  </span>
                  <span
                    v-if="confirmedLocation"
                    class="inline-flex items-center gap-1 text-xs font-medium text-n-teal-11"
                  >
                    <span class="i-lucide-check size-3.5" />
                    {{ selectedLocationLabel }}
                  </span>
                </div>
                <div
                  v-if="
                    combinedLocationSuggestions.length && !confirmedLocation
                  "
                  class="overflow-hidden rounded-md border border-n-weak bg-n-solid-1"
                >
                  <button
                    v-for="suggestion in combinedLocationSuggestions"
                    :key="suggestion.place_id || suggestion.text"
                    type="button"
                    class="flex w-full items-center justify-between gap-3 border-b border-n-weak px-3 py-2 text-left text-sm last:border-b-0 hover:bg-n-solid-2"
                    @click="confirmLocationSuggestion(suggestion)"
                  >
                    <span class="min-w-0 truncate text-n-slate-12">
                      {{ suggestion.text }}
                    </span>
                    <span
                      class="i-lucide-map-pin size-4 shrink-0 text-n-slate-10"
                    />
                  </button>
                </div>
              </div>

              <div class="grid gap-4 md:grid-cols-2">
                <label class="grid gap-1">
                  <span class="text-xs font-medium text-n-slate-11">
                    {{ t('PROSPECTING.SEARCH.FIELDS.RADIUS_KM') }}
                  </span>
                  <input
                    v-model="form.radius_km"
                    type="number"
                    min="0.1"
                    step="any"
                    class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
                  />
                </label>
                <label class="grid gap-1">
                  <span class="text-xs font-medium text-n-slate-11">
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
              </div>
            </div>

            <ProspectingGoogleMap
              v-if="confirmedLocation && previewMapCenter"
              :api-key="googleMapsApiKey"
              :center="previewMapCenter"
              :radius="Number(form.radius_km) * 1000"
              height-class="h-80"
            />
          </div>

          <aside
            class="grid content-start gap-3 rounded-md border border-n-weak bg-n-solid-2 p-4"
          >
            <div>
              <h2 class="text-sm font-semibold text-n-slate-12">
                {{ t('PROSPECTING.SEARCH.SECTIONS.RUN') }}
              </h2>
              <p class="mt-1 text-xs text-n-slate-10">
                {{ t('PROSPECTING.SEARCH.SEARCH_SUMMARY_HINT') }}
              </p>
            </div>
            <dl class="grid gap-3 text-sm text-n-slate-11">
              <div class="grid gap-1">
                <dt class="text-xs text-n-slate-10">
                  {{ t('PROSPECTING.SEARCH.FIELDS.QUERY') }}
                </dt>
                <dd class="break-words font-medium text-n-slate-12">
                  {{ form.query || '-' }}
                </dd>
              </div>
              <div class="grid gap-1">
                <dt class="text-xs text-n-slate-10">
                  {{ t('PROSPECTING.SEARCH.FIELDS.LOCATION') }}
                </dt>
                <dd class="break-words font-medium text-n-slate-12">
                  {{ selectedLocationLabel || '-' }}
                </dd>
              </div>
              <div class="grid grid-cols-2 gap-3">
                <div>
                  <dt class="text-xs text-n-slate-10">
                    {{ t('PROSPECTING.SEARCH.FIELDS.RADIUS_KM') }}
                  </dt>
                  <dd class="font-medium text-n-slate-12">
                    {{ form.radius_km }}
                  </dd>
                </div>
                <div>
                  <dt class="text-xs text-n-slate-10">
                    {{ t('PROSPECTING.SEARCH.FIELDS.LIMIT') }}
                  </dt>
                  <dd class="font-medium text-n-slate-12">
                    {{ form.requested_limit }}
                  </dd>
                </div>
              </div>
            </dl>
          </aside>
        </section>
      </form>

      <div
        v-else
        class="grid min-h-0 w-full flex-1 gap-4 xl:grid-cols-[21rem_minmax(0,1fr)]"
      >
        <aside
          class="flex min-h-0 flex-col overflow-hidden rounded-lg border border-n-weak bg-n-solid-1"
        >
          <div class="border-b border-n-weak px-4 py-3">
            <h2 class="text-sm font-semibold text-n-slate-12">
              {{ t('PROSPECTING.SEARCH.RECENT_SEARCHES') }}
            </h2>
          </div>
          <div v-if="isLoading" class="px-4 py-8 text-sm text-n-slate-11">
            {{ t('PROSPECTING.STATES.LOADING') }}
          </div>
          <div
            v-else-if="!searches.length"
            class="px-4 py-8 text-sm text-n-slate-11"
          >
            {{ t('PROSPECTING.SEARCH.EMPTY') }}
          </div>
          <div v-else class="min-h-0 flex-1 overflow-y-auto p-3">
            <article
              v-for="search in searches"
              :key="search.id"
              class="relative mb-3 overflow-hidden rounded-md border border-n-weak bg-n-solid-1 transition last:mb-0 hover:border-n-slate-7 hover:bg-n-solid-2"
              :class="{
                'border-n-brand bg-n-brand-2 shadow-sm ring-1 ring-n-brand/30':
                  selectedSearchId === search.id,
              }"
            >
              <span
                v-if="selectedSearchId === search.id"
                class="absolute inset-y-0 left-0 w-1 bg-n-brand"
              />
              <button
                type="button"
                class="grid w-full gap-2 p-3 pl-4 text-left"
                @click="openSearch(search)"
              >
                <div class="flex items-start justify-between gap-2">
                  <div class="min-w-0">
                    <h3 class="truncate text-sm font-semibold text-n-slate-12">
                      {{ search.query }}
                    </h3>
                    <p class="truncate text-xs text-n-slate-10">
                      {{ search.location }} · {{ formatRadius(search.radius) }}
                    </p>
                  </div>
                  <span
                    class="rounded-md bg-n-solid-3 px-2 py-1 text-xs text-n-slate-11"
                    :class="{
                      'bg-n-brand text-white': selectedSearchId === search.id,
                    }"
                  >
                    {{ search.results_count || 0 }}
                  </span>
                </div>
                <div
                  class="flex items-center justify-between text-xs text-n-slate-10"
                >
                  <span>
                    {{
                      t('PROSPECTING.SEARCH.RECENT_METRICS', {
                        leads: search.results_count || 0,
                        crm: search.crm_count || 0,
                      })
                    }}
                  </span>
                  <span>{{ formatRelativeTime(search.created_at) }}</span>
                </div>
              </button>
              <div
                class="flex items-center gap-1 border-t border-n-weak px-2 py-2"
              >
                <button
                  type="button"
                  class="flex size-8 items-center justify-center rounded-md text-n-slate-11 hover:bg-n-solid-2"
                  :title="t('PROSPECTING.SEARCH.CONFIGURE_SEARCH')"
                  @click.stop="openSearchConfig(search)"
                >
                  <span class="i-lucide-settings size-4" />
                </button>
                <button
                  type="button"
                  class="flex size-8 items-center justify-center rounded-md text-n-slate-11 hover:bg-n-solid-2 disabled:cursor-not-allowed disabled:opacity-60"
                  :title="t('PROSPECTING.SEARCH.DELETE_SEARCH')"
                  :disabled="deletingSearchId === search.id"
                  @click.stop="deleteSearch(search)"
                >
                  <span class="i-lucide-trash-2 size-4" />
                </button>
              </div>
            </article>
          </div>
        </aside>

        <section
          class="flex min-h-0 flex-col overflow-hidden rounded-lg border border-n-weak bg-n-solid-1"
        >
          <div
            class="flex flex-col gap-3 border-b border-n-weak px-4 py-3 lg:flex-row lg:items-end lg:justify-between"
          >
            <div class="min-w-0">
              <h2 class="truncate text-sm font-semibold text-n-slate-12">
                {{
                  selectedSearch
                    ? t('PROSPECTING.SEARCH.RESULTS_FOR', {
                        query: selectedSearch.query,
                      })
                    : t('PROSPECTING.SEARCH.RESULTS_TITLE')
                }}
              </h2>
              <p class="mt-1 truncate text-xs text-n-slate-10">
                {{
                  selectedSearch?.location ||
                  t('PROSPECTING.SEARCH.RESULTS_EMPTY')
                }}
              </p>
            </div>
            <div class="relative flex items-center gap-2">
              <button
                type="button"
                class="relative flex size-9 items-center justify-center rounded-md border border-n-weak text-n-slate-12 hover:bg-n-solid-2"
                :title="t('PROSPECTING.SEARCH.FILTER_BUTTON')"
                @click="showFilters = !showFilters"
              >
                <span class="i-lucide-sliders-horizontal size-4" />
                <span
                  v-if="activeFiltersCount"
                  class="absolute -right-1 -top-1 flex size-4 items-center justify-center rounded-full bg-n-brand text-[10px] font-semibold text-white"
                >
                  {{ activeFiltersCount }}
                </span>
              </button>
              <button
                type="button"
                class="flex size-9 items-center justify-center rounded-md border border-n-weak text-n-slate-12 hover:bg-n-solid-2 disabled:cursor-not-allowed disabled:opacity-60"
                :disabled="!sortedLeads.length"
                :title="t('PROSPECTING.SEARCH.CSV_EXPORT')"
                @click="exportCsv"
              >
                <span class="i-lucide-download size-4" />
              </button>
              <div
                v-if="showFilters"
                class="absolute right-0 top-11 z-30 grid w-[22rem] gap-3 rounded-md border border-n-weak bg-n-solid-1 p-3 shadow-lg"
              >
                <label class="grid gap-1">
                  <span class="text-xs font-medium text-n-slate-11">
                    {{ t('PROSPECTING.SEARCH.FIELDS.SORT') }}
                  </span>
                  <select
                    v-model="sortKey"
                    class="h-9 rounded-md border border-n-weak bg-n-solid-2 px-2 text-sm text-n-slate-12"
                  >
                    <option value="priority_desc">
                      {{ t('PROSPECTING.SEARCH.SORT.PRIORITY_DESC') }}
                    </option>
                    <option value="score_desc">
                      {{ t('PROSPECTING.SEARCH.SORT.SCORE_DESC') }}
                    </option>
                    <option value="created_desc">
                      {{ t('PROSPECTING.SEARCH.SORT.CREATED_DESC') }}
                    </option>
                    <option value="created_asc">
                      {{ t('PROSPECTING.SEARCH.SORT.CREATED_ASC') }}
                    </option>
                    <option value="rating_desc">
                      {{ t('PROSPECTING.SEARCH.SORT.RATING_DESC') }}
                    </option>
                    <option value="reviews_desc">
                      {{ t('PROSPECTING.SEARCH.SORT.REVIEWS_DESC') }}
                    </option>
                    <option value="name_asc">
                      {{ t('PROSPECTING.SEARCH.SORT.NAME_ASC') }}
                    </option>
                  </select>
                </label>
                <div class="grid gap-2 sm:grid-cols-2">
                  <label class="grid gap-1">
                    <span class="text-xs font-medium text-n-slate-11">
                      {{ t('PROSPECTING.SEARCH.FIELDS.HAS_SITE') }}
                    </span>
                    <select
                      v-model="advancedFilters.has_website"
                      class="h-9 rounded-md border border-n-weak bg-n-solid-2 px-2 text-sm text-n-slate-12"
                    >
                      <option value="">
                        {{ t('PROSPECTING.SEARCH.FILTERS.ANY') }}
                      </option>
                      <option value="yes">
                        {{ t('PROSPECTING.SEARCH.FILTERS.YES') }}
                      </option>
                      <option value="no">
                        {{ t('PROSPECTING.SEARCH.FILTERS.NO') }}
                      </option>
                    </select>
                  </label>
                  <label class="grid gap-1">
                    <span class="text-xs font-medium text-n-slate-11">
                      {{ t('PROSPECTING.SEARCH.FIELDS.HAS_PHONE') }}
                    </span>
                    <select
                      v-model="advancedFilters.has_phone"
                      class="h-9 rounded-md border border-n-weak bg-n-solid-2 px-2 text-sm text-n-slate-12"
                    >
                      <option value="">
                        {{ t('PROSPECTING.SEARCH.FILTERS.ANY') }}
                      </option>
                      <option value="yes">
                        {{ t('PROSPECTING.SEARCH.FILTERS.YES') }}
                      </option>
                      <option value="no">
                        {{ t('PROSPECTING.SEARCH.FILTERS.NO') }}
                      </option>
                    </select>
                  </label>
                </div>
                <div class="grid gap-2 sm:grid-cols-2">
                  <label class="grid gap-1">
                    <span class="text-xs font-medium text-n-slate-11">
                      {{ t('PROSPECTING.SEARCH.FIELDS.RATING_MIN') }}
                    </span>
                    <input
                      v-model="advancedFilters.rating_min"
                      type="number"
                      min="0"
                      max="5"
                      step="0.1"
                      class="h-9 rounded-md border border-n-weak bg-n-solid-2 px-2 text-sm text-n-slate-12"
                    />
                  </label>
                  <label class="grid gap-1">
                    <span class="text-xs font-medium text-n-slate-11">
                      {{ t('PROSPECTING.SEARCH.FIELDS.REVIEWS_MIN') }}
                    </span>
                    <input
                      v-model="advancedFilters.reviews_min"
                      type="number"
                      min="0"
                      class="h-9 rounded-md border border-n-weak bg-n-solid-2 px-2 text-sm text-n-slate-12"
                    />
                  </label>
                </div>
              </div>
            </div>
          </div>

          <div class="min-h-0 flex-1 overflow-x-hidden overflow-y-auto">
            <section class="border-b border-n-weak p-4">
              <div class="mb-3 flex items-start justify-between gap-3">
                <div>
                  <h3 class="text-sm font-semibold text-n-slate-12">
                    {{ t('PROSPECTING.SEARCH.MAP_TITLE') }}
                  </h3>
                  <p class="mt-1 text-xs text-n-slate-10">
                    {{ t('PROSPECTING.SEARCH.MAP_HINT') }}
                  </p>
                </div>
                <span class="text-xs text-n-slate-10">
                  {{ formatRadius(selectedSearch?.radius || 0) }}
                </span>
              </div>
              <ProspectingGoogleMap
                v-if="mapLeads.length || resultsMapCenter"
                :api-key="googleMapsApiKey"
                :center="resultsMapCenter"
                :radius="selectedSearch?.radius || 5000"
                :leads="mapLeads"
                height-class="h-80"
                @select-lead="selectedLeadDetailId = $event.id"
              />
              <div
                v-else
                class="flex h-80 items-center justify-center rounded-md border border-n-weak bg-n-solid-2 px-4 text-center text-xs text-n-slate-10"
              >
                {{ t('PROSPECTING.SEARCH.MAP_NO_COORDINATES') }}
              </div>
            </section>
            <div>
              <div
                v-if="isSearching || isLoading"
                class="px-4 py-8 text-sm text-n-slate-11"
              >
                {{ t('PROSPECTING.STATES.LOADING') }}
              </div>
              <div
                v-else-if="!hasResults"
                class="px-4 py-8 text-sm text-n-slate-11"
              >
                {{ t('PROSPECTING.SEARCH.RESULTS_EMPTY') }}
              </div>
              <div
                v-else-if="!sortedLeads.length"
                class="px-4 py-8 text-sm text-n-slate-11"
              >
                {{ t('PROSPECTING.QUALITY.NO_STATUS_RESULTS') }}
              </div>
              <div v-else class="grid min-w-0 gap-3 p-4">
                <div
                  class="flex flex-wrap items-center justify-between gap-2 text-xs"
                >
                  <div class="flex flex-wrap items-center gap-3">
                    <button
                      type="button"
                      class="font-medium text-n-brand hover:underline disabled:cursor-not-allowed disabled:opacity-60"
                      :disabled="!sortedLeads.length"
                      @click="toggleAllVisibleLeads"
                    >
                      {{ t('PROSPECTING.SEARCH.SELECT_VISIBLE') }}
                    </button>
                    <template v-if="hasSelectedLeads">
                      <span class="text-n-slate-10">
                        {{
                          t('PROSPECTING.SEARCH.SELECTED_COUNT', {
                            count: selectedLeadIds.length,
                          })
                        }}
                      </span>
                      <button
                        type="button"
                        class="h-7 rounded-md bg-n-brand px-3 text-xs font-medium text-white disabled:cursor-not-allowed disabled:opacity-60"
                        :disabled="bulkAction === 'contacts'"
                        @click="runBulkAction('contacts')"
                      >
                        {{ t('PROSPECTING.SEARCH.BULK_CONTACTS') }}
                      </button>
                      <button
                        type="button"
                        class="h-7 rounded-md bg-n-brand px-3 text-xs font-medium text-white disabled:cursor-not-allowed disabled:opacity-60"
                        :disabled="
                          bulkAction === 'crm_cards' || !canCreateCrmCard
                        "
                        @click="runBulkAction('crm_cards')"
                      >
                        {{ t('PROSPECTING.SEARCH.BULK_CRM_CARDS') }}
                      </button>
                    </template>
                  </div>
                  <span class="text-n-slate-10">
                    {{
                      t('PROSPECTING.SEARCH.VISIBLE_COUNT', {
                        count: sortedLeads.length,
                      })
                    }}
                  </span>
                </div>
                <article
                  v-for="lead in sortedLeads"
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
                          {{
                            t('PROSPECTING.SEARCH.PRIORITY_FIRST_CALL_SHORT')
                          }}
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
                    <input
                      type="checkbox"
                      class="mt-1 size-4 shrink-0"
                      :checked="
                        selectedLeadIds.map(Number).includes(Number(lead.id))
                      "
                      @change="toggleLeadSelection(lead.id)"
                    />
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
                    <button
                      type="button"
                      class="inline-flex h-8 items-center gap-1 rounded-md border border-n-weak px-3 text-xs font-medium text-n-slate-12 hover:bg-n-solid-2"
                      @click="selectedLeadDetailId = lead.id"
                    >
                      <span class="i-lucide-panel-right-open size-3.5" />
                      {{ t('PROSPECTING.SEARCH.OPEN_DETAILS') }}
                    </button>
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
                  </div>
                </article>
              </div>
            </div>
          </div>
        </section>
      </div>
    </section>

    <div
      v-if="selectedSearchConfig && !showNewSearch"
      class="fixed inset-0 z-40 flex items-center justify-center bg-n-slate-12/30 px-4"
      @click.self="editingSearchConfigId = null"
    >
      <section
        class="grid w-full max-w-md gap-4 rounded-lg border border-n-weak bg-n-solid-1 p-5 shadow-xl"
      >
        <header class="flex items-start justify-between gap-3">
          <div class="min-w-0">
            <h2 class="text-base font-semibold text-n-slate-12">
              {{ t('PROSPECTING.SEARCH.CONFIGURE_SEARCH') }}
            </h2>
            <p class="mt-1 truncate text-sm text-n-slate-10">
              {{ selectedSearchConfig.query }}
            </p>
          </div>
          <button
            type="button"
            class="flex size-8 shrink-0 items-center justify-center rounded-md text-n-slate-11 hover:bg-n-solid-2"
            :title="t('PROSPECTING.SEARCH.CLOSE_DETAILS')"
            @click="editingSearchConfigId = null"
          >
            <span class="i-lucide-x size-4" />
          </button>
        </header>
        <label class="grid gap-1">
          <span class="text-xs font-medium text-n-slate-11">
            {{ t('PROSPECTING.SEARCH.FIELDS.CRM_PIPELINE') }}
          </span>
          <select
            v-model="searchConfigForm.crm_pipeline_id"
            class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
            @change="fetchSearchConfigStages(searchConfigForm.crm_pipeline_id)"
          >
            <option value="">
              {{ t('PROSPECTING.SEARCH.CRM_DISABLED_SHORT') }}
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
            v-model="searchConfigForm.crm_stage_id"
            class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
          >
            <option value="">
              {{ t('PROSPECTING.SEARCH.CRM_STAGE_EMPTY') }}
            </option>
            <option
              v-for="stage in searchConfigStages"
              :key="stage.id"
              :value="stage.id"
            >
              {{ stage.name }}
            </option>
          </select>
        </label>
        <footer class="flex justify-end gap-2">
          <button
            type="button"
            class="h-9 rounded-md px-3 text-sm font-medium text-n-slate-12 hover:bg-n-solid-2"
            @click="editingSearchConfigId = null"
          >
            {{ t('PROSPECTING.LISTS.CANCEL') }}
          </button>
          <button
            type="button"
            class="h-9 rounded-md bg-n-brand px-3 text-sm font-medium text-white"
            @click="saveSearchConfig(selectedSearchConfig)"
          >
            {{ t('PROSPECTING.SEARCH.SAVE_CONFIG') }}
          </button>
        </footer>
      </section>
    </div>

    <div
      v-if="selectedLeadDetail && !showNewSearch"
      class="fixed inset-0 z-40 bg-n-slate-12/30"
      @click.self="selectedLeadDetailId = null"
    >
      <aside
        class="ml-auto flex h-full w-full max-w-xl flex-col overflow-hidden border-l border-n-weak bg-n-solid-1 shadow-xl"
      >
        <header
          class="flex items-start justify-between gap-3 border-b border-n-weak px-5 py-4"
        >
          <div class="min-w-0">
            <div class="mb-2 flex flex-wrap items-center gap-2">
              <span
                v-if="selectedLeadDetail.search_rank"
                class="inline-flex items-center rounded-md bg-n-amber-2 px-1.5 py-0.5 text-[11px] font-bold text-n-amber-11 ring-1 ring-n-amber-5"
              >
                {{
                  t('PROSPECTING.SEARCH.PRIORITY_GOOGLE_RANK', {
                    rank: selectedLeadDetail.search_rank,
                  })
                }}
              </span>
              <span
                v-if="selectedLeadDetail.priority_position"
                class="text-xs text-n-slate-10"
              >
                {{
                  t('PROSPECTING.SEARCH.PRIORITY_POSITION_IN_LIST', {
                    position: selectedLeadDetail.priority_position,
                  })
                }}
              </span>
              <span
                v-if="selectedLeadDetail.priority_position === 1"
                class="inline-flex items-center gap-1 rounded-full bg-n-teal-2 px-2 py-0.5 text-[11px] font-semibold text-n-teal-11 ring-1 ring-n-teal-5"
              >
                <span class="i-lucide-zap size-3" />
                {{ t('PROSPECTING.SEARCH.PRIORITY_FIRST_CALL') }}
              </span>
            </div>
            <h2 class="break-words text-lg font-semibold text-n-slate-12">
              {{ selectedLeadDetail.name }}
            </h2>
            <p class="mt-1 break-words text-sm text-n-slate-10">
              {{ formatLeadAddress(selectedLeadDetail) || '-' }}
            </p>
          </div>
          <button
            type="button"
            class="flex size-8 shrink-0 items-center justify-center rounded-md text-n-slate-11 hover:bg-n-solid-2"
            :title="t('PROSPECTING.SEARCH.CLOSE_DETAILS')"
            @click="selectedLeadDetailId = null"
          >
            <span class="i-lucide-x size-4" />
          </button>
        </header>

        <div class="min-h-0 flex-1 overflow-y-auto px-5 py-4">
          <section class="grid gap-3">
            <div
              class="rounded-xl border border-n-weak px-5 py-4"
              :class="[
                leadPriorityTheme(selectedLeadDetail)?.cardBg || 'bg-n-solid-2',
              ]"
            >
              <div class="flex items-center gap-4">
                <ProspectingPriorityRing
                  :priority="leadPriority(selectedLeadDetail)"
                  :size="92"
                />
                <div class="min-w-0 flex-1">
                  <p
                    class="text-base font-semibold leading-snug"
                    :class="[
                      leadPriorityTheme(selectedLeadDetail)?.titleClass ||
                        'text-n-slate-12',
                    ]"
                  >
                    {{
                      leadPriorityTheme(selectedLeadDetail)?.title ||
                      t('PROSPECTING.SEARCH.FIELDS.PRIORITY')
                    }}
                  </p>
                  <p class="mt-1 text-sm leading-relaxed text-n-slate-11">
                    {{
                      selectedLeadDetail.human_insight ||
                      t('PROSPECTING.SEARCH.SCORE_BASE', {
                        score: selectedLeadDetail.score || '-',
                      })
                    }}
                  </p>
                </div>
              </div>
            </div>

            <div
              v-if="leadSignals(selectedLeadDetail).length"
              class="flex flex-wrap gap-1.5"
            >
              <span
                v-for="signal in leadSignals(selectedLeadDetail)"
                :key="signal.key"
                class="inline-flex items-center gap-1 rounded-full border px-2 py-0.5 text-[11px] font-medium"
                :class="signal.card"
              >
                <span :class="[signal.icon, signal.iconClass]" class="size-3" />
                {{ signal.label }}
              </span>
            </div>

            <div class="grid gap-3 sm:grid-cols-2">
              <div class="rounded-md border border-n-weak bg-n-solid-2 p-3">
                <div class="text-xs font-medium text-n-slate-10">
                  {{ t('PROSPECTING.SEARCH.CONTACT_DATA') }}
                </div>
                <div class="mt-2 text-sm text-n-slate-12">
                  {{ selectedLeadDetail.phone || '-' }}
                </div>
                <a
                  v-if="selectedLeadDetail.website"
                  :href="selectedLeadDetail.website"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="mt-1 block truncate text-sm text-n-brand underline"
                >
                  {{ selectedLeadDetail.website }}
                </a>
              </div>
              <div class="rounded-md border border-n-weak bg-n-solid-2 p-3">
                <div class="text-xs font-medium text-n-slate-10">
                  {{ t('PROSPECTING.SEARCH.REPUTATION') }}
                </div>
                <div class="mt-2 text-sm text-n-slate-12">
                  {{
                    t('PROSPECTING.SEARCH.RATING_LABEL', {
                      rating: selectedLeadDetail.rating || '-',
                    })
                  }}
                </div>
                <div class="text-sm text-n-slate-11">
                  {{
                    t('PROSPECTING.SEARCH.REVIEWS_LABEL', {
                      count: selectedLeadDetail.reviews_count || 0,
                    })
                  }}
                </div>
              </div>
            </div>

            <div class="grid gap-3 sm:grid-cols-2">
              <div class="rounded-md border border-n-weak bg-n-solid-2 p-3">
                <div class="text-xs font-medium text-n-slate-10">
                  {{ t('PROSPECTING.SEARCH.FIELDS.CATEGORY') }}
                </div>
                <div class="mt-2 text-sm text-n-slate-12">
                  {{ selectedLeadDetail.category || '-' }}
                </div>
              </div>
              <div class="rounded-md border border-n-weak bg-n-solid-2 p-3">
                <div class="text-xs font-medium text-n-slate-10">
                  {{ t('PROSPECTING.SEARCH.FIELDS.CRM_STAGE') }}
                </div>
                <div class="mt-2 text-sm text-n-slate-12">
                  {{ selectedStageName }}
                </div>
              </div>
            </div>

            <div class="rounded-md border border-n-weak bg-n-solid-2 p-3">
              <div class="text-xs font-medium text-n-slate-10">
                {{ t('PROSPECTING.SEARCH.COORDINATES') }}
              </div>
              <div class="mt-2 text-sm text-n-slate-12">
                {{
                  selectedLeadDetail.latitude && selectedLeadDetail.longitude
                    ? `${selectedLeadDetail.latitude}, ${selectedLeadDetail.longitude}`
                    : '-'
                }}
              </div>
            </div>

            <div
              v-if="selectedLeadDetail.discard_reason"
              class="rounded-md border border-n-weak bg-n-solid-2 p-3"
            >
              <div class="text-xs font-medium text-n-slate-10">
                {{ t('PROSPECTING.QUALITY.DISCARD_REASON') }}
              </div>
              <div class="mt-2 text-sm text-n-slate-12">
                {{ selectedLeadDetail.discard_reason }}
              </div>
            </div>
          </section>
        </div>

        <footer class="flex flex-wrap gap-2 border-t border-n-weak px-5 py-4">
          <a
            :href="googleMapsLeadUrl(selectedLeadDetail)"
            target="_blank"
            rel="noopener noreferrer"
            class="inline-flex h-9 items-center gap-2 rounded-md border border-n-weak px-3 text-sm font-medium text-n-slate-12 hover:bg-n-solid-2"
          >
            <span class="i-lucide-map-pin size-4" />
            {{ t('PROSPECTING.SEARCH.OPEN_MAP') }}
          </a>
          <a
            v-if="selectedLeadDetail.contact_id"
            :href="contactUrl(selectedLeadDetail.contact_id)"
            class="inline-flex h-9 items-center rounded-md border border-n-weak px-3 text-sm font-medium text-n-brand underline"
          >
            {{ t('PROSPECTING.SEARCH.OPEN_CONTACT') }}
          </a>
          <button
            v-else
            type="button"
            class="h-9 rounded-md bg-n-brand px-3 text-sm font-medium text-white disabled:cursor-not-allowed disabled:opacity-60"
            :disabled="convertingLeadId === selectedLeadDetail.id"
            @click="createContact(selectedLeadDetail)"
          >
            {{ t('PROSPECTING.SEARCH.CREATE_CONTACT') }}
          </button>
          <a
            v-if="selectedLeadDetail.crm_card_id"
            :href="crmCardUrl(selectedLeadDetail.crm_card_id)"
            class="inline-flex h-9 items-center rounded-md border border-n-weak px-3 text-sm font-medium text-n-brand underline"
          >
            {{ t('PROSPECTING.SEARCH.OPEN_CRM_CARD') }}
          </a>
          <button
            v-else
            type="button"
            class="h-9 rounded-md bg-n-brand px-3 text-sm font-medium text-white disabled:cursor-not-allowed disabled:opacity-60"
            :disabled="
              convertingCrmLeadId === selectedLeadDetail.id || !canCreateCrmCard
            "
            @click="createCrmCard(selectedLeadDetail)"
          >
            {{ t('PROSPECTING.SEARCH.CREATE_CRM_CARD') }}
          </button>
        </footer>
      </aside>
    </div>
  </main>
</template>
