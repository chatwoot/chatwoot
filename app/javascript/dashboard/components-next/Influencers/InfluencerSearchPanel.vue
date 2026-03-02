<script setup>
import { ref, reactive } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

const store = useStore();
const { t } = useI18n();
const uiFlags = useMapGetter('influencerProfiles/getUIFlags');
const searchError = ref('');

const showAdvanced = ref(false);
const advancedChevron = '▸';

const EU_COUNTRIES = [
  { code: 'DE', name: 'Germany' },
  { code: 'PL', name: 'Poland' },
  { code: 'FR', name: 'France' },
  { code: 'NL', name: 'Netherlands' },
  { code: 'GB', name: 'United Kingdom' },
  { code: 'IT', name: 'Italy' },
  { code: 'ES', name: 'Spain' },
  { code: 'AT', name: 'Austria' },
  { code: 'BE', name: 'Belgium' },
  { code: 'DK', name: 'Denmark' },
  { code: 'SE', name: 'Sweden' },
];

const LANGUAGES = [
  { code: '', label: 'Any' },
  { code: 'en', label: 'English' },
  { code: 'de', label: 'Deutsch' },
  { code: 'pl', label: 'Polski' },
  { code: 'fr', label: 'Français' },
  { code: 'nl', label: 'Nederlands' },
  { code: 'it', label: 'Italiano' },
  { code: 'es', label: 'Español' },
  { code: 'da', label: 'Dansk' },
  { code: 'sv', label: 'Svenska' },
];

const SEARCH_PRESETS = {
  'DE micro home decor': {
    followers: { min: 5000, max: 30000 },
    ai_search: 'home decor interior design wall art',
    location: ['DE'],
    profile_language: 'de',
    engagement_percent_min: 1.5,
    engagement_percent_max: 15,
    hashtags: 'homedecor, interior, einrichtung',
  },
  'PL family photographers': {
    followers: { min: 5000, max: 30000 },
    ai_search: 'wnętrza rodzina zdjęcia dom',
    location: ['PL'],
    profile_language: 'pl',
    engagement_percent_min: 1.5,
    engagement_percent_max: 15,
    hashtags: 'wnetrza, homedecor',
  },
  'FR interior micro': {
    followers: { min: 5000, max: 30000 },
    ai_search: 'decoration interieur maison',
    location: ['FR'],
    profile_language: 'fr',
    engagement_percent_min: 1.5,
    engagement_percent_max: 15,
    hashtags: 'decoration, interieur',
  },
  'NL home lifestyle': {
    followers: { min: 5000, max: 30000 },
    ai_search: 'interieur woonkamer huis',
    location: ['NL'],
    profile_language: 'nl',
    engagement_percent_min: 1.5,
    engagement_percent_max: 15,
    hashtags: 'interieur, wonen',
  },
  'UK home decor': {
    followers: { min: 5000, max: 30000 },
    ai_search: 'homedecor interiordesign',
    location: ['GB'],
    profile_language: 'en',
    engagement_percent_min: 1.5,
    engagement_percent_max: 15,
    hashtags: 'homedecor, interiordesign',
  },
};

const DEFAULT_FILTERS = {
  ai_search: '',
  followers_min: 5000,
  followers_max: 30000,
  location: [],
  engagement_percent_min: '',
  engagement_percent_max: 15,
  gender: '',
  profile_language: '',
  hashtags: '',
  keywords_in_bio: '',
};

const selectedPreset = ref('');
const filters = reactive({ ...DEFAULT_FILTERS });

function applyPreset() {
  if (!selectedPreset.value) return;
  const preset = SEARCH_PRESETS[selectedPreset.value];
  if (!preset) return;

  Object.assign(filters, { ...DEFAULT_FILTERS });
  filters.ai_search = preset.ai_search || '';
  filters.followers_min = preset.followers?.min ?? 5000;
  filters.followers_max = preset.followers?.max ?? 30000;
  filters.location = preset.location ? [...preset.location] : [];
  filters.engagement_percent_min = preset.engagement_percent_min ?? '';
  filters.engagement_percent_max = preset.engagement_percent_max ?? 15;
  filters.gender = preset.gender || '';
  filters.profile_language = preset.profile_language || '';
  filters.hashtags = preset.hashtags || '';
  filters.keywords_in_bio = preset.keywords_in_bio || '';

  if (
    filters.engagement_percent_min ||
    filters.engagement_percent_max ||
    filters.gender ||
    filters.profile_language ||
    filters.hashtags ||
    filters.keywords_in_bio
  ) {
    showAdvanced.value = true;
  }
}

async function handleSearch() {
  const payload = {
    ai_search: filters.ai_search || undefined,
    followers: { min: filters.followers_min, max: filters.followers_max },
    location: filters.location.length
      ? filters.location
          .map(code => EU_COUNTRIES.find(c => c.code === code)?.name)
          .filter(Boolean)
      : undefined,
  };

  if (filters.engagement_percent_min)
    payload.engagement_percent_min = filters.engagement_percent_min;
  if (filters.engagement_percent_max)
    payload.engagement_percent_max = filters.engagement_percent_max;
  if (filters.gender) payload.gender = filters.gender.toLowerCase();
  if (filters.profile_language)
    payload.profile_language = [filters.profile_language];
  if (filters.hashtags)
    payload.hashtags = filters.hashtags
      .split(',')
      .map(h => h.trim())
      .filter(Boolean);
  if (filters.keywords_in_bio)
    payload.keywords_in_bio = filters.keywords_in_bio
      .split(',')
      .map(k => k.trim())
      .filter(Boolean);

  searchError.value = '';
  try {
    await store.dispatch('influencerProfiles/search', {
      filters: payload,
      page: 1,
    });
  } catch (error) {
    const message =
      error?.response?.data?.error || t('INFLUENCER.SEARCH.API_ERROR');
    searchError.value = message;
    useAlert(message);
  }
}

function toggleCountry(code) {
  const idx = filters.location.indexOf(code);
  if (idx >= 0) {
    filters.location.splice(idx, 1);
  } else {
    filters.location.push(code);
  }
}
</script>

<template>
  <div class="border-b border-n-weak p-4">
    <!-- Row 1: Quick filters -->
    <div class="flex flex-wrap items-end gap-4">
      <div class="min-w-[200px]">
        <label class="mb-1 block text-xs font-medium text-n-slate-11">
          {{ t('INFLUENCER.SEARCH.PRESET') }}
        </label>
        <select
          v-model="selectedPreset"
          class="w-full rounded-lg border border-n-weak bg-n-solid-1 px-3 py-1.5 text-sm"
          @change="applyPreset"
        >
          <option value="">
            {{ t('INFLUENCER.SEARCH.SELECT_PRESET') }}
          </option>
          <option v-for="(_, name) in SEARCH_PRESETS" :key="name" :value="name">
            {{ name }}
          </option>
        </select>
      </div>

      <div class="flex-1">
        <label class="mb-1 block text-xs font-medium text-n-slate-11">
          {{ t('INFLUENCER.SEARCH.AI_SEARCH') }}
        </label>
        <input
          v-model="filters.ai_search"
          type="text"
          class="w-full rounded-lg border border-n-weak bg-n-solid-1 px-3 py-1.5 text-sm"
          :placeholder="t('INFLUENCER.SEARCH.AI_SEARCH_PLACEHOLDER')"
        />
      </div>

      <div class="w-28">
        <label class="mb-1 block text-xs font-medium text-n-slate-11">
          {{ t('INFLUENCER.SEARCH.FOLLOWERS_MIN') }}
        </label>
        <input
          v-model.number="filters.followers_min"
          type="number"
          class="w-full rounded-lg border border-n-weak bg-n-solid-1 px-3 py-1.5 text-sm"
        />
      </div>

      <div class="w-28">
        <label class="mb-1 block text-xs font-medium text-n-slate-11">
          {{ t('INFLUENCER.SEARCH.FOLLOWERS_MAX') }}
        </label>
        <input
          v-model.number="filters.followers_max"
          type="number"
          class="w-full rounded-lg border border-n-weak bg-n-solid-1 px-3 py-1.5 text-sm"
        />
      </div>

      <button
        class="rounded-lg bg-n-brand px-4 py-1.5 text-sm font-medium text-white hover:bg-n-brand/90 disabled:opacity-50"
        :disabled="uiFlags.isSearching"
        @click="handleSearch"
      >
        {{
          uiFlags.isSearching
            ? t('INFLUENCER.SEARCH.SEARCHING')
            : t('INFLUENCER.SEARCH.BUTTON')
        }}
      </button>
    </div>

    <div
      v-if="searchError"
      class="mt-2 rounded-lg bg-n-ruby/10 px-3 py-2 text-xs text-red-700"
    >
      {{ searchError }}
    </div>

    <!-- Row 2: Country toggles -->
    <div class="mt-3 flex flex-wrap gap-1.5">
      <button
        v-for="country in EU_COUNTRIES"
        :key="country.code"
        class="rounded-md px-2 py-0.5 text-xs font-medium transition-colors"
        :class="
          filters.location.includes(country.code)
            ? 'bg-n-brand text-white'
            : 'bg-n-background text-n-slate-11 hover:bg-n-weak'
        "
        @click="toggleCountry(country.code)"
      >
        {{ country.code }}
      </button>
    </div>

    <!-- Row 3: Advanced filters toggle -->
    <button
      class="mt-3 flex items-center gap-1 text-xs font-medium text-n-slate-11 hover:text-n-slate-12"
      @click="showAdvanced = !showAdvanced"
    >
      <span
        class="inline-block transition-transform"
        :class="showAdvanced ? 'rotate-90' : ''"
      >
        {{ advancedChevron }}
      </span>
      {{ t('INFLUENCER.SEARCH.ADVANCED_FILTERS') }}
    </button>

    <!-- Row 4: Advanced filters (collapsible) -->
    <div v-if="showAdvanced" class="mt-3 flex flex-wrap items-end gap-4">
      <div class="w-24">
        <label class="mb-1 block text-xs font-medium text-n-slate-11">
          {{ t('INFLUENCER.SEARCH.MIN_ER') }}
        </label>
        <input
          v-model.number="filters.engagement_percent_min"
          type="number"
          step="0.1"
          min="0"
          class="w-full rounded-lg border border-n-weak bg-n-solid-1 px-3 py-1.5 text-sm"
          :placeholder="t('INFLUENCER.SEARCH.MIN_ER_PLACEHOLDER')"
        />
      </div>

      <div class="w-24">
        <label class="mb-1 block text-xs font-medium text-n-slate-11">
          {{ t('INFLUENCER.SEARCH.MAX_ER') }}
        </label>
        <input
          v-model.number="filters.engagement_percent_max"
          type="number"
          step="0.1"
          min="0"
          class="w-full rounded-lg border border-n-weak bg-n-solid-1 px-3 py-1.5 text-sm"
          :placeholder="t('INFLUENCER.SEARCH.MAX_ER_PLACEHOLDER')"
        />
      </div>

      <div class="w-28">
        <label class="mb-1 block text-xs font-medium text-n-slate-11">
          {{ t('INFLUENCER.SEARCH.GENDER') }}
        </label>
        <select
          v-model="filters.gender"
          class="w-full rounded-lg border border-n-weak bg-n-solid-1 px-3 py-1.5 text-sm"
        >
          <option value="">
            {{ t('INFLUENCER.SEARCH.GENDER_ANY') }}
          </option>
          <option value="male">
            {{ t('INFLUENCER.SEARCH.GENDER_MALE') }}
          </option>
          <option value="female">
            {{ t('INFLUENCER.SEARCH.GENDER_FEMALE') }}
          </option>
        </select>
      </div>

      <div class="w-36">
        <label class="mb-1 block text-xs font-medium text-n-slate-11">
          {{ t('INFLUENCER.SEARCH.LANGUAGE') }}
        </label>
        <select
          v-model="filters.profile_language"
          class="w-full rounded-lg border border-n-weak bg-n-solid-1 px-3 py-1.5 text-sm"
        >
          <option v-for="lang in LANGUAGES" :key="lang.code" :value="lang.code">
            {{ lang.label }}
          </option>
        </select>
      </div>

      <div class="flex-1 min-w-[200px]">
        <label class="mb-1 block text-xs font-medium text-n-slate-11">
          {{ t('INFLUENCER.SEARCH.HASHTAGS') }}
        </label>
        <input
          v-model="filters.hashtags"
          type="text"
          class="w-full rounded-lg border border-n-weak bg-n-solid-1 px-3 py-1.5 text-sm"
          :placeholder="t('INFLUENCER.SEARCH.HASHTAGS_PLACEHOLDER')"
        />
      </div>

      <div class="flex-1 min-w-[200px]">
        <label class="mb-1 block text-xs font-medium text-n-slate-11">
          {{ t('INFLUENCER.SEARCH.KEYWORDS_IN_BIO') }}
        </label>
        <input
          v-model="filters.keywords_in_bio"
          type="text"
          class="w-full rounded-lg border border-n-weak bg-n-solid-1 px-3 py-1.5 text-sm"
          :placeholder="t('INFLUENCER.SEARCH.KEYWORDS_IN_BIO_PLACEHOLDER')"
        />
      </div>
    </div>
  </div>
</template>
