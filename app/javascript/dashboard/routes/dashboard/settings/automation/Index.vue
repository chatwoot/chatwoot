<script setup>
import { useAlert } from 'dashboard/composables';
import AddAutomationRule from './AddAutomationRule.vue';
import EditAutomationRule from './EditAutomationRule.vue';
import SettingsLayout from '../SettingsLayout.vue';
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import AutomationRuleRow from './AutomationRuleRow.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import CustomBrandPolicyWrapper from 'dashboard/components/CustomBrandPolicyWrapper.vue';
import { getHelpUrlForFeature } from 'dashboard/helper/featureHelper';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();
const confirmDialog = ref(null);
const deleteDialogRef = ref(null);

const loading = ref({});
const showAddPopup = ref(false);
const showEditPopup = ref(false);
const selectedAutomation = ref({});
const toggleModalTitle = ref(t('AUTOMATION.TOGGLE.ACTIVATION_TITLE'));
const toggleModalDescription = ref(
  t('AUTOMATION.TOGGLE.ACTIVATION_DESCRIPTION')
);

const records = computed(() => getters['automations/getAutomations'].value);
const uiFlags = computed(() => getters['automations/getUIFlags'].value);
const accountId = computed(() => getters.getCurrentAccountId.value);
const helpURL = computed(() => getHelpUrlForFeature('automations'));

const deleteDescription = computed(() => {
  const name = selectedAutomation.value?.name || '';
  return `${t('AUTOMATION.DELETE.CONFIRM.MESSAGE')}${name}?`;
});

const isSLAEnabled = computed(() =>
  getters['accounts/isFeatureEnabledonAccount'].value(accountId.value, 'sla')
);

onMounted(() => {
  store.dispatch('inboxes/get');
  store.dispatch('agents/get');
  store.dispatch('contacts/get');
  store.dispatch('teams/get');
  store.dispatch('labels/get');
  store.dispatch('campaigns/get');
  store.dispatch('automations/get');
  if (isSLAEnabled.value) {
    store.dispatch('sla/get');
  }
});

const openAddPopup = () => {
  showAddPopup.value = true;
};
const hideAddPopup = () => {
  showAddPopup.value = false;
};

const openEditPopup = response => {
  selectedAutomation.value = response;
  showEditPopup.value = true;
};
const hideEditPopup = () => {
  showEditPopup.value = false;
};

const openDeletePopup = automation => {
  selectedAutomation.value = automation;
  deleteDialogRef.value?.open();
};

const deleteAutomation = async id => {
  try {
    await store.dispatch('automations/delete', id);
    useAlert(t('AUTOMATION.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('AUTOMATION.DELETE.API.ERROR_MESSAGE'));
  } finally {
    loading.value[id] = false;
  }
};

const confirmDeletion = () => {
  const id = selectedAutomation.value.id;
  loading.value[id] = true;
  deleteDialogRef.value?.close();
  deleteAutomation(id);
};

const cloneAutomation = async automation => {
  const id = automation.id;
  loading.value[id] = true;
  try {
    await store.dispatch('automations/clone', id);
    useAlert(t('AUTOMATION.CLONE.API.SUCCESS_MESSAGE'));
    store.dispatch('automations/get');
  } catch (error) {
    useAlert(t('AUTOMATION.CLONE.API.ERROR_MESSAGE'));
  } finally {
    loading.value[id] = false;
  }
};

const submitAutomation = async (payload, mode) => {
  try {
    const action =
      mode === 'edit' ? 'automations/update' : 'automations/create';
    const successMessage =
      mode === 'edit'
        ? t('AUTOMATION.EDIT.API.SUCCESS_MESSAGE')
        : t('AUTOMATION.ADD.API.SUCCESS_MESSAGE');
    await store.dispatch(action, payload);
    useAlert(successMessage);
    hideAddPopup();
    hideEditPopup();
  } catch (error) {
    const errorMessage =
      mode === 'edit'
        ? t('AUTOMATION.EDIT.API.ERROR_MESSAGE')
        : t('AUTOMATION.ADD.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
};

const toggleAutomation = async ({ id, name, status }) => {
  try {
    if (status) {
      toggleModalTitle.value = t('AUTOMATION.TOGGLE.DEACTIVATION_TITLE');
      toggleModalDescription.value = t(
        'AUTOMATION.TOGGLE.DEACTIVATION_DESCRIPTION',
        {
          automationName: name,
        }
      );
    } else {
      toggleModalTitle.value = t('AUTOMATION.TOGGLE.ACTIVATION_TITLE');
      toggleModalDescription.value = t(
        'AUTOMATION.TOGGLE.ACTIVATION_DESCRIPTION',
        {
          automationName: name,
        }
      );
    }

    const ok = await confirmDialog.value.showConfirmation();
    if (ok) {
      await store.dispatch('automations/update', {
        id: id,
        active: !status,
      });
      const message = status
        ? t('AUTOMATION.TOGGLE.DEACTIVATION_SUCCESFUL')
        : t('AUTOMATION.TOGGLE.ACTIVATION_SUCCESFUL');
      useAlert(message);
    }
  } catch (error) {
    useAlert(t('AUTOMATION.EDIT.API.ERROR_MESSAGE'));
  }
};
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="t('AUTOMATION.LIST.LOADING')"
    :no-records-found="!records.length"
    :no-records-message="t('AUTOMATION.LIST.404')"
  >
    <template #header>
      <div
        class="flex flex-col gap-6 pb-2 sm:flex-row sm:items-end sm:justify-between"
      >
        <div class="min-w-0 space-y-2">
          <p
            class="mb-0 text-[11px] font-bold uppercase tracking-widest text-on-surface-variant/70"
          >
            {{ t('AUTOMATION.PAGE_EYEBROW') }}
          </p>
          <h2 class="mb-0 text-3xl font-bold tracking-tight text-on-surface">
            {{ t('AUTOMATION.HEADER') }}
          </h2>
          <p class="mb-0 max-w-2xl text-base text-on-primary-container">
            {{ t('AUTOMATION.PAGE_SUBTITLE') }}
          </p>
          <CustomBrandPolicyWrapper :show-on-custom-branded-instance="false">
            <a
              v-if="helpURL"
              :href="helpURL"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-1 text-sm font-medium text-secondary hover:underline"
            >
              {{ t('AUTOMATION.LEARN_MORE') }}
              <Icon icon="i-lucide-chevron-right" class="size-4 shrink-0" />
            </a>
          </CustomBrandPolicyWrapper>
        </div>
        <Button
          solid
          teal
          lg
          icon="i-lucide-plus"
          :label="t('AUTOMATION.HEADER_BTN_TXT')"
          class="w-full shrink-0 rounded-xl font-bold shadow-none hover:shadow-[0_0_20px_rgba(4,190,153,0.4)] active:scale-[0.98] sm:w-auto"
          @click="openAddPopup"
        />
      </div>
    </template>
    <template #body>
      <div
        class="overflow-x-auto rounded-2xl border border-outline-variant/10 shadow-xl"
      >
        <div class="min-w-[56rem] bg-surface-container-low">
          <div
            class="grid grid-cols-12 border-b border-surface-container-high/50 bg-surface-container-high/30 px-6 py-4"
          >
            <div
              class="col-span-3 text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
            >
              {{ t('AUTOMATION.LIST.TABLE_HEADER.NAME') }}
            </div>
            <div
              class="col-span-4 text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
            >
              {{ t('AUTOMATION.LIST.TABLE_HEADER.DESCRIPTION') }}
            </div>
            <div
              class="col-span-2 text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
            >
              {{ t('AUTOMATION.LIST.TABLE_HEADER.ACTIVE') }}
            </div>
            <div
              class="col-span-2 text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
            >
              {{ t('AUTOMATION.LIST.TABLE_HEADER.CREATED_ON') }}
            </div>
            <div
              class="col-span-1 text-end text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
            >
              {{ t('AUTOMATION.LIST.TABLE_HEADER.ACTIONS') }}
            </div>
          </div>
          <div class="divide-y divide-surface-container-high/30">
            <AutomationRuleRow
              v-for="automation in records"
              :key="automation.id"
              :automation="automation"
              :loading="loading[automation.id]"
              @clone="cloneAutomation"
              @toggle="toggleAutomation"
              @edit="openEditPopup"
              @delete="openDeletePopup"
            />
          </div>
        </div>
      </div>
      <p class="mt-6 text-xs font-medium text-on-primary-container">
        {{ t('AUTOMATION.LIST.SHOWING_COUNT', { count: records.length }) }}
      </p>
    </template>

    <woot-modal
      v-model:show="showAddPopup"
      size="medium"
      :on-close="hideAddPopup"
    >
      <AddAutomationRule
        v-if="showAddPopup"
        :on-close="hideAddPopup"
        @save-automation="submitAutomation"
      />
    </woot-modal>

    <Dialog
      ref="deleteDialogRef"
      type="alert"
      :title="t('AUTOMATION.DELETE.CONFIRM.TITLE')"
      :description="deleteDescription"
      :confirm-button-label="t('AUTOMATION.DELETE.SUBMIT')"
      :cancel-button-label="t('AUTOMATION.DELETE.CANCEL_BUTTON_TEXT')"
      @confirm="confirmDeletion"
    />

    <woot-modal
      v-model:show="showEditPopup"
      size="medium"
      :on-close="hideEditPopup"
    >
      <EditAutomationRule
        v-if="showEditPopup"
        :on-close="hideEditPopup"
        :selected-response="selectedAutomation"
        @save-automation="submitAutomation"
      />
    </woot-modal>
    <woot-confirm-modal
      ref="confirmDialog"
      :title="toggleModalTitle"
      :description="toggleModalDescription"
    />
  </SettingsLayout>
</template>
