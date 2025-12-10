<script setup>
import { ref, computed, watch } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import Modal from 'dashboard/components/Modal.vue';
import ModalHeader from 'dashboard/components/ModalHeader.vue';
import surveysAPI from 'dashboard/api/surveys';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  contact: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['close']);
const { t } = useI18n();

const surveys = ref([]);
const selectedSurveyId = ref(null);
const isLoading = ref(false);
const isCalling = ref(false);
const isModalOpen = ref(props.show);

const hasValidPhoneNumber = computed(() => {
  const phoneNumber = props.contact?.phone_number;
  if (!phoneNumber) return false;
  // Validate E.164 format: +[1-9]\d{1,14}
  return /^\+[1-9]\d{1,14}$/.test(phoneNumber);
});

const activeSurveys = computed(() => {
  return surveys.value.filter(survey => survey.active);
});

const canMakeCall = computed(() => {
  return hasValidPhoneNumber.value && selectedSurveyId.value && !isCalling.value;
});

const loadSurveys = async () => {
  isLoading.value = true;
  try {
    const response = await surveysAPI.get();
    surveys.value = response.data;
  } catch (error) {
    useAlert(t('CONVERSATION.SURVEY_CALL.LOAD_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

const makeSurveyCall = async () => {
  if (!canMakeCall.value) return;

  isCalling.value = true;
  try {
    await surveysAPI.initiateSurveyCall({
      contactId: props.contact.id,
      surveyId: selectedSurveyId.value,
    });

    useAlert(t('CONVERSATION.SURVEY_CALL.SUCCESS'));
    emit('close');
  } catch (error) {
    const errorMessage = error.response?.data?.error || t('CONVERSATION.SURVEY_CALL.ERROR');
    useAlert(errorMessage);
  } finally {
    isCalling.value = false;
  }
};

const closeModal = () => {
  selectedSurveyId.value = null;
  isModalOpen.value = false;
  emit('close');
};

// Watch for show prop changes
watch(() => props.show, (newVal) => {
  isModalOpen.value = newVal;
  if (newVal) {
    loadSurveys();
  }
});
</script>

<template>
  <Modal v-model:show="isModalOpen" :on-close="closeModal">
    <div class="flex flex-col h-auto overflow-auto">
      <ModalHeader :header-title="t('CONVERSATION.SURVEY_CALL.TITLE')" />

      <div class="px-8 pb-8">
        <!-- Phone validation message -->
        <div
          v-if="!hasValidPhoneNumber"
          class="p-4 mb-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg"
        >
          <p class="text-sm text-red-800 dark:text-red-200">
            {{ t('CONVERSATION.SURVEY_CALL.NO_VALID_PHONE') }}
          </p>
        </div>

        <!-- Contact info -->
        <div v-if="hasValidPhoneNumber" class="mb-4">
          <p class="text-sm text-n-slate-11 mb-2">
            {{ t('CONVERSATION.SURVEY_CALL.CONTACT_INFO') }}
          </p>
          <div class="p-3 bg-n-light border border-n-weak rounded-lg">
            <p class="font-medium text-n-slate-12">{{ contact.name }}</p>
            <p class="text-sm text-n-slate-11">{{ contact.phone_number }}</p>
          </div>
        </div>

        <!-- Survey selection -->
        <div v-if="hasValidPhoneNumber" class="mb-6">
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            {{ t('CONVERSATION.SURVEY_CALL.SELECT_SURVEY') }}
          </label>

          <div v-if="isLoading" class="text-center py-8">
            <p class="text-sm text-n-slate-11">
              {{ t('CONVERSATION.SURVEY_CALL.LOADING') }}
            </p>
          </div>

          <div v-else-if="activeSurveys.length === 0" class="text-center py-8">
            <p class="text-sm text-n-slate-11">
              {{ t('CONVERSATION.SURVEY_CALL.NO_SURVEYS') }}
            </p>
          </div>

          <div v-else class="space-y-2 max-h-64 overflow-y-auto">
            <div
              v-for="survey in activeSurveys"
              :key="survey.id"
              class="p-3 border rounded-lg cursor-pointer transition-colors"
              :class="{
                'border-primary-500 bg-primary-50 dark:bg-primary-900/20': selectedSurveyId === survey.id,
                'border-n-weak hover:border-n-medium hover:bg-n-light': selectedSurveyId !== survey.id,
              }"
              @click="selectedSurveyId = survey.id"
            >
              <div class="flex items-start justify-between">
                <div class="flex-1">
                  <h4 class="font-medium text-n-slate-12">{{ survey.name }}</h4>
                  <p v-if="survey.description" class="text-sm text-n-slate-11 mt-1">
                    {{ survey.description }}
                  </p>
                  <p class="text-xs text-n-slate-10 mt-1">
                    {{ t('CONVERSATION.SURVEY_CALL.QUESTIONS_COUNT', { count: survey.questions_count || 0 }) }}
                  </p>
                </div>
                <div
                  v-if="selectedSurveyId === survey.id"
                  class="ml-3 text-primary-500"
                >
                  <i class="i-lucide-check-circle text-lg" />
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Actions -->
        <div class="flex justify-end gap-2 pt-4 border-t border-n-weak">
          <NextButton
            variant="ghost"
            :label="t('CONVERSATION.SURVEY_CALL.CANCEL')"
            @click="closeModal"
          />
          <NextButton
            v-if="hasValidPhoneNumber"
            variant="primary"
            :label="t('CONVERSATION.SURVEY_CALL.MAKE_CALL')"
            :disabled="!canMakeCall"
            :loading="isCalling"
            icon="i-lucide-phone"
            @click="makeSurveyCall"
          />
        </div>
      </div>
    </div>
  </Modal>
</template>
