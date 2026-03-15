<script setup>
import { computed, reactive, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { required, email } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';
import { splitName } from '@chatwoot/utils';
import countries from 'shared/constants/countries.js';
import Input from 'dashboard/components-next/input/Input.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import PhoneNumberInput from 'dashboard/components-next/phonenumberinput/PhoneNumberInput.vue';
import ContactEmailFields from './ContactEmailFields.vue';

const props = defineProps({
  contactData: {
    type: Object,
    default: null,
  },
  isDetailsView: {
    type: Boolean,
    default: false,
  },
  isNewContact: {
    type: Boolean,
    default: false,
  },
  showEmailAliases: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update']);

const { t } = useI18n();

const FORM_CONFIG = {
  FIRST_NAME: { field: 'firstName' },
  LAST_NAME: { field: 'lastName' },
  EMAIL_ADDRESS: { field: 'email' },
  PHONE_NUMBER: { field: 'phoneNumber' },
  CITY: { field: 'additionalAttributes.city' },
  COUNTRY: { field: 'additionalAttributes.countryCode' },
  BIO: { field: 'additionalAttributes.description' },
  COMPANY_NAME: { field: 'additionalAttributes.companyName' },
};

const SOCIAL_CONFIG = {
  LINKEDIN: 'i-ri-linkedin-box-fill',
  FACEBOOK: 'i-ri-facebook-circle-fill',
  INSTAGRAM: 'i-ri-instagram-line',
  TELEGRAM: 'i-ri-telegram-fill',
  TIKTOK: 'i-ri-tiktok-fill',
  TWITTER: 'i-ri-twitter-x-fill',
  GITHUB: 'i-ri-github-fill',
};

const buildDefaultState = () => ({
  id: 0,
  name: '',
  email: '',
  emailAddresses: [],
  firstName: '',
  lastName: '',
  phoneNumber: '',
  additionalAttributes: {
    description: '',
    companyName: '',
    countryCode: '',
    country: '',
    city: '',
    socialProfiles: {
      facebook: '',
      github: '',
      instagram: '',
      telegram: '',
      tiktok: '',
      linkedin: '',
      twitter: '',
    },
  },
});

const state = reactive(buildDefaultState());

const cloneEmailAddresses = emailAddresses =>
  Array.isArray(emailAddresses)
    ? emailAddresses.map(row => ({
        email: row?.email?.toString() || '',
        primary: Boolean(row?.primary),
      }))
    : [];

const resolvePrimaryIndex = emailAddresses => {
  const primaryIndex = emailAddresses.findIndex(row => row.primary);
  return primaryIndex >= 0 ? primaryIndex : 0;
};

const buildInitialEmailAddresses = (emailAddress, emailAddresses) => {
  const clonedRows = cloneEmailAddresses(emailAddresses);
  if (clonedRows.length) {
    const primaryIndex = resolvePrimaryIndex(clonedRows);
    return clonedRows.map((row, index) => ({
      ...row,
      primary: index === primaryIndex,
    }));
  }

  return emailAddress ? [{ email: emailAddress, primary: true }] : [];
};

const primaryEmailFromAddresses = emailAddresses => {
  const primaryRow = cloneEmailAddresses(emailAddresses).find(
    row => row.primary
  );
  return primaryRow?.email || '';
};

const serializedEmailAddresses = emailAddresses => {
  const rows = cloneEmailAddresses(emailAddresses).filter(row =>
    row.email.trim()
  );
  if (!rows.length) return [];

  const primaryIndex = resolvePrimaryIndex(rows);

  return rows.map((row, index) => ({
    email: row.email.trim(),
    primary: index === primaryIndex,
  }));
};

const buildSerializableState = () => {
  const { firstName, lastName, ...stateWithoutNames } = state;
  const serializableState = {
    ...stateWithoutNames,
    additionalAttributes: {
      ...state.additionalAttributes,
      socialProfiles: {
        ...state.additionalAttributes.socialProfiles,
      },
    },
  };

  if (props.showEmailAliases) {
    serializableState.emailAddresses = serializedEmailAddresses(
      state.emailAddresses
    );
    serializableState.email =
      primaryEmailFromAddresses(serializableState.emailAddresses) || '';
  } else {
    delete serializableState.emailAddresses;
  }

  return serializableState;
};

const validationRules = {
  firstName: { required },
  email: { email },
};

const v$ = useVuelidate(validationRules, state);

const isFormInvalid = computed(() => v$.value.$invalid);
const shouldShowEmailAliases = computed(
  () => props.showEmailAliases && !props.isNewContact
);

const emitContactUpdate = () => {
  emit('update', buildSerializableState());
};

const prepareStateBasedOnProps = () => {
  if (props.isNewContact) {
    return; // Added to prevent state update for new contact form
  }

  const {
    id,
    name = '',
    email: emailAddress,
    emailAddresses = [],
    phoneNumber,
    additionalAttributes = {},
  } = props.contactData || {};
  const { firstName, lastName } = splitName(name || '');
  const {
    description = '',
    companyName = '',
    countryCode = '',
    country = '',
    city = '',
    socialTelegramUserName = '',
    socialProfiles = {},
  } = additionalAttributes || {};

  const telegramUsername =
    socialProfiles?.telegram || socialTelegramUserName || '';

  Object.assign(state, {
    id,
    name,
    firstName,
    lastName,
    email: emailAddress,
    emailAddresses: buildInitialEmailAddresses(emailAddress, emailAddresses),
    phoneNumber,
    additionalAttributes: {
      description,
      companyName,
      countryCode,
      country,
      city,
      socialProfiles: {
        ...socialProfiles,
        telegram: telegramUsername,
      },
    },
  });
};

const countryOptions = computed(() =>
  countries.map(({ name, id }) => ({ label: name, value: id }))
);

const editDetailsForm = computed(() =>
  Object.keys(FORM_CONFIG).map(key => ({
    key,
    placeholder: t(
      `CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.FORM.${key}.PLACEHOLDER`
    ),
  }))
);

const socialProfilesForm = computed(() =>
  Object.entries(SOCIAL_CONFIG).map(([key, icon]) => ({
    key,
    placeholder: t(`CONTACTS_LAYOUT.CARD.SOCIAL_MEDIA.FORM.${key}.PLACEHOLDER`),
    icon,
  }))
);

const isValidationField = key => {
  const field = FORM_CONFIG[key]?.field;
  return ['firstName', 'email'].includes(field);
};

const getValidationKey = key => {
  return FORM_CONFIG[key]?.field;
};

// Creates a computed property for two-way form field binding
const getFormBinding = key => {
  const field = FORM_CONFIG[key]?.field;
  if (!field) return null;

  return computed({
    get: () => {
      // Handle firstName/lastName fields
      if (field === 'firstName' || field === 'lastName') {
        return state[field]?.toString() || '';
      }

      // Handle nested vs non-nested fields
      const [base, nested] = field.split('.');
      // Example: 'email' → state.email
      // Example: 'additionalAttributes.city' → state.additionalAttributes.city
      return (nested ? state[base][nested] : state[base])?.toString() || '';
    },

    set: async value => {
      // Handle name fields specially to maintain the combined 'name' field
      if (field === 'firstName' || field === 'lastName') {
        state[field] = value;
        // Example: firstName="John", lastName="Doe" → name="John Doe"
        state.name = `${state.firstName} ${state.lastName}`.trim();
      } else if (field === 'email') {
        state.email = value;

        if (shouldShowEmailAliases.value) {
          const existingRows = cloneEmailAddresses(state.emailAddresses);
          const trimmedValue = value.trim();

          if (!trimmedValue) {
            const remainingAliases = existingRows.filter(row => !row.primary);

            if (remainingAliases.length) {
              state.emailAddresses = remainingAliases.map((row, index) => ({
                ...row,
                primary: index === 0,
              }));
              state.email = state.emailAddresses[0]?.email || '';
            } else {
              state.emailAddresses = [];
            }
          } else {
            const normalizedValue = trimmedValue.toLowerCase();
            const matchingRowIndex = existingRows.findIndex(
              row => row.email.trim().toLowerCase() === normalizedValue
            );

            if (matchingRowIndex >= 0) {
              state.emailAddresses = existingRows.map((row, index) => ({
                ...row,
                email: index === matchingRowIndex ? value : row.email,
                primary: index === matchingRowIndex,
              }));
            } else if (existingRows.length) {
              state.emailAddresses = [
                { email: value, primary: true },
                ...existingRows.map(row => ({ ...row, primary: false })),
              ];
            } else {
              state.emailAddresses = [{ email: value, primary: true }];
            }
          }
        }
      } else {
        // Handle nested vs non-nested fields
        const [base, nested] = field.split('.');
        if (nested) {
          // Example: additionalAttributes.city = "New York"
          state[base][nested] = value;
        } else {
          // Example: email = "test@example.com"
          state[base] = value;
        }
      }

      const isFormValid = await v$.value.$validate();
      if (isFormValid) {
        emitContactUpdate();
      }
    },
  });
};

const getMessageType = key => {
  return isValidationField(key) && v$.value[getValidationKey(key)]?.$error
    ? 'error'
    : 'info';
};

const handleCountrySelection = value => {
  const selectedCountry = countries.find(option => option.id === value);
  state.additionalAttributes.country = selectedCountry?.name || '';
  emitContactUpdate();
};

const resetValidation = () => {
  v$.value.$reset();
};

const resetForm = () => {
  Object.assign(state, buildDefaultState());
};

const handleEmailAddressesUpdate = async emailAddresses => {
  const nextEmailAddresses = cloneEmailAddresses(emailAddresses);
  const primaryIndex = nextEmailAddresses.length
    ? resolvePrimaryIndex(nextEmailAddresses)
    : -1;

  state.emailAddresses = nextEmailAddresses.map((row, index) => ({
    ...row,
    primary: primaryIndex >= 0 && index === primaryIndex,
  }));
  state.email =
    primaryIndex >= 0 ? state.emailAddresses[primaryIndex].email : '';

  const isFormValid = await v$.value.$validate();
  if (isFormValid) {
    emitContactUpdate();
  }
};

watch(
  () => props.contactData?.id,
  id => {
    if (id) prepareStateBasedOnProps();
  },
  { immediate: true }
);

// Expose state to parent component for avatar upload
defineExpose({
  state,
  resetValidation,
  isFormInvalid,
  resetForm,
  getSerializableState: buildSerializableState,
});
</script>

<template>
  <div class="flex flex-col gap-6">
    <div class="flex flex-col items-start gap-2">
      <span class="py-1 text-sm font-medium text-n-slate-12">
        {{ t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.TITLE') }}
      </span>
      <div class="grid w-full grid-cols-1 gap-4 sm:grid-cols-2">
        <template v-for="item in editDetailsForm" :key="item.key">
          <ComboBox
            v-if="item.key === 'COUNTRY'"
            v-model="state.additionalAttributes.countryCode"
            :options="countryOptions"
            :placeholder="item.placeholder"
            class="[&>div>button]:h-8"
            :class="{
              '[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:!outline-transparent':
                !isDetailsView,
              '[&>div>button]:!bg-n-alpha-black2': isDetailsView,
            }"
            @update:model-value="handleCountrySelection"
          />
          <PhoneNumberInput
            v-else-if="item.key === 'PHONE_NUMBER'"
            v-model="getFormBinding(item.key).value"
            :placeholder="item.placeholder"
            :show-border="isDetailsView"
          />
          <Input
            v-else
            v-model="getFormBinding(item.key).value"
            :placeholder="item.placeholder"
            :message-type="getMessageType(item.key)"
            :custom-input-class="`h-8 !pt-1 !pb-1 ${
              !isDetailsView
                ? '[&:not(.error,.focus)]:!outline-transparent'
                : ''
            }`"
            class="w-full"
            @input="
              isValidationField(item.key) &&
                v$[getValidationKey(item.key)].$touch()
            "
            @blur="
              isValidationField(item.key) &&
                v$[getValidationKey(item.key)].$touch()
            "
          />
        </template>
      </div>
      <ContactEmailFields
        v-if="shouldShowEmailAliases"
        :model-value="state.emailAddresses"
        class="mt-4"
        @update:model-value="handleEmailAddressesUpdate"
      />
    </div>
    <div class="flex flex-col items-start gap-2">
      <span class="py-1 text-sm font-medium text-n-slate-12">
        {{ t('CONTACTS_LAYOUT.CARD.SOCIAL_MEDIA.TITLE') }}
      </span>
      <div class="flex flex-wrap gap-2">
        <div
          v-for="item in socialProfilesForm"
          :key="item.key"
          class="flex items-center h-8 gap-2 px-2 rounded-lg"
          :class="{
            'bg-n-alpha-2 dark:bg-n-solid-2': isDetailsView,
            'bg-n-alpha-2 dark:bg-n-solid-3': !isDetailsView,
          }"
        >
          <Icon
            :icon="item.icon"
            class="flex-shrink-0 text-n-slate-11 size-4"
          />
          <input
            v-model="
              state.additionalAttributes.socialProfiles[item.key.toLowerCase()]
            "
            class="w-auto min-w-[100px] text-sm bg-transparent outline-none reset-base text-n-slate-12 dark:text-n-slate-12 placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10"
            :placeholder="item.placeholder"
            :size="item.placeholder.length"
            @input="emitContactUpdate"
          />
        </div>
      </div>
    </div>
  </div>
</template>
