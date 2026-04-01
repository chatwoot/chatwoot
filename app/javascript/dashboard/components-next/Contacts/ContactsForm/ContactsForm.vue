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

const props = defineProps({
  contactData: {
    type: Object,
    default: null,
  },
  isNewContact: {
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
  TIKTOK: 'i-ri-tiktok-fill',
  TWITTER: 'i-ri-twitter-x-fill',
  GITHUB: 'i-ri-github-fill',
};

const defaultState = {
  id: 0,
  name: '',
  email: '',
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
      tiktok: '',
      linkedin: '',
      twitter: '',
    },
  },
};

const state = reactive({ ...defaultState });

const validationRules = {
  firstName: { required },
  email: { email },
};

const v$ = useVuelidate(validationRules, state);

const isFormInvalid = computed(() => v$.value.$invalid);

const prepareStateBasedOnProps = () => {
  if (props.isNewContact) {
    return; // Added to prevent state update for new contact form
  }

  const {
    id,
    name = '',
    email: emailAddress,
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
    socialProfiles = {},
  } = additionalAttributes || {};

  Object.assign(state, {
    id,
    name,
    firstName,
    lastName,
    email: emailAddress,
    phoneNumber,
    additionalAttributes: {
      description,
      companyName,
      countryCode,
      country,
      city,
      socialProfiles,
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
        const { firstName, lastName, ...stateWithoutNames } = state;
        emit('update', stateWithoutNames);
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
  emit('update', state);
};

const resetValidation = () => {
  v$.value.$reset();
};

const resetForm = () => {
  Object.assign(state, defaultState);
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
});
</script>

<template>
  <div class="flex flex-col gap-8">
    <section
      class="space-y-6 rounded-xl border border-outline-variant/5 bg-surface-container-low p-6 shadow-sm"
    >
      <h3
        class="mb-0 flex items-center gap-2 text-lg font-semibold text-on-surface"
      >
        <Icon
          icon="i-lucide-user-round"
          class="size-5 shrink-0 text-secondary"
        />
        {{ t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.TITLE') }}
      </h3>
      <div class="grid w-full grid-cols-1 gap-6 sm:grid-cols-2">
        <template v-for="item in editDetailsForm" :key="item.key">
          <ComboBox
            v-if="item.key === 'COUNTRY'"
            v-model="state.additionalAttributes.countryCode"
            :options="countryOptions"
            :placeholder="item.placeholder"
            class="w-full"
            @update:model-value="handleCountrySelection"
          />
          <PhoneNumberInput
            v-else-if="item.key === 'PHONE_NUMBER'"
            v-model="getFormBinding(item.key).value"
            :placeholder="item.placeholder"
            show-border
          />
          <Input
            v-else
            v-model="getFormBinding(item.key).value"
            :placeholder="item.placeholder"
            :message-type="getMessageType(item.key)"
            custom-input-class="!px-4"
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
    </section>
    <section
      class="space-y-4 rounded-xl border border-outline-variant/5 bg-surface-container-low p-6 shadow-sm"
    >
      <h3
        class="mb-0 flex items-center gap-2 text-lg font-semibold text-on-surface"
      >
        <Icon icon="i-lucide-link-2" class="size-5 shrink-0 text-secondary" />
        {{ t('CONTACTS_LAYOUT.CARD.SOCIAL_MEDIA.TITLE') }}
      </h3>
      <div class="flex flex-wrap gap-2">
        <div
          v-for="item in socialProfilesForm"
          :key="item.key"
          class="flex h-9 items-center gap-2 rounded-lg border border-outline-variant/10 bg-surface-container-lowest px-2.5"
        >
          <Icon
            :icon="item.icon"
            class="size-4 shrink-0 text-on-surface-variant"
          />
          <input
            v-model="
              state.additionalAttributes.socialProfiles[item.key.toLowerCase()]
            "
            class="reset-base min-w-[100px] w-auto bg-transparent text-sm text-on-surface outline-none placeholder:text-on-surface-variant/70"
            :placeholder="item.placeholder"
            :size="item.placeholder.length"
            @input="emit('update', state)"
          />
        </div>
      </div>
    </section>
  </div>
</template>
