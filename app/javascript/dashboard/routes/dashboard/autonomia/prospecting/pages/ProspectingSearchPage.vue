<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import AutonomiaProspectingAPI from 'dashboard/api/autonomiaProspecting';

const { t } = useI18n();

const isLoading = ref(true);
const isSearching = ref(false);
const error = ref('');
const searches = ref([]);
const leads = ref([]);
const selectedSearchId = ref(null);
const form = ref({
  query: '',
  location: '',
  radius: 5000,
  requested_limit: 20,
});

const hasResults = computed(() => leads.value.length > 0);
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
      provider: 'mock',
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

onMounted(fetchSearches);
</script>

<template>
  <main class="flex flex-col min-h-full bg-n-background">
    <header class="border-b border-n-weak px-6 py-4">
      <h1 class="text-xl font-semibold text-n-slate-12">
        {{ t('PROSPECTING.SEARCH.TITLE') }}
      </h1>
    </header>

    <section class="grid gap-4 px-6 py-5">
      <form
        class="grid gap-3 rounded-lg border border-n-weak bg-n-solid-1 p-4 md:grid-cols-[1fr_1fr_8rem_8rem_10rem]"
        @submit.prevent="submitSearch"
      >
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
            class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
            :placeholder="t('PROSPECTING.SEARCH.LOCATION_PLACEHOLDER')"
          />
        </label>
        <label class="grid gap-1">
          <span class="text-xs font-medium text-n-slate-11">
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
        <button
          type="submit"
          class="mt-5 h-10 rounded-md bg-n-brand px-3 text-sm font-medium text-white disabled:cursor-not-allowed disabled:opacity-60"
          :disabled="!canSearch"
        >
          {{
            isSearching
              ? t('PROSPECTING.SEARCH.SEARCHING')
              : t('PROSPECTING.SEARCH.ACTION')
          }}
        </button>
      </form>

      <div
        v-if="error"
        class="rounded-md bg-n-ruby-3 px-4 py-3 text-sm text-n-ruby-11"
      >
        {{ error }}
      </div>

      <div class="overflow-hidden rounded-lg border border-n-weak bg-n-solid-1">
        <div class="border-b border-n-weak px-4 py-3">
          <h2 class="text-sm font-semibold text-n-slate-12">
            {{ t('PROSPECTING.SEARCH.RESULTS_TITLE') }}
          </h2>
        </div>
        <div v-if="isSearching" class="px-4 py-8 text-sm text-n-slate-11">
          {{ t('PROSPECTING.STATES.LOADING') }}
        </div>
        <div v-else-if="!hasResults" class="px-4 py-8 text-sm text-n-slate-11">
          {{ resultsEmptyText }}
        </div>
        <div v-else class="divide-y divide-n-weak">
          <article
            v-for="lead in leads"
            :key="lead.id"
            class="grid gap-2 px-4 py-4 text-sm md:grid-cols-[1.5fr_1fr_1fr_8rem]"
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
          </article>
        </div>
      </div>

      <div class="overflow-hidden rounded-lg border border-n-weak bg-n-solid-1">
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
    </section>
  </main>
</template>
