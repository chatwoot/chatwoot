<script setup>
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { useRouter } from 'vue-router';
import { useAdmin } from 'dashboard/composables/useAdmin';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();
const router = useRouter();
const { isAdmin } = useAdmin();

const records = computed(() => getters['workflows/getWorkflows'].value);
const uiFlags = computed(() => getters['workflows/getUIFlags'].value);

onMounted(() => {
  store.dispatch('workflows/get');
});

const openNewWorkflow = () => {
  router.push({ name: 'workflows_new' });
};

const editWorkflow = id => {
  router.push({ name: 'workflows_edit', params: { workflowId: id } });
};

const deleteWorkflow = async id => {
  try {
    await store.dispatch('workflows/delete', id);
    useAlert(t('WORKFLOWS.DELETE.SUCCESS'));
  } catch (error) {
    useAlert(t('WORKFLOWS.DELETE.ERROR'));
  }
};
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('WORKFLOWS.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('WORKFLOWS.HEADER')"
        :description="$t('WORKFLOWS.DESCRIPTION')"
        :link-text="$t('WORKFLOWS.LEARN_MORE')"
        href="https://chatwoot.com"
      >
        <template #actions>
          <Button
            v-if="isAdmin"
            icon="plus"
            :label="$t('WORKFLOWS.CREATE')"
            @click="openNewWorkflow"
          />
        </template>
      </BaseSettingsHeader>
    </template>

    <div class="flex-1 w-full p-4 overflow-auto">
      <div
        v-if="!records.length && !uiFlags.isFetching"
        class="flex items-center justify-center h-full text-slate-500"
      >
        {{ $t('WORKFLOWS.EMPTY') }}
      </div>
      <div v-else class="flex flex-col gap-2">
        <div
          v-for="workflow in records"
          :key="workflow.id"
          class="flex items-center justify-between p-4 bg-white border rounded-lg shadow-sm dark:bg-slate-900 border-slate-200 dark:border-slate-800"
        >
          <div>
            <h3 class="font-medium text-slate-900 dark:text-slate-100">
              {{ workflow.name }}
            </h3>
            <p class="text-sm text-slate-500">
              {{ workflow.description || $t('WORKFLOWS.NO_DESCRIPTION') }}
            </p>
            <span
              class="inline-block mt-1 px-2 py-0.5 text-xs rounded-full bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400"
            >
              {{ $t('WORKFLOWS.TRIGGER_LABEL') }}: {{ workflow.trigger_event }}
            </span>
          </div>
          <div class="flex gap-2">
            <Button
              variant="ghost"
              icon="edit"
              @click="editWorkflow(workflow.id)"
            />
            <Button
              variant="ghost"
              color="red"
              icon="delete"
              @click="deleteWorkflow(workflow.id)"
            />
          </div>
        </div>
      </div>
    </div>
  </SettingsLayout>
</template>
