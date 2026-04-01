<script setup>
import { useAlert } from 'dashboard/composables';
import AddCanned from './AddCanned.vue';
import EditCanned from './EditCanned.vue';
import CannedResponseRow from './CannedResponseRow.vue';
import SettingsLayout from '../SettingsLayout.vue';
import { computed, onMounted, ref, defineOptions } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';

import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import CustomBrandPolicyWrapper from 'dashboard/components/CustomBrandPolicyWrapper.vue';
import { getHelpUrlForFeature } from 'dashboard/helper/featureHelper';

defineOptions({
  name: 'CannedResponseSettings',
});

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();

const showAddPopup = ref(false);
const loading = ref({});
const showEditPopup = ref(false);
const deleteDialogRef = ref(null);
const activeResponse = ref({});

const sortOrder = ref('asc');
const records = computed(() =>
  getters.getSortedCannedResponses.value(sortOrder.value)
);
const uiFlags = computed(() => getters.getUIFlags.value);
const helpURL = computed(() => getHelpUrlForFeature('canned_responses'));

const deleteDescription = computed(() => {
  const code = activeResponse.value?.short_code || '';
  return `${t('CANNED_MGMT.DELETE.CONFIRM.MESSAGE')}"${code}"?`;
});

const toggleSort = () => {
  sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc';
};

const fetchCannedResponses = async () => {
  try {
    await store.dispatch('getCannedResponse');
  } catch {
    // Ignore
  }
};

onMounted(() => {
  fetchCannedResponses();
});

const showAlertMessage = message => {
  const id = activeResponse.value?.id;
  if (id != null) {
    loading.value[id] = false;
  }
  activeResponse.value = {};
  useAlert(message);
};

const openAddPopup = () => {
  showAddPopup.value = true;
};
const hideAddPopup = () => {
  showAddPopup.value = false;
};

const openEditPopup = response => {
  showEditPopup.value = true;
  activeResponse.value = response;
};
const hideEditPopup = () => {
  showEditPopup.value = false;
};

const openDeletePopup = response => {
  activeResponse.value = response;
  deleteDialogRef.value?.open();
};

const deleteCannedResponse = async id => {
  try {
    await store.dispatch('deleteCannedResponse', id);
    showAlertMessage(t('CANNED_MGMT.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.message || t('CANNED_MGMT.DELETE.API.ERROR_MESSAGE');
    showAlertMessage(errorMessage);
  }
};

const confirmDeletion = () => {
  const id = activeResponse.value.id;
  loading.value[id] = true;
  deleteDialogRef.value?.close();
  deleteCannedResponse(id);
};
</script>

<template>
  <div>
    <SettingsLayout
      :is-loading="uiFlags.fetchingList"
      :loading-message="t('CANNED_MGMT.LIST.LOADING')"
      :no-records-found="!records.length"
      :no-records-message="t('CANNED_MGMT.LIST.404')"
    >
      <template #header>
        <div
          class="flex flex-col gap-6 pb-2 sm:flex-row sm:items-end sm:justify-between"
        >
          <div class="min-w-0 space-y-2">
            <p
              class="mb-0 text-[11px] font-bold uppercase tracking-widest text-on-surface-variant/70"
            >
              {{ t('CANNED_MGMT.PAGE_EYEBROW') }}
            </p>
            <h2 class="mb-0 text-3xl font-bold tracking-tight text-on-surface">
              {{ t('CANNED_MGMT.HEADER') }}
            </h2>
            <p class="mb-0 max-w-2xl text-base text-on-primary-container">
              {{ t('CANNED_MGMT.PAGE_SUBTITLE') }}
            </p>
            <CustomBrandPolicyWrapper :show-on-custom-branded-instance="false">
              <a
                v-if="helpURL"
                :href="helpURL"
                target="_blank"
                rel="noopener noreferrer"
                class="inline-flex items-center gap-1 text-sm font-medium text-secondary hover:underline"
              >
                {{ t('CANNED_MGMT.LEARN_MORE') }}
                <Icon icon="i-lucide-chevron-right" class="size-4 shrink-0" />
              </a>
            </CustomBrandPolicyWrapper>
          </div>
          <Button
            solid
            teal
            lg
            icon="i-lucide-plus"
            :label="t('CANNED_MGMT.HEADER_BTN_TXT')"
            class="w-full shrink-0 rounded-xl font-bold shadow-none hover:shadow-[0_0_20px_rgba(4,190,153,0.4)] active:scale-[0.98] sm:w-auto"
            @click="openAddPopup"
          />
        </div>
      </template>
      <template #body>
        <div
          class="overflow-x-auto rounded-2xl border border-outline-variant/10 shadow-xl"
        >
          <div class="min-w-[44rem] bg-surface-container-low">
            <div
              class="grid grid-cols-12 border-b border-surface-container-high/50 bg-surface-container-high/30 px-6 py-4"
            >
              <div
                class="col-span-3 flex items-center text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
              >
                <button
                  type="button"
                  class="flex items-center gap-2 rounded-md p-0 text-start text-inherit outline-none transition-colors hover:text-secondary focus-visible:ring-2 focus-visible:ring-secondary/40"
                  @click="toggleSort"
                >
                  {{ t('CANNED_MGMT.LIST.TABLE_HEADER.SHORT_CODE') }}
                  <Icon
                    :icon="
                      sortOrder === 'desc'
                        ? 'i-lucide-chevron-up'
                        : 'i-lucide-chevron-down'
                    "
                    class="size-4 shrink-0 text-tertiary"
                  />
                </button>
              </div>
              <div
                class="col-span-7 text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
              >
                {{ t('CANNED_MGMT.LIST.TABLE_HEADER.CONTENT') }}
              </div>
              <div
                class="col-span-2 text-end text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
              >
                {{ t('CANNED_MGMT.LIST.TABLE_HEADER.ACTIONS') }}
              </div>
            </div>
            <div class="divide-y divide-surface-container-high/30">
              <CannedResponseRow
                v-for="cannedItem in records"
                :key="cannedItem.id"
                :item="cannedItem"
                :deleting="Boolean(loading[cannedItem.id])"
                @edit="openEditPopup"
                @delete="openDeletePopup"
              />
            </div>
          </div>
        </div>
        <p class="mt-6 text-xs font-medium text-on-primary-container">
          {{ t('CANNED_MGMT.LIST.SHOWING_COUNT', { count: records.length }) }}
        </p>
      </template>
    </SettingsLayout>

    <woot-modal
      v-model:show="showAddPopup"
      size="medium"
      :on-close="hideAddPopup"
    >
      <AddCanned v-if="showAddPopup" :on-close="hideAddPopup" />
    </woot-modal>

    <woot-modal
      v-model:show="showEditPopup"
      size="medium"
      :on-close="hideEditPopup"
    >
      <EditCanned
        v-if="showEditPopup"
        :id="activeResponse.id"
        :edshort-code="activeResponse.short_code"
        :edcontent="activeResponse.content"
        :on-close="hideEditPopup"
      />
    </woot-modal>

    <Dialog
      ref="deleteDialogRef"
      type="alert"
      :title="t('CANNED_MGMT.DELETE.CONFIRM.TITLE')"
      :description="deleteDescription"
      :confirm-button-label="t('CANNED_MGMT.DELETE.CONFIRM.YES')"
      :cancel-button-label="t('CANNED_MGMT.DELETE.CONFIRM.NO')"
      @confirm="confirmDeletion"
    />
  </div>
</template>
