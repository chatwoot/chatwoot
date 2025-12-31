<script setup>
import { useAlert } from 'dashboard/composables';
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';

import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

const getters = useStoreGetters();
const store = useStore();
const router = useRouter();
const { t } = useI18n();
const { accountScopedRoute } = useAccount();

const loading = ref({});
const showDeletePopup = ref(false);
const currentAssistant = ref({});

const assistantList = computed(
  () => getters['alooAssistants/getRecords'].value
);
const uiFlags = computed(() => getters['alooAssistants/getUIFlags'].value);

onMounted(() => {
  store.dispatch('alooAssistants/get');
});

const deleteConfirmText = computed(() => `${t('ALOO.DELETE_CONFIRM.CONFIRM')}`);

const deleteMessage = computed(() => {
  return currentAssistant.value.name;
});

const showAlertMessage = message => {
  loading.value[currentAssistant.value.id] = false;
  currentAssistant.value = {};
  useAlert(message);
};

const openNewAssistant = () => {
  router.push(accountScopedRoute('settings_aloo_new'));
};

const openEditAssistant = assistant => {
  router.push({
    name: 'settings_aloo_edit',
    params: { assistantId: assistant.id },
  });
};

const openDeletePopup = assistant => {
  showDeletePopup.value = true;
  currentAssistant.value = assistant;
};

const closeDeletePopup = () => {
  showDeletePopup.value = false;
  currentAssistant.value = {};
};

const deleteAssistant = async id => {
  try {
    await store.dispatch('alooAssistants/delete', id);
    showAlertMessage(t('ALOO.MESSAGES.DELETED'));
  } catch (error) {
    showAlertMessage(t('ALOO.MESSAGES.ERROR'));
  }
};

const confirmDeletion = () => {
  loading.value[currentAssistant.value.id] = true;
  closeDeletePopup();
  deleteAssistant(currentAssistant.value.id);
};

const toggleActive = async (assistant, active) => {
  try {
    await store.dispatch('alooAssistants/update', {
      id: assistant.id,
      active,
    });
    showAlertMessage(t('ALOO.MESSAGES.UPDATED'));
  } catch (error) {
    showAlertMessage(t('ALOO.MESSAGES.ERROR'));
  }
};

const getInboxCount = assistant => {
  return assistant.aloo_assistant_inboxes?.length || 0;
};
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.fetchingList"
    :loading-message="$t('ALOO.TITLE')"
    :no-records-found="!assistantList.length"
    :no-records-message="$t('ALOO.EMPTY_STATE.DESCRIPTION')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('ALOO.TITLE')"
        :description="$t('ALOO.DESCRIPTION')"
        feature-name="aloo"
      >
        <template #actions>
          <Button
            icon="i-lucide-circle-plus"
            :label="$t('ALOO.NEW_ASSISTANT')"
            @click="openNewAssistant"
          />
        </template>
      </BaseSettingsHeader>
    </template>

    <template #body>
      <table class="w-full divide-y divide-n-weak">
        <thead>
          <tr class="text-left text-n-slate-11">
            <th class="py-3 font-medium">{{ $t('ALOO.FORM.NAME.LABEL') }}</th>
            <th class="py-3 font-medium">
              {{ $t('ALOO.FORM.DESCRIPTION.LABEL') }}
            </th>
            <th class="py-3 font-medium">{{ $t('ALOO.TABS.INBOXES') }}</th>
            <th class="py-3 font-medium">{{ $t('ALOO.FORM.ACTIVE.LABEL') }}</th>
            <th class="py-3 font-medium text-right">
              {{ $t('ALOO.ACTIONS.EDIT') }}
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-n-weak text-n-slate-11">
          <tr v-for="assistant in assistantList" :key="assistant.id">
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              <div class="flex flex-row items-center gap-3">
                <div
                  class="flex items-center justify-center w-10 h-10 rounded-lg bg-n-alpha-2"
                >
                  <span class="i-lucide-sparkles text-n-blue-10 text-xl" />
                </div>
                <span class="font-medium">{{ assistant.name }}</span>
              </div>
            </td>
            <td class="py-4 ltr:pr-4 rtl:pl-4 max-w-xs">
              <span class="line-clamp-2">
                {{ assistant.description || '-' }}
              </span>
            </td>
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              <span
                class="inline-flex items-center px-2 py-1 text-xs font-medium rounded-md bg-n-alpha-2"
              >
                {{ getInboxCount(assistant) }}
                {{ $t('ALOO.TABS.INBOXES').toLowerCase() }}
              </span>
            </td>
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              <Switch
                :model-value="assistant.active"
                @update:model-value="toggleActive(assistant, $event)"
              />
            </td>
            <td class="py-4">
              <div class="flex justify-end gap-1">
                <Button
                  v-tooltip.top="$t('ALOO.ACTIONS.EDIT')"
                  icon="i-lucide-pen"
                  slate
                  xs
                  faded
                  @click="openEditAssistant(assistant)"
                />
                <Button
                  v-tooltip.top="$t('ALOO.ACTIONS.DELETE')"
                  icon="i-lucide-trash-2"
                  xs
                  ruby
                  faded
                  :is-loading="loading[assistant.id]"
                  @click="openDeletePopup(assistant)"
                />
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </template>

    <woot-delete-modal
      v-model:show="showDeletePopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('ALOO.DELETE_CONFIRM.TITLE')"
      :message="$t('ALOO.DELETE_CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="deleteConfirmText"
      :reject-text="$t('ALOO.DELETE_CONFIRM.CANCEL')"
    />
  </SettingsLayout>
</template>
