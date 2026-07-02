<script setup>
import { onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import AutonomiaProspectingAPI from 'dashboard/api/autonomiaProspecting';

const { t } = useI18n();

const isLoading = ref(true);
const error = ref('');
const searches = ref([]);

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
      <div
        class="grid gap-3 rounded-lg border border-n-weak bg-n-solid-1 p-4 md:grid-cols-[1fr_1fr_10rem]"
      >
        <input
          class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
          :placeholder="t('PROSPECTING.SEARCH.QUERY_PLACEHOLDER')"
          disabled
        />
        <input
          class="h-10 rounded-md border border-n-weak bg-n-solid-2 px-3 text-sm text-n-slate-12"
          :placeholder="t('PROSPECTING.SEARCH.LOCATION_PLACEHOLDER')"
          disabled
        />
        <button
          type="button"
          class="h-10 rounded-md bg-n-brand px-3 text-sm font-medium text-white opacity-60"
          disabled
        >
          {{ t('PROSPECTING.SEARCH.ACTION') }}
        </button>
      </div>

      <div class="overflow-hidden rounded-lg border border-n-weak bg-n-solid-1">
        <div
          class="grid grid-cols-[1fr_10rem_8rem_10rem] border-b border-n-weak px-4 py-3 text-xs font-medium uppercase text-n-slate-10"
        >
          <span>{{ t('PROSPECTING.SEARCH.COLUMNS.QUERY') }}</span>
          <span>{{ t('PROSPECTING.SEARCH.COLUMNS.PROVIDER') }}</span>
          <span>{{ t('PROSPECTING.SEARCH.COLUMNS.STATUS') }}</span>
          <span>{{ t('PROSPECTING.SEARCH.COLUMNS.CREATED_AT') }}</span>
        </div>
        <div v-if="isLoading" class="px-4 py-8 text-sm text-n-slate-11">
          {{ t('PROSPECTING.STATES.LOADING') }}
        </div>
        <div v-else-if="error" class="px-4 py-8 text-sm text-n-ruby-11">
          {{ error }}
        </div>
        <div
          v-else-if="!searches.length"
          class="px-4 py-8 text-sm text-n-slate-11"
        >
          {{ t('PROSPECTING.SEARCH.EMPTY') }}
        </div>
        <template v-else>
          <div
            v-for="search in searches"
            :key="search.id"
            class="grid grid-cols-[1fr_10rem_8rem_10rem] border-b border-n-weak px-4 py-3 text-sm text-n-slate-12 last:border-b-0"
          >
            <span class="truncate">{{ search.query }}</span>
            <span>{{ search.provider }}</span>
            <span>{{ search.status }}</span>
            <span>{{ new Date(search.created_at).toLocaleDateString() }}</span>
          </div>
        </template>
      </div>
    </section>
  </main>
</template>
