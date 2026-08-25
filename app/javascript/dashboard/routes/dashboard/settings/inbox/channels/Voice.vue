<script setup>
import { reactive, ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import PathorsPhoneNumbersAPI from 'dashboard/api/pathorsPhoneNumbers';

import PageHeader from '../../SettingsSubPageHeader.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import RadioCard from 'dashboard/components-next/radioCard/RadioCard.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const { t } = useI18n();
const store = useStore();
const router = useRouter();

const state = reactive({
  inboxName: '',
  phoneNumberId: '',
});

const phoneNumbers = ref([]);
const isLoadingPhoneNumbers = ref(true);
const isIntegrationConnected = ref(true);

const uiFlags = useMapGetter('inboxes/getUIFlags');
const accountId = useMapGetter('getCurrentAccountId');

const validationRules = {
  inboxName: { required },
};

const v$ = useVuelidate(validationRules, state);

const selectedPhoneNumber = computed(() =>
  phoneNumbers.value.find(number => number.id === state.phoneNumberId)
);

const isSubmitDisabled = computed(
  () => v$.value.$invalid || !selectedPhoneNumber.value
);

const formErrors = computed(() => ({
  inboxName: v$.value.inboxName?.$error
    ? t('INBOX_MGMT.ADD.VOICE.INBOX_NAME.ERROR')
    : '',
}));

onMounted(async () => {
  try {
    const { data } = await PathorsPhoneNumbersAPI.get();
    phoneNumbers.value = data.payload;
  } catch (error) {
    if (error.response?.status === 404) {
      isIntegrationConnected.value = false;
    } else {
      useAlert(t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBERS.FETCH_ERROR'));
    }
  } finally {
    isLoadingPhoneNumbers.value = false;
  }
});

function selectPhoneNumber(id) {
  state.phoneNumberId = id;
}

async function createChannel() {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) return;

  try {
    const channel = await store.dispatch('inboxes/createVoiceChannel', {
      name: state.inboxName.trim(),
      voice: {
        phone_number: selectedPhoneNumber.value.phone_number,
        pathors_phone_number_id: selectedPhoneNumber.value.id,
      },
    });

    router.replace({
      name: 'settings_inboxes_add_agents',
      params: { page: 'new', inbox_id: channel.id },
    });
  } catch (error) {
    // A number Pathors already routes elsewhere comes back as a 409 whose body
    // is `{ error: ... }`, unlike the `{ message: ... }` of a model validation.
    useAlert(
      error.response?.data?.message ||
        error.response?.data?.error ||
        t('INBOX_MGMT.ADD.VOICE.API.ERROR_MESSAGE')
    );
  }
}
</script>

<template>
  <div class="overflow-auto col-span-6 p-6 w-full h-full">
    <PageHeader
      :header-title="t('INBOX_MGMT.ADD.VOICE.TITLE')"
      :header-content="t('INBOX_MGMT.ADD.VOICE.DESC')"
    />

    <form
      class="flex flex-col gap-6 flex-wrap mx-0"
      @submit.prevent="createChannel"
    >
      <Input
        v-model="state.inboxName"
        :label="t('INBOX_MGMT.ADD.VOICE.INBOX_NAME.LABEL')"
        :placeholder="t('INBOX_MGMT.ADD.VOICE.INBOX_NAME.PLACEHOLDER')"
        :message="formErrors.inboxName"
        :message-type="formErrors.inboxName ? 'error' : 'info'"
        @blur="v$.inboxName?.$touch"
      />

      <div class="flex flex-col gap-1">
        <span class="mb-0.5 text-heading-3 text-n-slate-12">
          {{ t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBERS.LABEL') }}
        </span>

        <div
          v-if="isLoadingPhoneNumbers"
          class="flex items-center gap-2 py-6 text-n-slate-11"
        >
          <Spinner :size="16" />
          <span class="text-body-main">
            {{ t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBERS.LOADING') }}
          </span>
        </div>

        <div
          v-else-if="!isIntegrationConnected"
          class="flex flex-col items-start gap-3 p-6 rounded-xl outline outline-1 outline-n-container bg-n-card"
        >
          <h4 class="text-heading-3 text-n-slate-12">
            {{ t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBERS.NOT_CONNECTED.TITLE') }}
          </h4>
          <p class="max-w-2xl text-body-main text-n-slate-11">
            {{
              t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBERS.NOT_CONNECTED.DESCRIPTION')
            }}
          </p>
          <router-link
            :to="{
              name: 'settings_applications_pathors',
              params: { accountId },
            }"
          >
            <NextButton
              type="button"
              :label="
                t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBERS.NOT_CONNECTED.ACTION')
              "
              icon="i-lucide-plug"
              trailing-icon
            />
          </router-link>
        </div>

        <div
          v-else-if="!phoneNumbers.length"
          class="flex flex-col items-start gap-3 p-6 rounded-xl outline outline-1 outline-n-container bg-n-card"
        >
          <h4 class="text-heading-3 text-n-slate-12">
            {{ t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBERS.EMPTY.TITLE') }}
          </h4>
          <p class="max-w-2xl text-body-main text-n-slate-11">
            {{ t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBERS.EMPTY.DESCRIPTION') }}
          </p>
        </div>

        <template v-else>
          <div class="flex flex-col gap-2">
            <RadioCard
              v-for="number in phoneNumbers"
              :id="number.id"
              :key="number.id"
              :label="number.label || number.phone_number"
              :description="number.phone_number"
              :is-active="state.phoneNumberId === number.id"
              :disabled="Boolean(number.binding)"
              :disabled-label="
                t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBERS.TAKEN_LABEL')
              "
              @select="selectPhoneNumber"
            >
              <span
                v-if="number.extension"
                class="text-label-small text-n-slate-10"
              >
                {{
                  t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBERS.EXTENSION', {
                    extension: number.extension,
                  })
                }}
              </span>
            </RadioCard>
          </div>
          <p class="mt-1 mb-0 text-label-small text-n-slate-11">
            {{ t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBERS.HELP') }}
          </p>
        </template>
      </div>

      <div>
        <NextButton
          :is-loading="uiFlags.isCreating"
          :disabled="isSubmitDisabled"
          :label="t('INBOX_MGMT.ADD.VOICE.SUBMIT_BUTTON')"
          type="submit"
        />
      </div>
    </form>
  </div>
</template>
