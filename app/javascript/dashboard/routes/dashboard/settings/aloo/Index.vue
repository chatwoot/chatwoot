<script setup>
import { useAlert } from 'dashboard/composables';
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useVuelidate } from '@vuelidate/core';
import { required, maxLength } from '@vuelidate/validators';
import { useDebounce } from '@vueuse/core';
import AlooAssistant from 'dashboard/api/aloo/assistant';

import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

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

// --- Create assistant dialog ---
const createDialog = ref(null);
const newName = ref('');
const newDescription = ref('');
const isSubmitting = ref(false);
const isCheckingName = ref(false);
const isNameTaken = ref(false);
const debouncedName = useDebounce(newName, 300);

const checkNameAvailability = async nameToCheck => {
  if (!nameToCheck?.trim()) {
    isNameTaken.value = false;
    return;
  }
  isCheckingName.value = true;
  try {
    const { data } = await AlooAssistant.checkName(nameToCheck.trim());
    isNameTaken.value = !data.available;
  } catch {
    isNameTaken.value = false;
  } finally {
    isCheckingName.value = false;
  }
};

watch(debouncedName, newVal => {
  checkNameAvailability(newVal);
});

const rules = { newName: { required, maxLength: maxLength(100) } };
const v$ = useVuelidate(rules, { newName });

const nameError = computed(() => {
  if (isNameTaken.value) return t('ALOO.FORM.NAME.DUPLICATE_ERROR');
  if (v$.value.newName.$error) return t('ALOO.FORM.NAME.ERROR');
  return '';
});

const isCreateDisabled = computed(
  () =>
    !newName.value?.trim() ||
    isNameTaken.value ||
    isCheckingName.value ||
    v$.value.newName.$error
);

const openNewAssistant = () => {
  newName.value = '';
  newDescription.value = '';
  v$.value.$reset();
  isNameTaken.value = false;
  createDialog.value?.open();
};

const createAssistant = async () => {
  v$.value.newName.$touch();
  if (isCreateDisabled.value) return;

  isSubmitting.value = true;
  try {
    const assistant = await store.dispatch('alooAssistants/create', {
      name: newName.value.trim(),
      description: newDescription.value,
      active: true,
    });
    createDialog.value?.close();
    useAlert(t('ALOO.MESSAGES.CREATED'));
    router.push(
      accountScopedRoute('settings_aloo_edit', {
        assistantId: assistant.id,
      })
    );
  } catch (error) {
    const errorMessage =
      error?.response?.data?.message || t('ALOO.MESSAGES.ERROR');
    useAlert(errorMessage);
  } finally {
    isSubmitting.value = false;
  }
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
  const assistantId = currentAssistant.value.id;
  loading.value[assistantId] = true;
  closeDeletePopup();
  deleteAssistant(assistantId);
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
  return assistant.assigned_inboxes?.length || 0;
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

    <Dialog
      ref="createDialog"
      :title="$t('ALOO.WIZARD.TITLE')"
      :description="$t('ALOO.WIZARD.STEP_1_DESCRIPTION')"
      :confirm-button-label="$t('ALOO.EMPTY_STATE.ACTION')"
      :cancel-button-label="$t('ALOO.ACTIONS.CANCEL')"
      :is-loading="isSubmitting"
      :disable-confirm-button="isCreateDisabled"
      @confirm="createAssistant"
    >
      <div class="flex flex-col gap-4">
        <Input
          v-model="newName"
          :label="$t('ALOO.FORM.NAME.LABEL')"
          :placeholder="$t('ALOO.FORM.NAME.PLACEHOLDER')"
          :message="nameError"
          :message-type="nameError ? 'error' : 'info'"
          @blur="v$.newName.$touch()"
        />
        <TextArea
          v-model="newDescription"
          :label="$t('ALOO.FORM.DESCRIPTION.LABEL')"
          :placeholder="$t('ALOO.FORM.DESCRIPTION.PLACEHOLDER')"
        />
      </div>
    </Dialog>

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
