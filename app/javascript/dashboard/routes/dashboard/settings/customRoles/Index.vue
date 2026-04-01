<script setup>
import { useAlert } from 'dashboard/composables';
import SettingsLayout from '../SettingsLayout.vue';
import CustomRoleModal from './component/CustomRoleModal.vue';
import CustomRoleTableBody from './component/CustomRoleTableBody.vue';
import CustomRolePaywall from './component/CustomRolePaywall.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import ConfirmDialog from 'dashboard/components-next/dialog/Dialog.vue';
import CustomBrandPolicyWrapper from 'dashboard/components/CustomBrandPolicyWrapper.vue';
import { getHelpUrlForFeature } from 'dashboard/helper/featureHelper';
import { computed, nextTick, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';

const store = useStore();
const { t } = useI18n();

const showCustomRoleModal = ref(false);
const customRoleModalMode = ref('add');
const selectedRole = ref(null);
const loading = ref({});
const deleteDialogRef = ref(null);
const activeResponse = ref({});

const records = useMapGetter('customRole/getCustomRoles');
const uiFlags = useMapGetter('customRole/getUIFlags');

const helpURL = computed(() => getHelpUrlForFeature('custom_roles'));

const deleteDescription = computed(() =>
  t('CUSTOM_ROLE.DELETE.CONFIRM.MESSAGE', {
    name: activeResponse.value?.name || '',
  })
);

const isFeatureEnabledOnAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const currentAccountId = useMapGetter('getCurrentAccountId');

const isBehindAPaywall = computed(() => {
  return !isFeatureEnabledOnAccount.value(
    currentAccountId.value,
    'custom_roles'
  );
});

const fetchCustomRoles = async () => {
  try {
    await store.dispatch('customRole/getCustomRole');
  } catch {
    // Ignore
  }
};

onMounted(() => {
  fetchCustomRoles();
});

const tableHeaders = computed(() => {
  return [
    t('CUSTOM_ROLE.LIST.TABLE_HEADER.NAME'),
    t('CUSTOM_ROLE.LIST.TABLE_HEADER.DESCRIPTION'),
    t('CUSTOM_ROLE.LIST.TABLE_HEADER.PERMISSIONS'),
    t('CUSTOM_ROLE.LIST.TABLE_HEADER.ACTIONS'),
  ];
});

const showAlertMessage = message => {
  const id = activeResponse.value?.id;
  if (id != null) {
    loading.value[id] = false;
  }
  activeResponse.value = {};
  useAlert(message);
};

const openAddModal = () => {
  if (isBehindAPaywall.value) return;
  customRoleModalMode.value = 'add';
  selectedRole.value = null;
  showCustomRoleModal.value = true;
};

const openEditModal = role => {
  customRoleModalMode.value = 'edit';
  selectedRole.value = role;
  showCustomRoleModal.value = true;
};

const hideCustomRoleModal = () => {
  selectedRole.value = null;
  showCustomRoleModal.value = false;
};

const openDeletePopup = response => {
  activeResponse.value = response;
  nextTick(() => {
    deleteDialogRef.value?.open();
  });
};

const deleteCustomRole = async id => {
  try {
    await store.dispatch('customRole/deleteCustomRole', id);
    showAlertMessage(t('CUSTOM_ROLE.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.message || t('CUSTOM_ROLE.DELETE.API.ERROR_MESSAGE');
    showAlertMessage(errorMessage);
  }
};

const confirmDeletion = () => {
  const id = activeResponse.value.id;
  loading.value[id] = true;
  deleteDialogRef.value?.close();
  deleteCustomRole(id);
};
</script>

<template>
  <div>
    <SettingsLayout
      :is-loading="uiFlags.fetchingList"
      :loading-message="t('CUSTOM_ROLE.LIST.LOADING')"
      :no-records-found="!records.length && !isBehindAPaywall"
      :no-records-message="t('CUSTOM_ROLE.LIST.404')"
    >
      <template #header>
        <div
          class="flex flex-col gap-6 pb-2 sm:flex-row sm:items-end sm:justify-between"
        >
          <div class="min-w-0 space-y-2">
            <p
              class="mb-0 text-[11px] font-bold uppercase tracking-widest text-on-surface-variant/70"
            >
              {{ t('CUSTOM_ROLE.PAGE_EYEBROW') }}
            </p>
            <h2 class="mb-0 text-3xl font-bold tracking-tight text-on-surface">
              {{ t('CUSTOM_ROLE.HEADER') }}
            </h2>
            <p class="mb-0 w-full text-base text-on-primary-container">
              {{ t('CUSTOM_ROLE.PAGE_SUBTITLE') }}
            </p>
            <CustomBrandPolicyWrapper :show-on-custom-branded-instance="false">
              <a
                v-if="helpURL"
                :href="helpURL"
                target="_blank"
                rel="noopener noreferrer"
                class="inline-flex items-center gap-1 text-sm font-medium text-secondary hover:underline"
              >
                {{ t('CUSTOM_ROLE.LEARN_MORE') }}
                <Icon icon="i-lucide-chevron-right" class="size-4 shrink-0" />
              </a>
            </CustomBrandPolicyWrapper>
          </div>
          <NextButton
            solid
            teal
            lg
            icon="i-lucide-plus"
            :label="t('CUSTOM_ROLE.HEADER_BTN_TXT')"
            class="w-full shrink-0 rounded-xl font-bold shadow-none hover:shadow-[0_0_20px_rgba(4,190,153,0.4)] active:scale-[0.98] sm:w-auto"
            :disabled="isBehindAPaywall"
            @click="openAddModal"
          />
        </div>
      </template>

      <template #body>
        <CustomRolePaywall v-if="isBehindAPaywall" />
        <template v-else>
          <div
            class="overflow-x-auto rounded-2xl border border-outline-variant/10 shadow-xl"
          >
            <div class="min-w-[56rem] bg-surface-container-low">
              <table
                class="min-w-full divide-y divide-surface-container-high/30"
              >
                <thead>
                  <tr
                    class="border-b border-surface-container-high/50 bg-surface-container-high/30"
                  >
                    <th
                      v-for="thHeader in tableHeaders"
                      :key="thHeader"
                      class="px-6 py-4 text-start text-[11px] font-bold uppercase tracking-widest text-tertiary/60 last:text-end"
                    >
                      {{ thHeader }}
                    </th>
                  </tr>
                </thead>
                <CustomRoleTableBody
                  :roles="records"
                  :loading="loading"
                  @edit="openEditModal"
                  @delete="openDeletePopup"
                />
              </table>
            </div>
          </div>
          <p class="mt-6 text-xs font-medium text-on-primary-container">
            {{ t('CUSTOM_ROLE.LIST.SHOWING_COUNT', { count: records.length }) }}
          </p>
        </template>
      </template>
    </SettingsLayout>

    <woot-modal
      v-model:show="showCustomRoleModal"
      size="medium"
      :on-close="hideCustomRoleModal"
    >
      <CustomRoleModal
        v-if="showCustomRoleModal"
        :mode="customRoleModalMode"
        :selected-role="selectedRole"
        @close="hideCustomRoleModal"
      />
    </woot-modal>

    <ConfirmDialog
      ref="deleteDialogRef"
      type="alert"
      :title="t('CUSTOM_ROLE.DELETE.CONFIRM.TITLE')"
      :description="deleteDescription"
      :confirm-button-label="t('CUSTOM_ROLE.DELETE.CONFIRM.YES')"
      :cancel-button-label="t('CUSTOM_ROLE.DELETE.CONFIRM.NO')"
      @confirm="confirmDeletion"
    />
  </div>
</template>
