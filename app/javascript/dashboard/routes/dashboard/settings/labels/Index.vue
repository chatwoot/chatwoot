<script setup>
import { useAlert } from 'dashboard/composables';
import { computed, onBeforeMount, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';

import AddLabel from './AddLabel.vue';
import EditLabel from './EditLabel.vue';
import CustomBrandPolicyWrapper from 'dashboard/components/CustomBrandPolicyWrapper.vue';
import { getHelpUrlForFeature } from 'dashboard/helper/featureHelper';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();

const loading = ref({});
const showAddPopup = ref(false);
const showEditPopup = ref(false);
const selectedLabel = ref({});
const labelDeleteDialogRef = ref(null);

const records = computed(() => getters['labels/getLabels'].value);
const uiFlags = computed(() => getters['labels/getUIFlags'].value);
const helpURL = computed(() => getHelpUrlForFeature('labels'));

const selectedLabelTitle = computed(() => selectedLabel.value?.title || '');

const deleteDescription = computed(() => {
  const title = selectedLabelTitle.value;
  return `${t('LABEL_MGMT.DELETE.CONFIRM.MESSAGE')}${title}?`;
});

const openAddPopup = () => {
  showAddPopup.value = true;
};
const hideAddPopup = () => {
  showAddPopup.value = false;
};

const openEditPopup = label => {
  showEditPopup.value = true;
  selectedLabel.value = label;
};
const hideEditPopup = () => {
  showEditPopup.value = false;
};

const openDeletePopup = label => {
  selectedLabel.value = label;
  labelDeleteDialogRef.value?.open();
};

const closeDeletePopup = () => {
  labelDeleteDialogRef.value?.close();
};

const deleteLabel = async id => {
  try {
    await store.dispatch('labels/delete', id);
    useAlert(t('LABEL_MGMT.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.message || t('LABEL_MGMT.DELETE.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  } finally {
    loading.value[id] = false;
  }
};

const confirmDeletion = () => {
  const id = selectedLabel.value.id;
  loading.value[id] = true;
  closeDeletePopup();
  deleteLabel(id);
};

onBeforeMount(() => {
  store.dispatch('labels/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('LABEL_MGMT.LIST.LOADING')"
    :no-records-found="!records.length"
    :no-records-message="$t('LABEL_MGMT.LIST.404')"
  >
    <template #header>
      <div
        class="flex flex-col gap-6 pb-2 sm:flex-row sm:items-end sm:justify-between"
      >
        <div class="min-w-0 space-y-2">
          <p
            class="mb-0 text-[11px] font-bold uppercase tracking-widest text-on-surface-variant/70"
          >
            {{ t('LABEL_MGMT.PAGE_EYEBROW') }}
          </p>
          <h2 class="mb-0 text-3xl font-bold tracking-tight text-on-surface">
            {{ t('LABEL_MGMT.HEADER') }}
          </h2>
          <p class="mb-0 max-w-2xl text-base text-on-primary-container">
            {{ t('LABEL_MGMT.PAGE_SUBTITLE') }}
          </p>
          <CustomBrandPolicyWrapper :show-on-custom-branded-instance="false">
            <a
              v-if="helpURL"
              :href="helpURL"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-1 text-sm font-medium text-secondary hover:underline"
            >
              {{ t('LABEL_MGMT.LEARN_MORE') }}
              <Icon icon="i-lucide-chevron-right" class="size-4 shrink-0" />
            </a>
          </CustomBrandPolicyWrapper>
        </div>
        <Button
          solid
          teal
          lg
          icon="i-lucide-plus"
          :label="t('LABEL_MGMT.HEADER_BTN_TXT')"
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
              class="col-span-3 text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
            >
              {{ t('LABEL_MGMT.LIST.TABLE_HEADER.NAME') }}
            </div>
            <div
              class="col-span-4 text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
            >
              {{ t('LABEL_MGMT.LIST.TABLE_HEADER.DESCRIPTION') }}
            </div>
            <div
              class="col-span-3 text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
            >
              {{ t('LABEL_MGMT.LIST.TABLE_HEADER.COLOR') }}
            </div>
            <div
              class="col-span-2 text-end text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
            >
              {{ t('LABEL_MGMT.LIST.TABLE_HEADER.ACTIONS') }}
            </div>
          </div>
          <div class="divide-y divide-surface-container-high/30">
            <div
              v-for="label in records"
              :key="label.id"
              class="grid grid-cols-12 items-center px-6 py-4 transition-all duration-200 hover:bg-surface-container-high/40"
            >
              <div class="col-span-3 min-w-0">
                <span
                  class="block text-sm font-bold break-words text-on-surface"
                >
                  {{ label.title }}
                </span>
                <span
                  v-if="label.show_on_sidebar"
                  class="mt-1 inline-block rounded-md bg-surface-container-high px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-on-primary-container"
                >
                  {{ t('LABEL_MGMT.LIST.SIDEBAR_BADGE') }}
                </span>
              </div>
              <div class="col-span-4 min-w-0 text-sm text-on-primary-container">
                <span class="line-clamp-2">{{ label.description || '—' }}</span>
              </div>
              <div class="col-span-3 min-w-0">
                <div class="flex items-center gap-2">
                  <span
                    class="size-4 shrink-0 rounded border border-outline-variant/30 shadow-sm"
                    :style="{ backgroundColor: label.color }"
                  />
                  <span
                    class="font-mono text-xs text-on-primary-container"
                    :title="label.color"
                  >
                    {{ label.color }}
                  </span>
                </div>
              </div>
              <div class="col-span-2 flex justify-end gap-1">
                <button
                  v-tooltip.top="t('LABEL_MGMT.FORM.EDIT')"
                  type="button"
                  :disabled="loading[label.id]"
                  class="rounded-lg p-2 text-tertiary opacity-70 outline-none transition-all hover:bg-surface-container-high hover:text-secondary hover:opacity-100 focus-visible:ring-2 focus-visible:ring-secondary/40 disabled:pointer-events-none disabled:opacity-40"
                  @click="openEditPopup(label)"
                >
                  <Icon icon="i-lucide-pen" class="size-5" />
                </button>
                <button
                  v-tooltip.top="t('LABEL_MGMT.FORM.DELETE')"
                  type="button"
                  :disabled="loading[label.id]"
                  class="rounded-lg p-2 text-tertiary opacity-70 outline-none transition-all hover:bg-surface-container-high hover:text-error hover:opacity-100 focus-visible:ring-2 focus-visible:ring-error/40 disabled:pointer-events-none disabled:opacity-40"
                  @click="openDeletePopup(label)"
                >
                  <Spinner v-if="loading[label.id]" class="size-5" />
                  <Icon v-else icon="i-lucide-trash-2" class="size-5" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
      <p class="mt-6 text-xs font-medium text-on-primary-container">
        {{ t('LABEL_MGMT.LIST.SHOWING_COUNT', { count: records.length }) }}
      </p>
    </template>

    <woot-modal v-model:show="showAddPopup" :on-close="hideAddPopup">
      <AddLabel @close="hideAddPopup" />
    </woot-modal>

    <woot-modal v-model:show="showEditPopup" :on-close="hideEditPopup">
      <EditLabel :selected-response="selectedLabel" @close="hideEditPopup" />
    </woot-modal>

    <Dialog
      ref="labelDeleteDialogRef"
      type="alert"
      :title="t('LABEL_MGMT.DELETE.CONFIRM.TITLE')"
      :description="deleteDescription"
      :confirm-button-label="t('LABEL_MGMT.DELETE.CONFIRM.YES')"
      :cancel-button-label="t('LABEL_MGMT.DELETE.CONFIRM.NO')"
      @confirm="confirmDeletion"
    />
  </SettingsLayout>
</template>
