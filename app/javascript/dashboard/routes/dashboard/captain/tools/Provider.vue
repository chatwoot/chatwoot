<script setup>
import { computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAdmin } from 'dashboard/composables/useAdmin';

import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ProviderIcon from 'dashboard/components-next/captain/pageComponents/toolCatalog/ProviderIcon.vue';

const route = useRoute();
const router = useRouter();
const store = useStore();
const { isAdmin } = useAdmin();

const providerKey = computed(() => route.params.providerKey);
const provider = useMapGetter('captainToolCatalog/getProvider');
const capacity = useMapGetter('captainToolCatalog/getCapacity');
const uiFlags = useMapGetter('captainToolCatalog/getUIFlags');

const providerDetails = computed(() => provider.value(providerKey.value));
const isFetching = computed(() => uiFlags.value.fetchingProvider);
const backUrl = computed(() => ({
  name: 'captain_tools_index',
  params: route.params,
  query: { view: 'browse' },
}));

const riskLabel = riskClass =>
  riskClass === 'read'
    ? 'CAPTAIN.CUSTOM_TOOLS.CATALOG.READ'
    : 'CAPTAIN.CUSTOM_TOOLS.CATALOG.WRITE';

const availabilityLabel = template => {
  if (template.availability !== 'available') {
    return 'CAPTAIN.CUSTOM_TOOLS.CATALOG.REQUIRES_APPROVAL';
  }
  if (template.update_available) {
    return 'CAPTAIN.CUSTOM_TOOLS.CATALOG.UPDATE_AVAILABLE';
  }
  if (template.installed) return 'CAPTAIN.CUSTOM_TOOLS.CATALOG.INSTALLED';
  return 'CAPTAIN.CUSTOM_TOOLS.CATALOG.AVAILABLE';
};

onMounted(async () => {
  if (!isAdmin.value) {
    await router.replace({ name: 'captain_tools_index', params: route.params });
    return;
  }
  await store.dispatch('captainToolCatalog/show', providerKey.value);
});
</script>

<template>
  <PageLayout
    :header-title="providerDetails?.name || $t('CAPTAIN.CUSTOM_TOOLS.HEADER')"
    :back-url="backUrl"
    :is-fetching="false"
    :is-empty="false"
    :show-pagination-footer="false"
  >
    <template #body>
      <div v-if="isFetching" class="flex justify-center py-12">
        <Spinner />
      </div>
      <div v-else-if="providerDetails" class="flex flex-col gap-6 pb-10">
        <section
          class="flex flex-col gap-5 rounded-xl border border-n-weak bg-n-solid-1 p-5 sm:flex-row sm:items-start"
        >
          <ProviderIcon
            :provider-key="providerDetails.key"
            :provider-name="providerDetails.name"
          />
          <div class="min-w-0 flex-1">
            <div class="flex flex-wrap items-center gap-2">
              <h1 class="text-lg font-medium text-n-slate-12">
                {{ providerDetails.name }}
              </h1>
              <span
                class="rounded-md px-2 py-0.5 text-xs"
                :class="
                  providerDetails.connection.connected
                    ? 'bg-n-teal-3 text-n-teal-11'
                    : 'bg-n-alpha-2 text-n-slate-11'
                "
              >
                {{
                  providerDetails.connection.connected
                    ? $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.CONNECTED')
                    : $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.NOT_CONNECTED')
                }}
              </span>
            </div>
            <p class="mt-1 text-sm leading-5 text-n-slate-11">
              {{ providerDetails.description }}
            </p>
            <p
              v-if="providerDetails.connection.display_name"
              class="mt-2 text-sm text-n-slate-10"
            >
              {{ providerDetails.connection.display_name }}
            </p>
          </div>
          <div class="rounded-lg bg-n-alpha-1 px-4 py-3 text-sm sm:text-right">
            <p class="text-n-slate-10">
              {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.CAPACITY') }}
            </p>
            <p class="font-medium text-n-slate-12">
              {{ capacity.used }} / {{ capacity.limit }}
            </p>
          </div>
        </section>

        <section
          v-for="category in providerDetails.categories"
          :key="category.key"
          class="overflow-hidden rounded-xl border border-n-weak bg-n-solid-1"
        >
          <header class="border-b border-n-weak p-5">
            <h2 class="font-medium text-n-slate-12">{{ category.name }}</h2>
            <p class="mt-1 text-sm text-n-slate-10">
              {{ category.description }}
            </p>
          </header>
          <div class="divide-y divide-n-weak">
            <article
              v-for="template in category.templates"
              :key="template.key"
              class="p-5"
              :class="{ 'opacity-65': template.availability !== 'available' }"
            >
              <div class="flex flex-col gap-3 sm:flex-row sm:items-start">
                <div class="min-w-0 flex-1">
                  <div class="flex flex-wrap items-center gap-2">
                    <h3 class="text-sm font-medium text-n-slate-12">
                      {{ template.name }}
                    </h3>
                    <span
                      class="rounded-md bg-n-alpha-2 px-2 py-0.5 text-xs text-n-slate-11"
                    >
                      {{ $t(riskLabel(template.risk_class)) }}
                    </span>
                    <span
                      class="rounded-md px-2 py-0.5 text-xs"
                      :class="
                        template.installed
                          ? 'bg-n-teal-3 text-n-teal-11'
                          : 'bg-n-alpha-2 text-n-slate-11'
                      "
                    >
                      {{ $t(availabilityLabel(template)) }}
                    </span>
                  </div>
                  <p class="mt-1 text-sm leading-5 text-n-slate-10">
                    {{ template.description }}
                  </p>
                </div>
              </div>
              <details class="mt-3 text-sm text-n-slate-10">
                <summary class="cursor-pointer text-n-slate-11">
                  {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.HOW_THIS_WORKS') }}
                </summary>
                <div
                  class="mt-2 flex flex-col gap-1 rounded-lg bg-n-alpha-1 p-3"
                >
                  <p>
                    {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.REQUIRED_SCOPES') }}:
                    {{
                      template.required_scopes.join(', ') ||
                      $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.NONE')
                    }}
                  </p>
                  <p>
                    {{
                      $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.REVIEWED_OPERATIONS')
                    }}:
                    {{ template.operation_keys.join(', ') }}
                  </p>
                </div>
              </details>
            </article>
          </div>
        </section>
      </div>
    </template>
  </PageLayout>
</template>
