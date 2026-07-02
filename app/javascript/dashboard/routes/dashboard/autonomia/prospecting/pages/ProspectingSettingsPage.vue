<script setup>
import { onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import AutonomiaProspectingAPI from 'dashboard/api/autonomiaProspecting';

const { t } = useI18n();

const isLoading = ref(true);
const error = ref('');
const settings = ref(null);

const fetchSettings = async () => {
  isLoading.value = true;
  error.value = '';
  try {
    const { data } = await AutonomiaProspectingAPI.getSettings();
    settings.value = data.payload;
  } catch {
    error.value = t('PROSPECTING.ERRORS.LOAD_SETTINGS');
  } finally {
    isLoading.value = false;
  }
};

onMounted(fetchSettings);
</script>

<template>
  <main class="flex flex-col min-h-full bg-n-background">
    <header class="border-b border-n-weak px-6 py-4">
      <h1 class="text-xl font-semibold text-n-slate-12">
        {{ t('PROSPECTING.SETTINGS.TITLE') }}
      </h1>
    </header>

    <section class="grid gap-3 px-6 py-5 md:max-w-3xl">
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
      <dl
        v-else
        class="grid overflow-hidden rounded-lg border border-n-weak bg-n-solid-1 text-sm"
      >
        <div
          class="grid grid-cols-[12rem_1fr] border-b border-n-weak px-4 py-3 last:border-b-0"
        >
          <dt class="text-n-slate-11">
            {{ t('PROSPECTING.SETTINGS.FIELDS.PROVIDER') }}
          </dt>
          <dd class="text-n-slate-12">{{ settings.provider }}</dd>
        </div>
        <div
          class="grid grid-cols-[12rem_1fr] border-b border-n-weak px-4 py-3 last:border-b-0"
        >
          <dt class="text-n-slate-11">
            {{ t('PROSPECTING.SETTINGS.FIELDS.PROVIDER_ENABLED') }}
          </dt>
          <dd class="text-n-slate-12">
            {{
              settings.provider_enabled
                ? t('PROSPECTING.SETTINGS.ENABLED')
                : t('PROSPECTING.SETTINGS.DISABLED')
            }}
          </dd>
        </div>
        <div
          class="grid grid-cols-[12rem_1fr] border-b border-n-weak px-4 py-3 last:border-b-0"
        >
          <dt class="text-n-slate-11">
            {{ t('PROSPECTING.SETTINGS.FIELDS.DEFAULT_LIMIT') }}
          </dt>
          <dd class="text-n-slate-12">{{ settings.default_limit }}</dd>
        </div>
        <div
          class="grid grid-cols-[12rem_1fr] border-b border-n-weak px-4 py-3 last:border-b-0"
        >
          <dt class="text-n-slate-11">
            {{ t('PROSPECTING.SETTINGS.FIELDS.CACHE_TTL') }}
          </dt>
          <dd class="text-n-slate-12">{{ settings.cache_ttl_seconds }}</dd>
        </div>
      </dl>
    </section>
  </main>
</template>
