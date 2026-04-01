<script setup>
import { useAlert } from 'dashboard/composables';
import MacrosTableRow from './MacrosTableRow.vue';
import SettingsLayout from '../SettingsLayout.vue';
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import CustomBrandPolicyWrapper from 'dashboard/components/CustomBrandPolicyWrapper.vue';
import { getHelpUrlForFeature } from 'dashboard/helper/featureHelper';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();

const deleteDialogRef = ref(null);
const selectedMacro = ref({});

const records = computed(() => getters['macros/getMacros'].value);
const uiFlags = computed(() => getters['macros/getUIFlags'].value);
const helpURL = computed(() => getHelpUrlForFeature('macros'));

const deleteDescription = computed(() => {
  const name = selectedMacro.value?.name || '';
  return `${t('MACROS.DELETE.CONFIRM.MESSAGE')}${name}?`;
});

onMounted(() => {
  store.dispatch('macros/get');
});

const deleteMacro = async id => {
  try {
    await store.dispatch('macros/delete', id);
    useAlert(t('MACROS.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('MACROS.DELETE.API.ERROR_MESSAGE'));
  }
};

const openDeletePopup = macro => {
  selectedMacro.value = macro;
  deleteDialogRef.value?.open();
};

const confirmDeletion = () => {
  const id = selectedMacro.value.id;
  deleteDialogRef.value?.close();
  deleteMacro(id);
};
</script>

<template>
  <div>
    <SettingsLayout
      :no-records-message="t('MACROS.LIST.404')"
      :no-records-found="!records.length"
      :is-loading="uiFlags.isFetching"
      :loading-message="t('MACROS.LIST.LOADING')"
    >
      <template #header>
        <div
          class="flex flex-col gap-6 pb-2 sm:flex-row sm:items-end sm:justify-between"
        >
          <div class="min-w-0 space-y-2">
            <p
              class="mb-0 text-[11px] font-bold uppercase tracking-widest text-on-surface-variant/70"
            >
              {{ t('MACROS.PAGE_EYEBROW') }}
            </p>
            <h2 class="mb-0 text-3xl font-bold tracking-tight text-on-surface">
              {{ t('MACROS.HEADER') }}
            </h2>
            <p class="mb-0 w-full text-base text-on-primary-container">
              {{ t('MACROS.PAGE_SUBTITLE') }}
            </p>
            <CustomBrandPolicyWrapper :show-on-custom-branded-instance="false">
              <a
                v-if="helpURL"
                :href="helpURL"
                target="_blank"
                rel="noopener noreferrer"
                class="inline-flex items-center gap-1 text-sm font-medium text-secondary hover:underline"
              >
                {{ t('MACROS.LEARN_MORE') }}
                <Icon icon="i-lucide-chevron-right" class="size-4 shrink-0" />
              </a>
            </CustomBrandPolicyWrapper>
          </div>
          <router-link
            :to="{ name: 'macros_new' }"
            class="inline-flex w-full shrink-0 sm:w-auto"
          >
            <Button
              solid
              teal
              lg
              icon="i-lucide-plus"
              :label="t('MACROS.HEADER_BTN_TXT')"
              class="w-full rounded-xl font-bold shadow-none hover:shadow-[0_0_20px_rgba(4,190,153,0.4)] active:scale-[0.98] sm:w-auto"
            />
          </router-link>
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
                {{ t('MACROS.LIST.TABLE_HEADER.NAME') }}
              </div>
              <div
                class="col-span-3 text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
              >
                {{ t('MACROS.LIST.TABLE_HEADER.CREATED BY') }}
              </div>
              <div
                class="col-span-3 text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
              >
                {{ t('MACROS.LIST.TABLE_HEADER.LAST_UPDATED_BY') }}
              </div>
              <div
                class="col-span-2 text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
              >
                {{ t('MACROS.LIST.TABLE_HEADER.VISIBILITY') }}
              </div>
              <div
                class="col-span-1 text-end text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
              >
                {{ t('MACROS.LIST.TABLE_HEADER.ACTIONS') }}
              </div>
            </div>
            <div class="divide-y divide-surface-container-high/30">
              <MacrosTableRow
                v-for="macro in records"
                :key="macro.id"
                :macro="macro"
                @delete="openDeletePopup(macro)"
              />
            </div>
          </div>
        </div>
        <p class="mt-6 text-xs font-medium text-on-primary-container">
          {{ t('MACROS.LIST.SHOWING_COUNT', { count: records.length }) }}
        </p>
      </template>
    </SettingsLayout>

    <Dialog
      ref="deleteDialogRef"
      type="alert"
      :title="t('MACROS.DELETE.CONFIRM.TITLE')"
      :description="deleteDescription"
      :confirm-button-label="t('MACROS.DELETE.CONFIRM.YES')"
      :cancel-button-label="t('MACROS.DELETE.CONFIRM.NO')"
      @confirm="confirmDeletion"
    />
  </div>
</template>
