<script setup>
import { useAlert } from 'dashboard/composables';
import { computed, onBeforeMount, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';

import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const store = useStore();
const { t } = useI18n();

const loading = ref({});
const templates = ref([]);
const isFetching = ref(false);

const fetchTemplates = async () => {
  isFetching.value = true;
  try {
    const response = await store.dispatch('emailTemplates/get');
    templates.value = response.data || [];
  } catch (error) {
    useAlert(t('EMAIL_TEMPLATES.FETCH_ERROR'));
  } finally {
    isFetching.value = false;
  }
};

const activateTemplate = async id => {
  loading.value = { ...loading.value, [id]: true };
  try {
    await store.dispatch('emailTemplates/activate', id);
    useAlert(t('EMAIL_TEMPLATES.ACTIVATE_SUCCESS'));
    await fetchTemplates();
  } catch (error) {
    useAlert(t('EMAIL_TEMPLATES.ACTIVATE_ERROR'));
  } finally {
    loading.value = { ...loading.value, [id]: false };
  }
};

const deactivateTemplate = async id => {
  loading.value = { ...loading.value, [id]: true };
  try {
    await store.dispatch('emailTemplates/deactivate', id);
    useAlert(t('EMAIL_TEMPLATES.DEACTIVATE_SUCCESS'));
    await fetchTemplates();
  } catch (error) {
    useAlert(t('EMAIL_TEMPLATES.DEACTIVATE_ERROR'));
  } finally {
    loading.value = { ...loading.value, [id]: false };
  }
};

const groupedTemplates = computed(() => {
  return templates.value.reduce((acc, template) => {
    const group = template.template.name;
    if (!acc[group]) {
      acc[group] = [];
    }
    acc[group].push(template);
    return acc;
  }, {});
});

onBeforeMount(() => {
  fetchTemplates();
});
</script>

<template>
  <SettingsLayout
    :is-loading="isFetching"
    :loading-message="$t('EMAIL_TEMPLATES.LOADING')"
    :no-records-found="!templates.length"
    :no-records-message="$t('EMAIL_TEMPLATES.NO_TEMPLATES')"
  >
    <template #body>
      <div
        v-for="(group, friendlyName) in groupedTemplates"
        :key="friendlyName"
        class="mb-8"
      >
        <h3 class="text-lg font-semibold text-n-slate-12 mb-4">
          {{ friendlyName }}
        </h3>
        <table class="min-w-full overflow-x-auto divide-y divide-n-weak">
          <thead>
            <tr>
              <th
                scope="col"
                class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-n-slate-12 sm:pl-6"
              >
                {{ $t('EMAIL_TEMPLATES.TABLE_HEADER.FRIENDLY_NAME') }}
              </th>
              <th
                scope="col"
                class="px-3 py-3.5 text-left text-sm font-semibold text-n-slate-12"
              >
                {{ $t('EMAIL_TEMPLATES.TABLE_HEADER.DESCRIPTION') }}
              </th>
              <th
                scope="col"
                class="px-3 py-3.5 text-left text-sm font-semibold text-n-slate-12"
              >
                {{ $t('EMAIL_TEMPLATES.TABLE_HEADER.TYPE') }}
              </th>
              <th
                scope="col"
                class="relative py-3.5 pl-3 pr-4 sm:pr-6 text-right text-sm font-semibold text-n-slate-12"
              >
                {{ $t('EMAIL_TEMPLATES.TABLE_HEADER.STATUS') }}
              </th>
            </tr>
          </thead>
          <tbody class="flex-1 divide-y divide-n-weak text-n-slate-12">
            <tr v-for="assignment in group" :key="assignment.id">
              <td class="py-4 pl-4 pr-3 text-sm sm:pl-6">
                <span class="mb-1 font-medium break-words text-n-slate-12">
                  {{ assignment.template.friendly_name }}
                </span>
              </td>
              <td class="px-3 py-4 text-sm text-n-slate-11">
                {{ assignment.template.description }}
              </td>
              <td class="px-3 py-4 text-sm text-n-slate-11">
                {{ assignment.template.template_type }}
              </td>
              <td class="relative py-4 pl-3 pr-4 text-right text-sm sm:pr-6">
                <div
                  v-if="assignment.active"
                  class="flex items-center justify-end gap-2"
                >
                  <span
                    class="inline-flex items-center px-2 py-1 text-xs font-medium rounded-md bg-n-teal-1 text-n-teal-11 ring-1 ring-inset ring-n-teal-6"
                  >
                    {{ $t('EMAIL_TEMPLATES.ACTIVE') }}
                  </span>
                  <Button
                    :label="$t('EMAIL_TEMPLATES.DEACTIVATE')"
                    xs
                    variant="outline"
                    color="slate"
                    :is-loading="loading[assignment.id]"
                    @click="deactivateTemplate(assignment.id)"
                  />
                </div>
                <Button
                  v-else
                  :label="$t('EMAIL_TEMPLATES.ACTIVATE')"
                  xs
                  :is-loading="loading[assignment.id]"
                  @click="activateTemplate(assignment.id)"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </template>
  </SettingsLayout>
</template>
