<script setup>
import { onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import AutonomiaProspectingAPI from 'dashboard/api/autonomiaProspecting';

const { t } = useI18n();

const isLoading = ref(true);
const error = ref('');
const lists = ref([]);

const fetchLists = async () => {
  isLoading.value = true;
  error.value = '';
  try {
    const { data } = await AutonomiaProspectingAPI.getLists();
    lists.value = data.payload || [];
  } catch {
    error.value = t('PROSPECTING.ERRORS.LOAD_LISTS');
  } finally {
    isLoading.value = false;
  }
};

onMounted(fetchLists);
</script>

<template>
  <main class="flex flex-col min-h-full bg-n-background">
    <header class="border-b border-n-weak px-6 py-4">
      <h1 class="text-xl font-semibold text-n-slate-12">
        {{ t('PROSPECTING.LISTS.TITLE') }}
      </h1>
    </header>

    <section class="px-6 py-5">
      <div class="overflow-hidden rounded-lg border border-n-weak bg-n-solid-1">
        <div
          class="grid grid-cols-[1fr_8rem_10rem] border-b border-n-weak px-4 py-3 text-xs font-medium uppercase text-n-slate-10"
        >
          <span>{{ t('PROSPECTING.LISTS.COLUMNS.NAME') }}</span>
          <span>{{ t('PROSPECTING.LISTS.COLUMNS.STATUS') }}</span>
          <span>{{ t('PROSPECTING.LISTS.COLUMNS.CREATED_AT') }}</span>
        </div>
        <div v-if="isLoading" class="px-4 py-8 text-sm text-n-slate-11">
          {{ t('PROSPECTING.STATES.LOADING') }}
        </div>
        <div v-else-if="error" class="px-4 py-8 text-sm text-n-ruby-11">
          {{ error }}
        </div>
        <div
          v-else-if="!lists.length"
          class="px-4 py-8 text-sm text-n-slate-11"
        >
          {{ t('PROSPECTING.LISTS.EMPTY') }}
        </div>
        <template v-else>
          <div
            v-for="list in lists"
            :key="list.id"
            class="grid grid-cols-[1fr_8rem_10rem] border-b border-n-weak px-4 py-3 text-sm text-n-slate-12 last:border-b-0"
          >
            <span class="truncate">{{ list.name }}</span>
            <span>{{ list.status }}</span>
            <span>{{ new Date(list.created_at).toLocaleDateString() }}</span>
          </div>
        </template>
      </div>
    </section>
  </main>
</template>
