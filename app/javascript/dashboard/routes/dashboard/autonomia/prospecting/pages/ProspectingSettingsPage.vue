<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import AutonomiaProspectingAPI from 'dashboard/api/autonomiaProspecting';
import CrmKanbanAPI from 'dashboard/api/crmKanban';

const { t } = useI18n();

const isLoading = ref(true);
const isSaving = ref(false);
const hasLoadError = ref(false);
const settings = ref(null);
const crmPipelines = ref([]);
const crmStages = ref([]);
const scoringProfiles = ref([]);
const activeSettingsTab = ref('general');
const CUSTOM_SCORING_PROFILE_VALUE = 'custom';
const scoringWeightKeys = [
  'rating',
  'reviews_count',
  'website',
  'phone',
  'google_rank',
  'query_relevance',
];
const form = ref({
  default_limit: 20,
  max_results_per_search: 20,
  daily_limit: '',
  monthly_limit: '',
  cache_ttl_seconds: 86400,
  default_crm_pipeline_id: '',
  default_crm_stage_id: '',
  google_places_api_key: '',
  clear_google_places_api_key: false,
  google_maps_browser_api_key: '',
  clear_google_maps_browser_api_key: false,
  scoring_profile_option: '',
  scoring_profile_id: '',
  custom_scoring_weights: {
    rating: 25,
    reviews_count: 20,
    website: 15,
    phone: 15,
    google_rank: 15,
    query_relevance: 10,
  },
});

const selectedScoringProfile = computed(() =>
  scoringProfiles.value.find(
    profile => Number(profile.id) === Number(form.value.scoring_profile_option)
  )
);

const isCustomScoringProfile = computed(
  () => form.value.scoring_profile_option === CUSTOM_SCORING_PROFILE_VALUE
);

const displayedScoringWeights = computed(() => {
  if (isCustomScoringProfile.value) {
    return form.value.custom_scoring_weights;
  }

  return (
    selectedScoringProfile.value?.weights ||
    settings.value?.active_scoring_weights ||
    form.value.custom_scoring_weights
  );
});

const syncForm = payload => {
  settings.value = payload;
  scoringProfiles.value = payload.scoring_profiles || [];
  const defaultProfile =
    scoringProfiles.value.find(profile => profile.default) ||
    scoringProfiles.value[0];
  form.value = {
    default_limit: payload.default_limit || 20,
    max_results_per_search: payload.max_results_per_search || 20,
    daily_limit: payload.daily_limit || '',
    monthly_limit: payload.monthly_limit || '',
    cache_ttl_seconds: payload.cache_ttl_seconds || 86400,
    default_crm_pipeline_id: payload.default_crm_pipeline_id || '',
    default_crm_stage_id: payload.default_crm_stage_id || '',
    google_places_api_key: '',
    clear_google_places_api_key: false,
    google_maps_browser_api_key: '',
    clear_google_maps_browser_api_key: false,
    scoring_profile_option:
      payload.scoring_mode === 'custom'
        ? CUSTOM_SCORING_PROFILE_VALUE
        : payload.scoring_profile_id || defaultProfile?.id || '',
    scoring_profile_id: payload.scoring_profile_id || defaultProfile?.id || '',
    custom_scoring_weights: {
      ...form.value.custom_scoring_weights,
      ...(payload.custom_scoring_weights ||
        payload.active_scoring_weights ||
        {}),
    },
  };
};

const fetchCrmStages = async pipelineId => {
  crmStages.value = [];
  form.value.default_crm_stage_id = '';
  if (!pipelineId) return;

  const { data } = await CrmKanbanAPI.getStages(pipelineId);
  crmStages.value = data.payload || [];
  form.value.default_crm_stage_id =
    settings.value?.default_crm_stage_id || crmStages.value[0]?.id || '';
};

const fetchCrmPipelines = async () => {
  try {
    const { data } = await CrmKanbanAPI.getPipelines();
    crmPipelines.value = data.payload || [];
  } catch {
    crmPipelines.value = [];
  }
};

const weightPercent = key =>
  Math.max(0, Math.min(100, Number(displayedScoringWeights.value[key] || 0)));

const fetchSettings = async () => {
  isLoading.value = true;
  hasLoadError.value = false;
  try {
    const [{ data }] = await Promise.all([
      AutonomiaProspectingAPI.getSettings(),
      fetchCrmPipelines(),
    ]);
    syncForm(data.payload || {});
    await fetchCrmStages(form.value.default_crm_pipeline_id);
  } catch {
    hasLoadError.value = true;
    useAlert(t('PROSPECTING.ERRORS.LOAD_SETTINGS'));
  } finally {
    isLoading.value = false;
  }
};

const saveSettings = async () => {
  isSaving.value = true;

  try {
    const { data } = await AutonomiaProspectingAPI.updateSettings({
      provider: 'google_places',
      provider_enabled: true,
      default_limit: Number(form.value.default_limit),
      max_results_per_search: Number(form.value.max_results_per_search),
      daily_limit: form.value.daily_limit
        ? Number(form.value.daily_limit)
        : null,
      monthly_limit: form.value.monthly_limit
        ? Number(form.value.monthly_limit)
        : null,
      cache_ttl_seconds: Number(form.value.cache_ttl_seconds),
      default_crm_pipeline_id: form.value.default_crm_pipeline_id || null,
      default_crm_stage_id: form.value.default_crm_stage_id || null,
      scoring_mode: isCustomScoringProfile.value ? 'custom' : 'profile',
      scoring_profile_id: isCustomScoringProfile.value
        ? null
        : form.value.scoring_profile_option || null,
      custom_scoring_weights: scoringWeightKeys.reduce((weights, key) => {
        weights[key] = Number(form.value.custom_scoring_weights[key] || 0);
        return weights;
      }, {}),
      google_places_api_key: form.value.google_places_api_key,
      clear_google_places_api_key: form.value.clear_google_places_api_key,
      google_maps_browser_api_key: form.value.google_maps_browser_api_key,
      clear_google_maps_browser_api_key:
        form.value.clear_google_maps_browser_api_key,
    });
    syncForm(data.payload || {});
    useAlert(t('PROSPECTING.SETTINGS.SAVED'));
  } catch (e) {
    useAlert(e?.response?.data?.error || t('PROSPECTING.ERRORS.SAVE_SETTINGS'));
  } finally {
    isSaving.value = false;
  }
};

const clearGooglePlacesApiKey = () => {
  form.value.google_places_api_key = '';
  form.value.clear_google_places_api_key = true;
};

const clearGoogleMapsBrowserApiKey = () => {
  form.value.google_maps_browser_api_key = '';
  form.value.clear_google_maps_browser_api_key = true;
};

onMounted(fetchSettings);
</script>

<template>
  <main class="flex min-h-full w-full flex-col bg-n-background">
    <header class="border-b border-n-weak px-6 py-4">
      <h1 class="text-xl font-semibold text-n-slate-12">
        {{ t('PROSPECTING.SETTINGS.TITLE') }}
      </h1>
    </header>

    <section class="grid w-full gap-3 px-6 py-5">
      <div
        v-if="isLoading"
        class="rounded-lg border border-n-weak bg-n-solid-1 px-4 py-8 text-sm text-n-slate-11"
      >
        {{ t('PROSPECTING.STATES.LOADING') }}
      </div>
      <div
        v-else-if="hasLoadError"
        class="rounded-lg border border-n-weak bg-n-solid-1 px-4 py-8"
      />
      <form
        v-else
        class="grid gap-4 rounded-lg border border-n-weak bg-n-solid-1 p-4 text-sm"
        @submit.prevent="saveSettings"
      >
        <div class="flex border-b border-n-weak">
          <button
            type="button"
            class="-mb-px px-4 py-2 text-sm font-medium"
            :class="
              activeSettingsTab === 'general'
                ? 'border-b-2 border-n-brand text-n-brand'
                : 'text-n-slate-10 hover:text-n-slate-12'
            "
            @click="activeSettingsTab = 'general'"
          >
            {{ t('PROSPECTING.SETTINGS.TABS.GENERAL') }}
          </button>
          <button
            type="button"
            class="-mb-px px-4 py-2 text-sm font-medium"
            :class="
              activeSettingsTab === 'score'
                ? 'border-b-2 border-n-brand text-n-brand'
                : 'text-n-slate-10 hover:text-n-slate-12'
            "
            @click="activeSettingsTab = 'score'"
          >
            {{ t('PROSPECTING.SETTINGS.TABS.SCORE') }}
          </button>
        </div>

        <div v-show="activeSettingsTab === 'general'" class="grid gap-4">
          <div class="grid gap-3 md:grid-cols-2">
            <label class="grid gap-1">
              <span class="text-xs font-medium text-n-slate-11">
                {{ t('PROSPECTING.SETTINGS.FIELDS.CRM_PIPELINE') }}
              </span>
              <select
                v-model="form.default_crm_pipeline_id"
                class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
                @change="fetchCrmStages(form.default_crm_pipeline_id)"
              >
                <option value="">
                  {{ t('PROSPECTING.SETTINGS.CRM_EMPTY') }}
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
                {{ t('PROSPECTING.SETTINGS.FIELDS.CRM_STAGE') }}
              </span>
              <select
                v-model="form.default_crm_stage_id"
                class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
                :disabled="!crmStages.length"
              >
                <option value="">
                  {{ t('PROSPECTING.SETTINGS.CRM_STAGE_EMPTY') }}
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
          </div>

          <div class="grid gap-3 md:grid-cols-2">
            <div class="grid gap-2 rounded-md border border-n-weak p-3">
              <label class="grid gap-1">
                <span class="text-xs font-medium text-n-slate-11">
                  {{ t('PROSPECTING.SETTINGS.FIELDS.GOOGLE_PLACES_API_KEY') }}
                </span>
                <span class="flex gap-2">
                  <input
                    v-model="form.google_places_api_key"
                    type="password"
                    autocomplete="off"
                    class="h-10 min-w-0 flex-1 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
                    :placeholder="
                      settings.has_google_places_api_key
                        ? t('PROSPECTING.SETTINGS.API_KEY_CONFIGURED')
                        : t('PROSPECTING.SETTINGS.API_KEY_EMPTY')
                    "
                  />
                  <button
                    v-if="settings.has_google_places_api_key"
                    type="button"
                    class="flex size-10 shrink-0 items-center justify-center rounded-md border border-n-weak text-n-slate-11 hover:bg-n-solid-2"
                    :title="
                      t('PROSPECTING.SETTINGS.FIELDS.CLEAR_PLACES_API_KEY')
                    "
                    @click="clearGooglePlacesApiKey"
                  >
                    <span class="i-lucide-eraser size-4" />
                  </button>
                </span>
              </label>

              <p class="text-xs text-n-slate-10">
                {{ t('PROSPECTING.SETTINGS.GOOGLE_PLACES_API_KEY_HINT') }}
              </p>
            </div>

            <div class="grid gap-2 rounded-md border border-n-weak p-3">
              <label class="grid gap-1">
                <span class="text-xs font-medium text-n-slate-11">
                  {{
                    t('PROSPECTING.SETTINGS.FIELDS.GOOGLE_MAPS_BROWSER_API_KEY')
                  }}
                </span>
                <span class="flex gap-2">
                  <input
                    v-model="form.google_maps_browser_api_key"
                    type="password"
                    autocomplete="off"
                    class="h-10 min-w-0 flex-1 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
                    :placeholder="
                      settings.has_google_maps_browser_api_key
                        ? t('PROSPECTING.SETTINGS.API_KEY_CONFIGURED')
                        : t('PROSPECTING.SETTINGS.MAPS_API_KEY_EMPTY')
                    "
                  />
                  <button
                    v-if="settings.has_google_maps_browser_api_key"
                    type="button"
                    class="flex size-10 shrink-0 items-center justify-center rounded-md border border-n-weak text-n-slate-11 hover:bg-n-solid-2"
                    :title="
                      t(
                        'PROSPECTING.SETTINGS.FIELDS.CLEAR_MAPS_BROWSER_API_KEY'
                      )
                    "
                    @click="clearGoogleMapsBrowserApiKey"
                  >
                    <span class="i-lucide-eraser size-4" />
                  </button>
                </span>
              </label>

              <p class="text-xs text-n-slate-10">
                {{ t('PROSPECTING.SETTINGS.GOOGLE_MAPS_BROWSER_API_KEY_HINT') }}
              </p>
            </div>
          </div>

          <div class="grid gap-3 md:grid-cols-5">
            <label class="grid gap-1">
              <span class="text-xs font-medium text-n-slate-11">
                {{ t('PROSPECTING.SETTINGS.FIELDS.DEFAULT_LIMIT') }}
              </span>
              <input
                v-model="form.default_limit"
                type="number"
                min="1"
                class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
              />
            </label>
            <label class="grid gap-1">
              <span class="text-xs font-medium text-n-slate-11">
                {{ t('PROSPECTING.SETTINGS.FIELDS.MAX_RESULTS') }}
              </span>
              <input
                v-model="form.max_results_per_search"
                type="number"
                min="1"
                class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
              />
            </label>
            <label class="grid gap-1">
              <span class="text-xs font-medium text-n-slate-11">
                {{ t('PROSPECTING.SETTINGS.FIELDS.CACHE_TTL') }}
              </span>
              <input
                v-model="form.cache_ttl_seconds"
                type="number"
                min="0"
                class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
              />
            </label>
            <label class="grid gap-1">
              <span class="text-xs font-medium text-n-slate-11">
                {{ t('PROSPECTING.SETTINGS.FIELDS.DAILY_LIMIT') }}
              </span>
              <input
                v-model="form.daily_limit"
                type="number"
                min="1"
                class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
              />
            </label>
            <label class="grid gap-1">
              <span class="text-xs font-medium text-n-slate-11">
                {{ t('PROSPECTING.SETTINGS.FIELDS.MONTHLY_LIMIT') }}
              </span>
              <input
                v-model="form.monthly_limit"
                type="number"
                min="1"
                class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
              />
            </label>
          </div>

          <div
            class="grid gap-3 rounded-md border border-n-weak bg-n-solid-2 p-3 md:grid-cols-2"
          >
            <div>
              <span class="text-xs font-medium text-n-slate-11">
                {{ t('PROSPECTING.SETTINGS.USAGE_DAILY') }}
              </span>
              <p class="text-sm text-n-slate-12">
                {{ settings.usage?.daily_used || 0 }} /
                {{ form.daily_limit || t('PROSPECTING.SETTINGS.UNLIMITED') }}
              </p>
            </div>
            <div>
              <span class="text-xs font-medium text-n-slate-11">
                {{ t('PROSPECTING.SETTINGS.USAGE_MONTHLY') }}
              </span>
              <p class="text-sm text-n-slate-12">
                {{ settings.usage?.monthly_used || 0 }} /
                {{ form.monthly_limit || t('PROSPECTING.SETTINGS.UNLIMITED') }}
              </p>
            </div>
          </div>
        </div>

        <div v-show="activeSettingsTab === 'score'" class="grid gap-5">
          <div
            class="rounded-lg border border-n-weak bg-n-solid-2 p-4 shadow-sm"
          >
            <div
              class="flex flex-col gap-3 md:flex-row md:items-start md:justify-between"
            >
              <div class="grid gap-1">
                <h2 class="text-base font-semibold text-n-slate-12">
                  {{ t('PROSPECTING.SETTINGS.SCORING_TITLE') }}
                </h2>
                <p class="max-w-2xl text-sm text-n-slate-10">
                  {{ t('PROSPECTING.SETTINGS.SCORING_HINT') }}
                </p>
              </div>
              <span
                class="inline-flex w-fit items-center rounded-full border px-2.5 py-1 text-xs font-semibold"
                :class="
                  isCustomScoringProfile
                    ? 'border-amber-200 bg-amber-50 text-amber-800'
                    : 'border-emerald-200 bg-emerald-50 text-emerald-800'
                "
              >
                {{
                  isCustomScoringProfile
                    ? t('PROSPECTING.SETTINGS.SCORING_PROFILE_CUSTOM')
                    : t('PROSPECTING.SETTINGS.SCORING_PROFILE_GLOBAL')
                }}
              </span>
            </div>

            <label class="mt-4 grid gap-1">
              <span class="text-xs font-medium text-n-slate-11">
                {{ t('PROSPECTING.SETTINGS.FIELDS.SCORING_PROFILE') }}
              </span>
              <select
                v-model="form.scoring_profile_option"
                class="h-10 rounded-md border border-n-weak bg-n-solid-1 px-3 text-sm text-n-slate-12"
              >
                <option
                  v-for="profile in scoringProfiles"
                  :key="profile.id"
                  :value="profile.id"
                >
                  {{ profile.name }}
                </option>
                <option :value="CUSTOM_SCORING_PROFILE_VALUE">
                  {{ t('PROSPECTING.SETTINGS.SCORING_PROFILE_CUSTOM') }}
                </option>
              </select>
            </label>
          </div>

          <div
            class="overflow-hidden rounded-lg border border-n-weak bg-n-solid-1 shadow-sm"
          >
            <div class="border-b border-n-weak px-4 py-3">
              <h3 class="text-sm font-semibold text-n-slate-12">
                {{ t('PROSPECTING.SETTINGS.SCORING_WEIGHTS_TITLE') }}
              </h3>
              <p class="text-xs text-n-slate-10">
                {{
                  isCustomScoringProfile
                    ? t('PROSPECTING.SETTINGS.SCORING_CUSTOM_HINT')
                    : t('PROSPECTING.SETTINGS.SCORING_PROFILE_HINT')
                }}
              </p>
            </div>

            <div
              v-for="key in scoringWeightKeys"
              :key="key"
              class="grid items-center gap-3 px-4 py-3 md:grid-cols-[160px_1fr_90px]"
              :class="{
                'border-b border-n-weak':
                  key !== scoringWeightKeys[scoringWeightKeys.length - 1],
              }"
            >
              <label class="text-sm font-medium text-n-slate-11">
                {{ t(`PROSPECTING.SETTINGS.SCORING_WEIGHTS.${key}`) }}
              </label>
              <div class="h-2 overflow-hidden rounded-full bg-n-solid-3">
                <div
                  class="h-full rounded-full bg-gradient-to-r from-blue-500 to-emerald-500"
                  :style="{ width: `${weightPercent(key)}%` }"
                />
              </div>
              <input
                v-if="isCustomScoringProfile"
                v-model="form.custom_scoring_weights[key]"
                type="number"
                min="0"
                max="100"
                class="h-9 rounded-md border border-n-weak bg-n-solid-2 px-2 text-center text-sm text-n-slate-12"
              />
              <div
                v-else
                class="flex h-9 items-center justify-center rounded-md border border-n-weak bg-n-solid-2 text-sm font-semibold text-n-slate-12"
              >
                {{ displayedScoringWeights[key] || 0 }}
              </div>
            </div>
          </div>
        </div>

        <button
          type="submit"
          class="h-10 w-fit rounded-md bg-n-brand px-4 text-sm font-medium text-white disabled:cursor-not-allowed disabled:opacity-60"
          :disabled="isSaving"
        >
          {{
            isSaving
              ? t('PROSPECTING.SETTINGS.SAVING')
              : t('PROSPECTING.SETTINGS.SAVE')
          }}
        </button>
      </form>
    </section>
  </main>
</template>
