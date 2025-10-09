<script setup>
import { computed, reactive, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { required, email } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';
import { splitName } from '@chatwoot/utils';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
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
  isDetailsView: {
    type: Boolean,
    default: false,
  },
  isNewContact: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update']);

const { t } = useI18n();
const store = useStore();
const getters = useStoreGetters();

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
  customAttributes: {},
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
    customAttributes = {},
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
    customAttributes,
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

// Custom attributes
const contactAttributeDefinitions = computed(() => {
  const attributes =
    getters['attributes/getAttributesByModel'].value('contact_attribute');
  return attributes || [];
});

const customAttributesWithValues = computed(() => {
  if (
    !contactAttributeDefinitions.value ||
    contactAttributeDefinitions.value.length === 0
  ) {
    return [];
  }
  return contactAttributeDefinitions.value.map(attribute => ({
    ...attribute,
    value: state.customAttributes[attribute.attribute_key] || '',
  }));
});

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

const handleCustomAttributeUpdate = (key, value) => {
  state.customAttributes = {
    ...state.customAttributes,
    [key]: value,
  };
  emit('update', state);
};

watch(
  () => props.contactData?.id,
  id => {
    if (id) prepareStateBasedOnProps();
  },
  { immediate: true }
);

onMounted(async () => {
  await store.dispatch('attributes/get');
});

// Expose state to parent component for avatar upload
defineExpose({
  state,
  resetValidation,
  isFormInvalid,
  resetForm,
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
    </div>
    <div
      v-if="customAttributesWithValues.length > 0"
      class="flex flex-col items-start gap-2"
    >
      <span class="py-1 text-sm font-medium text-n-slate-12">
        {{ t('CONTACT_FORM.FORM.CUSTOM_ATTRIBUTES.LABEL') }}
      </span>
      <div class="grid w-full grid-cols-1 gap-4 sm:grid-cols-2">
        <template
          v-for="attribute in customAttributesWithValues"
          :key="attribute.attribute_key"
        >
          <div
            v-if="
              !attribute.attribute_display_type ||
              attribute.attribute_display_type === 'text' ||
              attribute.attribute_display_type === 'link'
            "
            class="flex flex-col gap-1"
          >
            <label class="text-xs font-medium text-n-slate-11">
              {{ attribute.attribute_display_name }}
            </label>
            <Input
              :model-value="attribute.value"
              :placeholder="attribute.attribute_display_name"
              message-type="info"
              :custom-input-class="`h-8 !pt-1 !pb-1 ${
                !isDetailsView
                  ? '[&:not(.error,.focus)]:!outline-transparent'
                  : ''
              }`"
              class="w-full"
              @update:model-value="
                value =>
                  handleCustomAttributeUpdate(attribute.attribute_key, value)
              "
            />
          </div>
          <div
            v-else-if="
              attribute.attribute_display_type === 'number' ||
              attribute.attribute_display_type === 'currency' ||
              attribute.attribute_display_type === 'percent'
            "
            class="flex flex-col gap-1"
          >
            <label class="text-xs font-medium text-n-slate-11">
              {{ attribute.attribute_display_name }}
            </label>
            <Input
              :model-value="attribute.value"
              type="number"
              :placeholder="attribute.attribute_display_name"
              message-type="info"
              :custom-input-class="`h-8 !pt-1 !pb-1 ${
                !isDetailsView
                  ? '[&:not(.error,.focus)]:!outline-transparent'
                  : ''
              }`"
              class="w-full"
              @update:model-value="
                value =>
                  handleCustomAttributeUpdate(attribute.attribute_key, value)
              "
            />
          </div>
          <div
            v-else-if="attribute.attribute_display_type === 'date'"
            class="flex flex-col gap-1"
          >
            <label class="text-xs font-medium text-n-slate-11">
              {{ attribute.attribute_display_name }}
            </label>
            <Input
              :model-value="attribute.value"
              type="date"
              :placeholder="attribute.attribute_display_name"
              message-type="info"
              :custom-input-class="`h-8 !pt-1 !pb-1 ${
                !isDetailsView
                  ? '[&:not(.error,.focus)]:!outline-transparent'
                  : ''
              }`"
              class="w-full"
              @update:model-value="
                value =>
                  handleCustomAttributeUpdate(attribute.attribute_key, value)
              "
            />
          </div>
          <div
            v-else-if="attribute.attribute_display_type === 'datetime'"
            class="flex flex-col gap-1"
          >
            <label class="text-xs font-medium text-n-slate-11">
              {{ attribute.attribute_display_name }}
            </label>
            <Input
              :model-value="attribute.value"
              type="datetime-local"
              :placeholder="attribute.attribute_display_name"
              message-type="info"
              :custom-input-class="`h-8 !pt-1 !pb-1 ${
                !isDetailsView
                  ? '[&:not(.error,.focus)]:!outline-transparent'
                  : ''
              }`"
              class="w-full"
              @update:model-value="
                value =>
                  handleCustomAttributeUpdate(attribute.attribute_key, value)
              "
            />
          </div>
          <div
            v-else-if="attribute.attribute_display_type === 'checkbox'"
            class="flex items-center h-8 gap-2"
          >
            <input
              :checked="attribute.value === true || attribute.value === 'true'"
              type="checkbox"
              class="w-4 h-4 rounded border-n-weak"
              @change="
                e =>
                  handleCustomAttributeUpdate(
                    attribute.attribute_key,
                    e.target.checked
                  )
              "
            />
            <label class="text-sm text-n-slate-12">
              {{ attribute.attribute_display_name }}
            </label>
          </div>
          <div
            v-else-if="
              attribute.attribute_display_type === 'list' &&
              attribute.attribute_values
            "
            class="flex flex-col gap-1"
          >
            <label class="text-xs font-medium text-n-slate-11">
              {{ attribute.attribute_display_name }}
            </label>
            <ComboBox
              :model-value="attribute.value"
              :options="
                attribute.attribute_values.map(v => ({ label: v, value: v }))
              "
              :placeholder="attribute.attribute_display_name"
              class="[&>div>button]:h-8"
              :class="{
                '[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:!outline-transparent':
                  !isDetailsView,
                '[&>div>button]:!bg-n-alpha-black2': isDetailsView,
              }"
              @update:model-value="
                value =>
                  handleCustomAttributeUpdate(attribute.attribute_key, value)
              "
            />
          </div>
          <div v-else class="flex flex-col gap-1">
            <label class="text-xs font-medium text-n-slate-11">
              {{ attribute.attribute_display_name }}
            </label>
            <Input
              :model-value="attribute.value"
              :placeholder="attribute.attribute_display_name"
              message-type="info"
              :custom-input-class="`h-8 !pt-1 !pb-1 ${
                !isDetailsView
                  ? '[&:not(.error,.focus)]:!outline-transparent'
                  : ''
              }`"
              class="w-full"
              @update:model-value="
                value =>
                  handleCustomAttributeUpdate(attribute.attribute_key, value)
              "
            />
          </div>
        </template>
      </div>
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
            @input="emit('update', state)"
          />
        </div>
      </div>
    </div>
  </div>
</template>
