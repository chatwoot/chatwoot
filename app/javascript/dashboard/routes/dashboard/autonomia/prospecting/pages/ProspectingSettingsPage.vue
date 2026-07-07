<script setup>
import { onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import AutonomiaProspectingAPI from 'dashboard/api/autonomiaProspecting';
import CrmKanbanAPI from 'dashboard/api/crmKanban';

const { t } = useI18n();

const isLoading = ref(true);
const isSaving = ref(false);
const error = ref('');
const notice = ref('');
const settings = ref(null);
const crmPipelines = ref([]);
const crmStages = ref([]);
const form = ref({
  provider: 'mock',
  provider_enabled: false,
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
});

const syncForm = payload => {
  settings.value = payload;
  form.value = {
    provider: payload.provider || 'mock',
    provider_enabled: Boolean(payload.provider_enabled),
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

const fetchSettings = async () => {
  isLoading.value = true;
  error.value = '';
  try {
    const [{ data }] = await Promise.all([
      AutonomiaProspectingAPI.getSettings(),
      fetchCrmPipelines(),
    ]);
    syncForm(data.payload || {});
    await fetchCrmStages(form.value.default_crm_pipeline_id);
  } catch {
    error.value = t('PROSPECTING.ERRORS.LOAD_SETTINGS');
  } finally {
    isLoading.value = false;
  }
};

const saveSettings = async () => {
  isSaving.value = true;
  error.value = '';
  notice.value = '';

  try {
    const { data } = await AutonomiaProspectingAPI.updateSettings({
      provider: form.value.provider,
      provider_enabled: form.value.provider_enabled,
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
      google_places_api_key: form.value.google_places_api_key,
      clear_google_places_api_key: form.value.clear_google_places_api_key,
      google_maps_browser_api_key: form.value.google_maps_browser_api_key,
      clear_google_maps_browser_api_key:
        form.value.clear_google_maps_browser_api_key,
    });
    syncForm(data.payload || {});
    notice.value = t('PROSPECTING.SETTINGS.SAVED');
  } catch (e) {
    error.value =
      e?.response?.data?.error || t('PROSPECTING.ERRORS.SAVE_SETTINGS');
  } finally {
    isSaving.value = false;
  }
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
        v-else-if="error"
        class="rounded-lg border border-n-weak bg-n-solid-1 px-4 py-8 text-sm text-n-ruby-11"
      >
        {{ error }}
      </div>
      <form
        v-else
        class="grid gap-4 rounded-lg border border-n-weak bg-n-solid-1 p-4 text-sm"
        @submit.prevent="saveSettings"
      >
        <div
          v-if="notice"
          class="rounded-md bg-n-teal-3 px-3 py-2 text-n-teal-11"
        >
          {{ notice }}
        </div>

        <label class="grid gap-1">
          <span class="text-xs font-medium text-n-slate-11">
            {{ t('PROSPECTING.SETTINGS.FIELDS.PROVIDER') }}
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

        <label class="flex items-center gap-2 text-n-slate-12">
          <input v-model="form.provider_enabled" type="checkbox" />
          <span>
            {{ t('PROSPECTING.SETTINGS.FIELDS.PROVIDER_ENABLED') }}
          </span>
        </label>

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
              <input
                v-model="form.google_places_api_key"
                type="password"
                autocomplete="off"
                class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
                :placeholder="
                  settings.has_google_places_api_key
                    ? t('PROSPECTING.SETTINGS.API_KEY_CONFIGURED')
                    : t('PROSPECTING.SETTINGS.API_KEY_EMPTY')
                "
              />
            </label>

            <p class="text-xs text-n-slate-10">
              {{ t('PROSPECTING.SETTINGS.GOOGLE_PLACES_API_KEY_HINT') }}
            </p>

            <label
              v-if="settings.has_google_places_api_key"
              class="flex items-center gap-2 text-n-slate-12"
            >
              <input
                v-model="form.clear_google_places_api_key"
                type="checkbox"
              />
              <span>
                {{ t('PROSPECTING.SETTINGS.FIELDS.CLEAR_PLACES_API_KEY') }}
              </span>
            </label>
          </div>

          <div class="grid gap-2 rounded-md border border-n-weak p-3">
            <label class="grid gap-1">
              <span class="text-xs font-medium text-n-slate-11">
                {{
                  t('PROSPECTING.SETTINGS.FIELDS.GOOGLE_MAPS_BROWSER_API_KEY')
                }}
              </span>
              <input
                v-model="form.google_maps_browser_api_key"
                type="password"
                autocomplete="off"
                class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
                :placeholder="
                  settings.has_google_maps_browser_api_key
                    ? t('PROSPECTING.SETTINGS.API_KEY_CONFIGURED')
                    : t('PROSPECTING.SETTINGS.MAPS_API_KEY_EMPTY')
                "
              />
            </label>

            <p class="text-xs text-n-slate-10">
              {{ t('PROSPECTING.SETTINGS.GOOGLE_MAPS_BROWSER_API_KEY_HINT') }}
            </p>

            <label
              v-if="settings.has_google_maps_browser_api_key"
              class="flex items-center gap-2 text-n-slate-12"
            >
              <input
                v-model="form.clear_google_maps_browser_api_key"
                type="checkbox"
              />
              <span>
                {{
                  t('PROSPECTING.SETTINGS.FIELDS.CLEAR_MAPS_BROWSER_API_KEY')
                }}
              </span>
            </label>
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
