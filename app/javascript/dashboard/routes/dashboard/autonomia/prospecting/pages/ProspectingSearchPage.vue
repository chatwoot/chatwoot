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
const isSuggestingLocations = ref(false);
const convertingLeadId = ref(null);
const convertingCrmLeadId = ref(null);
const selectedLeadIds = ref([]);
const bulkAction = ref('');
const error = ref('');
const searches = ref([]);
const leads = ref([]);
const settings = ref(null);
const crmPipelines = ref([]);
const crmStages = ref([]);
const searchConfigStages = ref([]);
const locationSuggestions = ref([]);
const locationDetails = ref(null);
const selectedSearchId = ref(null);
const selectedLeadDetailId = ref(null);
const statusFilter = ref('');
const sortKey = ref('created_desc');
const editingSearchConfigId = ref(null);
const showNewSearch = ref(false);
const deletingSearchId = ref(null);
let locationSuggestionTimer;

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

const statusOptions = [
  'new_lead',
  'qualified',
  'discarded',
  'no_consent',
  'ready_for_campaign',
];

const hasResults = computed(() => leads.value.length > 0);
const filteredLeads = computed(() => {
  return leads.value.filter(lead => {
    if (statusFilter.value && lead.status !== statusFilter.value) return false;
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
const selectedLeadDetail = computed(() =>
  leads.value.find(lead => lead.id === selectedLeadDetailId.value)
);
const canCreateCrmCard = computed(() =>
  Boolean(crmForm.value.pipeline_id && crmForm.value.stage_id)
);
const canSearch = computed(
  () =>
    form.value.query.trim().length > 0 &&
    form.value.location.trim().length > 0 &&
    !isSearching.value
);
const hasSelectedLeads = computed(() => selectedLeadIds.value.length > 0);
const selectedPipelineName = computed(() => {
  const pipeline = crmPipelines.value.find(
    item => Number(item.id) === Number(crmForm.value.pipeline_id)
  );
  return pipeline?.name || t('PROSPECTING.SEARCH.CRM_DISABLED_SHORT');
});
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
const selectedMapQuery = computed(() => {
  if (
    selectedSearch.value?.location_latitude &&
    selectedSearch.value?.location_longitude
  ) {
    return `${selectedSearch.value.location_latitude},${selectedSearch.value.location_longitude}`;
  }

  const leadWithCoordinates = leads.value.find(
    lead => lead.latitude && lead.longitude
  );
  if (leadWithCoordinates) {
    return `${leadWithCoordinates.latitude},${leadWithCoordinates.longitude}`;
  }

  if (selectedSearch.value?.location) {
    return `${selectedSearch.value.query || ''} ${selectedSearch.value.location}`;
  }

  return form.value.location || 'Brasil';
});
const searchPreviewQuery = computed(() =>
  [form.value.query, form.value.location].filter(Boolean).join(' ')
);
const recentLocations = computed(() =>
  [
    ...new Set(searches.value.map(search => search.location).filter(Boolean)),
  ].slice(0, 8)
);
const recentLocationSuggestions = computed(() =>
  recentLocations.value.map(location => ({ text: location, place_id: '' }))
);
const combinedLocationSuggestions = computed(() => {
  const items = [
    ...locationSuggestions.value,
    ...recentLocationSuggestions.value,
  ];
  const seen = new Set();
  return items.filter(item => {
    const key = item.place_id || item.text;
    if (!key || seen.has(key)) return false;
    seen.add(key);
    return true;
  });
});
const mapLeads = computed(() =>
  sortedLeads.value.filter(lead => lead.latitude && lead.longitude)
);
const mapBounds = computed(() => {
  if (!mapLeads.value.length) return null;

  const latitudes = mapLeads.value.map(lead => Number(lead.latitude));
  const longitudes = mapLeads.value.map(lead => Number(lead.longitude));
  return {
    minLat: Math.min(...latitudes),
    maxLat: Math.max(...latitudes),
    minLng: Math.min(...longitudes),
    maxLng: Math.max(...longitudes),
  };
});

const mapUrlFor = query =>
  `https://maps.google.com/maps?q=${encodeURIComponent(query || 'Brasil')}&z=12&output=embed`;

const selectedMapUrl = computed(() => mapUrlFor(selectedMapQuery.value));
const previewMapUrl = computed(() =>
  mapUrlFor(searchPreviewQuery.value || form.value.location || 'Brasil')
);

const markerStyle = lead => {
  if (!mapBounds.value) return { left: '50%', top: '50%' };

  const latitudeRange = mapBounds.value.maxLat - mapBounds.value.minLat || 0.01;
  const longitudeRange =
    mapBounds.value.maxLng - mapBounds.value.minLng || 0.01;
  const left =
    ((Number(lead.longitude) - mapBounds.value.minLng) / longitudeRange) * 84 +
    8;
  const top =
    (1 - (Number(lead.latitude) - mapBounds.value.minLat) / latitudeRange) *
      84 +
    8;

  return {
    left: `${Math.max(6, Math.min(94, left))}%`,
    top: `${Math.max(6, Math.min(94, top))}%`,
  };
};

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

const fetchLocationDetails = async suggestion => {
  if (!suggestion?.place_id) {
    locationDetails.value = null;
    return;
  }

  try {
    const { data } = await AutonomiaProspectingAPI.getLocationDetails(
      suggestion.place_id
    );
    locationDetails.value = data.payload || null;
    if (locationDetails.value?.label) {
      form.value.location = locationDetails.value.label;
    }
  } catch {
    locationDetails.value = null;
  }
};

const selectLocationSuggestion = async () => {
  const typedLocation = form.value.location.trim();
  const selectedSuggestion = combinedLocationSuggestions.value.find(
    item => item.text === typedLocation
  );
  await fetchLocationDetails(selectedSuggestion);
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
};

const submitSearch = async () => {
  if (!canSearch.value) return;

  isSearching.value = true;
  error.value = '';
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
          locationDetails.value?.label || form.value.location.trim(),
      },
    });

    const payload = data.payload || {};
    await fetchSearches();
    await selectSearchPayload(payload);
    showNewSearch.value = false;
  } catch (e) {
    error.value =
      e?.response?.data?.error || t('PROSPECTING.ERRORS.CREATE_SEARCH');
  } finally {
    isSearching.value = false;
  }
};

const openSearch = async search => {
  selectedSearchId.value = search.id;
  selectedLeadIds.value = [];
  error.value = '';
  isLoading.value = true;

  try {
    const { data } = await AutonomiaProspectingAPI.getSearch(search.id);
    await selectSearchPayload(data.payload || {});
  } catch {
    error.value = t('PROSPECTING.ERRORS.LOAD_SEARCH');
  } finally {
    isLoading.value = false;
  }
};

const repeatSearch = async search => {
  form.value = {
    query: search.query || '',
    location: search.location || '',
    radius_km: Math.max(Number(search.radius || 5000) / 1000, 0.1),
    requested_limit:
      search.requested_limit || settings.value?.default_limit || 20,
  };
  locationDetails.value = {
    place_id: search.location_place_id,
    latitude: search.location_latitude,
    longitude: search.location_longitude,
    label: search.location_label || search.location,
  };
  await applyCrmTarget(search);
  showNewSearch.value = true;
};

const deleteSearch = async search => {
  if (!search?.id || deletingSearchId.value) return;

  deletingSearchId.value = search.id;
  error.value = '';
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
    error.value =
      e?.response?.data?.error || t('PROSPECTING.ERRORS.DELETE_SEARCH');
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

const replaceLead = updatedLead => {
  if (!updatedLead?.id) return;
  leads.value = leads.value.map(item =>
    item.id === updatedLead.id ? updatedLead : item
  );
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

const runBulkAction = async action => {
  if (!hasSelectedLeads.value || bulkAction.value) return;

  bulkAction.value = action;
  error.value = '';

  try {
    if (action === 'contacts') {
      await selectedLeadObjects.value
        .filter(item => !item.contact_id)
        .reduce(
          (promise, lead) => promise.then(() => createContact(lead)),
          Promise.resolve()
        );
    }

    if (action === 'crm_cards') {
      await selectedLeadObjects.value
        .filter(item => !item.crm_card_id)
        .reduce(
          (promise, lead) => promise.then(() => createCrmCard(lead)),
          Promise.resolve()
        );
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
  editingSearchConfigId.value =
    editingSearchConfigId.value === search.id ? null : search.id;
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
    error.value =
      e?.response?.data?.error || t('PROSPECTING.ERRORS.UPDATE_SEARCH');
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
    error.value = t('PROSPECTING.ERRORS.LOAD_SEARCHES');
  } finally {
    isLoading.value = false;
  }
});
</script>

<template>
  <main class="flex h-full min-h-0 flex-col overflow-hidden bg-n-background">
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
        @click="showNewSearch = !showNewSearch"
      >
        <span class="i-lucide-plus size-4" />
        {{ t('PROSPECTING.SEARCH.NEW_SEARCH') }}
      </button>
    </header>

    <section class="min-h-0 flex-1 overflow-y-auto px-6 py-5">
      <div
        v-if="error"
        class="mb-4 rounded-md bg-n-ruby-3 px-4 py-3 text-sm text-n-ruby-11"
      >
        {{ error }}
      </div>

      <form
        v-if="showNewSearch"
        class="mb-4 grid gap-4 rounded-lg border border-n-weak bg-n-solid-1 p-4 xl:grid-cols-[minmax(20rem,1.1fr)_minmax(18rem,.9fr)_minmax(16rem,.7fr)]"
        @submit.prevent="submitSearch"
      >
        <section class="grid gap-3">
          <div>
            <h2 class="text-sm font-semibold text-n-slate-12">
              {{ t('PROSPECTING.SEARCH.SECTIONS.WHERE') }}
            </h2>
            <p class="mt-1 text-xs text-n-slate-10">
              {{ t('PROSPECTING.SEARCH.LOCATION_HINT') }}
            </p>
          </div>
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
          <label class="grid gap-1">
            <span class="text-xs font-medium text-n-slate-11">
              {{ t('PROSPECTING.SEARCH.FIELDS.LOCATION') }}
            </span>
            <input
              v-model="form.location"
              list="prospecting-location-suggestions"
              class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
              :placeholder="t('PROSPECTING.SEARCH.LOCATION_PLACEHOLDER')"
              @input="fetchLocationSuggestions"
              @change="selectLocationSuggestion"
            />
            <datalist id="prospecting-location-suggestions">
              <option
                v-for="suggestion in combinedLocationSuggestions"
                :key="suggestion.place_id || suggestion.text"
                :value="suggestion.text"
              />
            </datalist>
            <span class="text-xs text-n-slate-10">
              {{
                isSuggestingLocations
                  ? t('PROSPECTING.SEARCH.SUGGESTING_LOCATIONS')
                  : t('PROSPECTING.SEARCH.AUTOCOMPLETE_HINT')
              }}
            </span>
          </label>
          <label class="grid gap-1">
            <span class="text-xs font-medium text-n-slate-11">
              {{ t('PROSPECTING.SEARCH.FIELDS.RADIUS_KM') }}
            </span>
            <input
              v-model="form.radius_km"
              type="number"
              min="0.1"
              step="0.5"
              class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
            />
          </label>
          <div class="h-56 overflow-hidden rounded-md border border-n-weak">
            <iframe
              :src="previewMapUrl"
              class="size-full border-0"
              loading="lazy"
              referrerpolicy="no-referrer-when-downgrade"
              :title="t('PROSPECTING.SEARCH.MAP_PREVIEW')"
            />
          </div>
        </section>

        <section class="grid content-start gap-3">
          <div>
            <h2 class="text-sm font-semibold text-n-slate-12">
              {{ t('PROSPECTING.SEARCH.SECTIONS.DECIDER') }}
            </h2>
          </div>
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
          <label class="grid gap-1">
            <span class="text-xs font-medium text-n-slate-11">
              {{ t('PROSPECTING.SEARCH.FIELDS.CRM_PIPELINE') }}
            </span>
            <select
              v-model="crmForm.pipeline_id"
              class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
              @change="fetchCrmStages(crmForm.pipeline_id)"
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
              v-model="crmForm.stage_id"
              class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
              :disabled="!crmStages.length"
            >
              <option value="">
                {{ t('PROSPECTING.SEARCH.CRM_STAGE_EMPTY') }}
              </option>
              <option
                v-for="stage in crmStages"
                :key="stage.id"
                :value="stage.id"
              >
                {{ stage.name }}
              </option>
            </select>
          </label>
        </section>

        <section class="grid content-start gap-3">
          <div>
            <h2 class="text-sm font-semibold text-n-slate-12">
              {{ t('PROSPECTING.SEARCH.SECTIONS.RUN') }}
            </h2>
          </div>
          <div class="rounded-md border border-n-weak bg-n-solid-2 p-3 text-sm">
            <dl class="grid gap-2 text-n-slate-11">
              <div class="flex justify-between gap-3">
                <dt>{{ t('PROSPECTING.SEARCH.FIELDS.QUERY') }}</dt>
                <dd class="truncate font-medium text-n-slate-12">
                  {{ form.query || '-' }}
                </dd>
              </div>
              <div class="flex justify-between gap-3">
                <dt>{{ t('PROSPECTING.SEARCH.FIELDS.LOCATION') }}</dt>
                <dd class="truncate font-medium text-n-slate-12">
                  {{ form.location || '-' }}
                </dd>
              </div>
              <div class="flex justify-between gap-3">
                <dt>{{ t('PROSPECTING.SEARCH.FIELDS.RADIUS_KM') }}</dt>
                <dd class="font-medium text-n-slate-12">
                  {{ form.radius_km }}
                </dd>
              </div>
              <div class="flex justify-between gap-3">
                <dt>{{ t('PROSPECTING.SEARCH.CRM_TARGET') }}</dt>
                <dd class="truncate font-medium text-n-slate-12">
                  {{ selectedPipelineName }} / {{ selectedStageName }}
                </dd>
              </div>
            </dl>
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
        </section>
      </form>

      <div class="grid min-h-[34rem] gap-4 xl:grid-cols-[21rem_minmax(0,1fr)]">
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
              class="mb-3 rounded-md border border-n-weak bg-n-solid-1 last:mb-0"
              :class="{
                'border-n-brand bg-n-brand-2': selectedSearchId === search.id,
              }"
            >
              <button
                type="button"
                class="grid w-full gap-2 p-3 text-left"
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
                  class="inline-flex h-8 flex-1 items-center justify-center gap-1 rounded-md border border-n-weak px-2 text-xs font-medium text-n-slate-12 hover:bg-n-solid-2"
                  @click="repeatSearch(search)"
                >
                  <span class="i-lucide-rotate-cw size-3.5" />
                  {{ t('PROSPECTING.SEARCH.REPEAT_SEARCH') }}
                </button>
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
              <div
                v-if="editingSearchConfigId === search.id"
                class="grid gap-2 border-t border-n-weak px-3 pb-3 pt-2"
              >
                <select
                  v-model="searchConfigForm.crm_pipeline_id"
                  class="h-9 rounded-md border border-n-weak bg-n-solid-2 px-2 text-sm text-n-slate-12"
                  @change="
                    fetchSearchConfigStages(searchConfigForm.crm_pipeline_id)
                  "
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
                <select
                  v-model="searchConfigForm.crm_stage_id"
                  class="h-9 rounded-md border border-n-weak bg-n-solid-2 px-2 text-sm text-n-slate-12"
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
                <button
                  type="button"
                  class="h-9 rounded-md bg-n-brand px-3 text-sm font-medium text-white"
                  @click="saveSearchConfig(search)"
                >
                  {{ t('PROSPECTING.SEARCH.SAVE_CONFIG') }}
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
            <div class="flex flex-wrap items-end gap-2">
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
                  {{ t('PROSPECTING.SEARCH.FIELDS.SORT') }}
                </span>
                <select
                  v-model="sortKey"
                  class="h-9 rounded-md border border-n-weak bg-n-solid-2 px-2 text-sm text-n-slate-12"
                >
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
                  class="h-9 w-24 rounded-md border border-n-weak bg-n-solid-2 px-2 text-sm text-n-slate-12"
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
                  class="h-9 w-24 rounded-md border border-n-weak bg-n-solid-2 px-2 text-sm text-n-slate-12"
                />
              </label>
              <span
                v-if="activeAdvancedFiltersCount"
                class="mb-1 rounded-md bg-n-solid-3 px-2 py-1 text-xs text-n-slate-11"
              >
                {{
                  t('PROSPECTING.SEARCH.ACTIVE_FILTERS', {
                    count: activeAdvancedFiltersCount,
                  })
                }}
              </span>
              <button
                type="button"
                class="h-9 rounded-md border border-n-weak px-3 text-sm font-medium text-n-slate-12 hover:bg-n-solid-2 disabled:cursor-not-allowed disabled:opacity-60"
                :disabled="!sortedLeads.length"
                @click="toggleAllVisibleLeads"
              >
                {{ t('PROSPECTING.SEARCH.SELECT_VISIBLE') }}
              </button>
              <button
                type="button"
                class="inline-flex h-9 items-center justify-center gap-2 rounded-md border border-n-weak px-3 text-sm font-medium text-n-slate-12 hover:bg-n-solid-2 disabled:cursor-not-allowed disabled:opacity-60"
                :disabled="!sortedLeads.length"
                @click="exportCsv"
              >
                <span class="i-lucide-download size-4" />
                {{ t('PROSPECTING.SEARCH.CSV_EXPORT') }}
              </button>
            </div>
          </div>

          <div
            v-if="hasSelectedLeads"
            class="flex flex-wrap items-center gap-2 border-b border-n-weak bg-n-solid-2 px-4 py-3 text-sm text-n-slate-11"
          >
            <span>
              {{
                t('PROSPECTING.SEARCH.SELECTED_COUNT', {
                  count: selectedLeadIds.length,
                })
              }}
            </span>
            <button
              type="button"
              class="h-8 rounded-md bg-n-brand px-3 text-xs font-medium text-white disabled:cursor-not-allowed disabled:opacity-60"
              :disabled="bulkAction === 'contacts'"
              @click="runBulkAction('contacts')"
            >
              {{ t('PROSPECTING.SEARCH.BULK_CONTACTS') }}
            </button>
            <button
              type="button"
              class="h-8 rounded-md bg-n-brand px-3 text-xs font-medium text-white disabled:cursor-not-allowed disabled:opacity-60"
              :disabled="bulkAction === 'crm_cards' || !canCreateCrmCard"
              @click="runBulkAction('crm_cards')"
            >
              {{ t('PROSPECTING.SEARCH.BULK_CRM_CARDS') }}
            </button>
          </div>

          <div class="grid min-h-0 flex-1 lg:grid-cols-[minmax(0,1fr)_18rem]">
            <div class="min-h-0 overflow-y-auto">
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
              <div v-else class="grid gap-3 p-4">
                <article
                  v-for="lead in sortedLeads"
                  :key="lead.id"
                  class="grid gap-3 rounded-md border border-n-weak bg-n-solid-1 p-4 text-sm"
                >
                  <div class="flex items-start gap-3">
                    <input
                      type="checkbox"
                      class="mt-1 size-4"
                      :checked="
                        selectedLeadIds.map(Number).includes(Number(lead.id))
                      "
                      @change="toggleLeadSelection(lead.id)"
                    />
                    <div class="min-w-0 flex-1">
                      <div
                        class="flex flex-col gap-2 md:flex-row md:items-start md:justify-between"
                      >
                        <div class="min-w-0">
                          <h3
                            class="truncate text-base font-semibold text-n-slate-12"
                          >
                            {{ lead.name }}
                          </h3>
                          <p class="mt-1 text-sm text-n-slate-10">
                            {{ formatLeadAddress(lead) || '-' }}
                          </p>
                        </div>
                        <div class="flex shrink-0 flex-wrap gap-2">
                          <span
                            class="rounded-md bg-n-solid-3 px-2 py-1 text-xs text-n-slate-11"
                          >
                            {{
                              t(`PROSPECTING.QUALITY.STATUSES.${lead.status}`)
                            }}
                          </span>
                          <span
                            class="rounded-md bg-n-solid-3 px-2 py-1 text-xs text-n-slate-11"
                          >
                            {{ lead.source_label || lead.provider }}
                          </span>
                        </div>
                      </div>
                      <div class="mt-3 grid gap-3 md:grid-cols-3">
                        <div class="text-n-slate-11">
                          <div class="text-xs text-n-slate-10">
                            {{ t('PROSPECTING.SEARCH.FIELDS.CATEGORY') }}
                          </div>
                          <div>{{ lead.category || '-' }}</div>
                        </div>
                        <div class="text-n-slate-11">
                          <div class="text-xs text-n-slate-10">
                            {{ t('PROSPECTING.SEARCH.CONTACT_DATA') }}
                          </div>
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
                          <div class="text-xs text-n-slate-10">
                            {{ t('PROSPECTING.SEARCH.REPUTATION') }}
                          </div>
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
                      </div>
                    </div>
                  </div>

                  <div
                    class="flex flex-wrap items-center gap-2 border-t border-n-weak pt-3"
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
                      class="h-8 min-w-[12rem] rounded-md border border-n-weak bg-n-solid-2 px-2 text-xs text-n-slate-12"
                      :placeholder="t('PROSPECTING.QUALITY.DISCARD_REASON')"
                      @blur="updateDiscardReason(lead)"
                    />
                  </div>
                </article>
              </div>
            </div>

            <aside class="hidden border-l border-n-weak lg:block">
              <div class="border-b border-n-weak px-4 py-3">
                <h3 class="text-sm font-semibold text-n-slate-12">
                  {{ t('PROSPECTING.SEARCH.MAP_TITLE') }}
                </h3>
                <p class="mt-1 text-xs text-n-slate-10">
                  {{ t('PROSPECTING.SEARCH.MAP_HINT') }}
                </p>
              </div>
              <div class="grid gap-3 p-3">
                <div
                  class="relative h-72 overflow-hidden rounded-md border border-n-weak bg-n-solid-2"
                >
                  <div class="absolute inset-0 opacity-70">
                    <div
                      class="size-full bg-[linear-gradient(90deg,var(--slate-4)_1px,transparent_1px),linear-gradient(0deg,var(--slate-4)_1px,transparent_1px)] bg-[size:32px_32px]"
                    />
                  </div>
                  <div
                    v-if="!mapLeads.length"
                    class="absolute inset-0 flex items-center justify-center px-4 text-center text-xs text-n-slate-10"
                  >
                    {{ t('PROSPECTING.SEARCH.MAP_NO_COORDINATES') }}
                  </div>
                  <button
                    v-for="lead in mapLeads"
                    :key="`map-${lead.id}`"
                    type="button"
                    class="absolute flex size-7 -translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-full bg-n-brand text-xs font-semibold text-white shadow-md ring-2 ring-white"
                    :style="markerStyle(lead)"
                    :title="lead.name"
                    @click="selectedLeadDetailId = lead.id"
                  >
                    {{ sortedLeads.findIndex(item => item.id === lead.id) + 1 }}
                  </button>
                </div>
                <div
                  class="max-h-40 overflow-y-auto rounded-md border border-n-weak"
                >
                  <button
                    v-for="lead in mapLeads"
                    :key="`map-list-${lead.id}`"
                    type="button"
                    class="grid w-full gap-1 border-b border-n-weak px-3 py-2 text-left text-xs last:border-b-0 hover:bg-n-solid-2"
                    @click="selectedLeadDetailId = lead.id"
                  >
                    <span class="truncate font-medium text-n-slate-12">
                      {{ lead.name }}
                    </span>
                    <span class="truncate text-n-slate-10">
                      {{ formatLeadAddress(lead) || '-' }}
                    </span>
                  </button>
                </div>
                <div
                  class="h-48 overflow-hidden rounded-md border border-n-weak"
                >
                  <iframe
                    :src="selectedMapUrl"
                    class="size-full border-0"
                    loading="lazy"
                    referrerpolicy="no-referrer-when-downgrade"
                    :title="t('PROSPECTING.SEARCH.MAP_TITLE')"
                  />
                </div>
              </div>
            </aside>
          </div>
        </section>
      </div>
    </section>

    <div
      v-if="selectedLeadDetail"
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
                  {{ t('PROSPECTING.QUALITY.SOURCE') }}
                </div>
                <div class="mt-2 text-sm text-n-slate-12">
                  {{
                    selectedLeadDetail.source_label ||
                    selectedLeadDetail.provider
                  }}
                </div>
                <div class="break-all text-xs text-n-slate-10">
                  {{ selectedLeadDetail.provider_place_id || '-' }}
                </div>
              </div>
              <div class="rounded-md border border-n-weak bg-n-solid-2 p-3">
                <div class="text-xs font-medium text-n-slate-10">
                  {{ t('PROSPECTING.SEARCH.FIELDS.CATEGORY') }}
                </div>
                <div class="mt-2 text-sm text-n-slate-12">
                  {{ selectedLeadDetail.category || '-' }}
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

            <label class="grid gap-1">
              <span class="text-xs font-medium text-n-slate-11">
                {{ t('PROSPECTING.QUALITY.STATUS_FILTER') }}
              </span>
              <select
                :value="selectedLeadDetail.status"
                class="h-9 rounded-md border border-n-weak bg-n-solid-2 px-2 text-sm text-n-slate-12"
                @change="
                  updateLeadQuality(selectedLeadDetail, $event.target.value)
                "
              >
                <option
                  v-for="status in statusOptions"
                  :key="status"
                  :value="status"
                >
                  {{ t(`PROSPECTING.QUALITY.STATUSES.${status}`) }}
                </option>
              </select>
            </label>
            <label
              v-if="selectedLeadDetail.status === 'discarded'"
              class="grid gap-1"
            >
              <span class="text-xs font-medium text-n-slate-11">
                {{ t('PROSPECTING.QUALITY.DISCARD_REASON') }}
              </span>
              <input
                v-model="selectedLeadDetail.discard_reason"
                class="h-9 rounded-md border border-n-weak bg-n-solid-2 px-2 text-sm text-n-slate-12"
                @blur="updateDiscardReason(selectedLeadDetail)"
              />
            </label>
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
