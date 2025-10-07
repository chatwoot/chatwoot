<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import SurveyModal from './components/SurveyModal.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const MODAL_TYPES = {
  CREATE: 'create',
  EDIT: 'edit',
};

const store = useStore();
const router = useRouter();
const { t } = useI18n();

const surveys = useMapGetter('surveys/getSurveys');
const uiFlags = useMapGetter('surveys/getUIFlags');

const selectedSurvey = ref({});
const loading = ref({});
const modalType = ref(MODAL_TYPES.CREATE);
const surveyModalRef = ref(null);
const surveyDeleteDialogRef = ref(null);

const tableHeaders = computed(() => {
  return [
    t('SURVEYS.LIST.TABLE_HEADER.NAME'),
    t('SURVEYS.LIST.TABLE_HEADER.DESCRIPTION'),
    t('SURVEYS.LIST.TABLE_HEADER.QUESTIONS'),
    t('SURVEYS.LIST.TABLE_HEADER.STATUS'),
  ];
});

const selectedSurveyName = computed(() => selectedSurvey.value?.name || '');

const openAddModal = () => {
  modalType.value = MODAL_TYPES.CREATE;
  selectedSurvey.value = {};
  surveyModalRef.value.dialogRef.open();
};

const openEditModal = survey => {
  modalType.value = MODAL_TYPES.EDIT;
  selectedSurvey.value = survey;
  surveyModalRef.value.dialogRef.open();
};

const openDeletePopup = survey => {
  selectedSurvey.value = survey;
  surveyDeleteDialogRef.value.open();
};

const navigateToQuestions = survey => {
  router.push({
    name: 'survey_questions',
    params: { surveyId: survey.id },
  });
};

const deleteSurvey = async id => {
  try {
    await store.dispatch('surveys/delete', id);
    useAlert(t('SURVEYS.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('SURVEYS.DELETE.API.ERROR_MESSAGE'));
  } finally {
    loading.value[id] = false;
    selectedSurvey.value = {};
  }
};

const confirmDeletion = () => {
  loading.value[selectedSurvey.value.id] = true;
  deleteSurvey(selectedSurvey.value.id);
  surveyDeleteDialogRef.value.close();
};

onMounted(() => {
  store.dispatch('surveys/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="t('SURVEYS.LIST.LOADING')"
    :no-records-found="!surveys.length"
    :no-records-message="t('SURVEYS.LIST.404')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('SURVEYS.HEADER')"
        :description="t('SURVEYS.DESCRIPTION')"
        :link-text="t('SURVEYS.LEARN_MORE')"
        feature-name="surveys"
      >
        <template #actions>
          <Button
            icon="i-lucide-circle-plus"
            :label="$t('SURVEYS.ADD.TITLE')"
            @click="openAddModal"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <table class="min-w-full overflow-x-auto divide-y divide-n-strong">
        <thead>
          <th
            v-for="thHeader in tableHeaders"
            :key="thHeader"
            class="py-4 font-semibold text-left ltr:pr-4 rtl:pl-4 text-n-slate-11"
          >
            {{ thHeader }}
          </th>
        </thead>
        <tbody class="flex-1 divide-y divide-n-weak text-n-slate-12">
          <tr v-for="survey in surveys" :key="survey.id">
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              <button
                class="font-medium text-left hover:text-woot-500 hover:underline"
                @click="navigateToQuestions(survey)"
              >
                {{ survey.name }}
              </button>
            </td>
            <td class="py-4 ltr:pr-4 rtl:pl-4 text-sm text-n-slate-11">
              {{ survey.description || '-' }}
            </td>
            <td class="py-4 ltr:pr-4 rtl:pl-4 text-sm">
              {{ survey.questions_count }}
            </td>
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              <span
                class="inline-flex items-center px-2 py-1 text-xs font-medium rounded-md"
                :class="[
                  survey.active
                    ? 'bg-n-green-3 text-n-green-11'
                    : 'bg-n-slate-3 text-n-slate-11',
                ]"
              >
                {{
                  survey.active
                    ? $t('SURVEYS.STATUS.ACTIVE')
                    : $t('SURVEYS.STATUS.INACTIVE')
                }}
              </span>
            </td>
            <td class="py-4 min-w-xs">
              <div class="flex gap-1 justify-end">
                <Button
                  v-tooltip.top="t('SURVEYS.EDIT.BUTTON_TEXT')"
                  icon="i-lucide-pen"
                  slate
                  xs
                  faded
                  :is-loading="loading[survey.id]"
                  @click="openEditModal(survey)"
                />
                <Button
                  v-tooltip.top="t('SURVEYS.DELETE.BUTTON_TEXT')"
                  icon="i-lucide-trash-2"
                  xs
                  ruby
                  faded
                  :is-loading="loading[survey.id]"
                  @click="openDeletePopup(survey)"
                />
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </template>

    <SurveyModal
      ref="surveyModalRef"
      :type="modalType"
      :selected-survey="selectedSurvey"
    />

    <Dialog
      ref="surveyDeleteDialogRef"
      type="alert"
      :title="t('SURVEYS.DELETE.CONFIRM.TITLE')"
      :description="
        t('SURVEYS.DELETE.CONFIRM.MESSAGE', { name: selectedSurveyName })
      "
      :is-loading="uiFlags.isDeleting"
      :confirm-button-label="t('SURVEYS.DELETE.CONFIRM.YES')"
      :cancel-button-label="t('SURVEYS.DELETE.CONFIRM.NO')"
      @confirm="confirmDeletion"
    />
  </SettingsLayout>
</template>
