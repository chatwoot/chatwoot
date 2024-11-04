<script setup>
import { computed, reactive, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import countries from 'shared/constants/countries.js';
import Input from 'dashboard/components-next/input/Input.vue';
import ComboBox from 'dashboard/components-next/combobox/Combobox.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  contactData: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['update']);

const { t } = useI18n();

const FORM_CONFIG = {
  FIRST_NAME: { field: 'name' },
  LAST_NAME: { field: 'name' },
  EMAIL_ADDRESS: { field: 'email' },
  PHONE_NUMBER: { field: 'phone_number' },
  CITY: { field: 'additional_attributes.city' },
  COUNTRY: { field: 'additional_attributes.country' },
  BIO: { field: 'additional_attributes.description' },
  COMPANY_NAME: { field: 'additional_attributes.company_name' },
};

const SOCIAL_CONFIG = {
  FACEBOOK: 'i-ri-facebook-circle-fill',
  GITHUB: 'i-ri-github-fill',
  INSTAGRAM: 'i-ri-instagram-line',
  LINKEDIN: 'i-ri-linkedin-box-fill',
  TWITTER: 'i-ri-twitter-x-fill',
};

const defaultState = {
  id: 0,
  name: '',
  email: '',
  phone_number: '',
  additional_attributes: {
    description: '',
    company_name: '',
    country_code: '',
    country: '',
    city: '',
    social_profiles: {
      facebook: '',
      github: '',
      instagram: '',
      linkedin: '',
      twitter: '',
    },
  },
};

const state = reactive({ ...defaultState });

const updateState = () => {
  Object.assign(state, {
    id: props.contactData.id,
    name: props.contactData.name,
    email: props.contactData.email,
    phone_number: props.contactData.phoneNumber,
    additional_attributes: {
      ...state.additional_attributes,
      ...props.contactData.additionalAttributes,
      social_profiles: {
        ...state.additional_attributes.social_profiles,
        ...props.contactData.additionalAttributes?.social_profiles,
      },
    },
  });
};

const countryOptions = computed(() =>
  countries.map(({ name }) => ({ label: name, value: name }))
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

// Creates a computed property for form field binding based on FORM_CONFIG
const getFormBinding = key => {
  // Get field path from config
  // Example: FORM_CONFIG.name = { field: 'contact.name' }
  const field = FORM_CONFIG[key]?.field;
  if (!field) return null;

  return computed({
    // Get value from state
    // Example 1 (nested): field = 'contact.name' returns state.contact.name = "John Doe"
    // Example 2 (root): field = 'email' returns state.email = "john@example.com"
    get: () => {
      const [base, nested] = field.split('.');
      return nested ? state[base][nested] : state[base];
    },

    // Set value in state and emit update
    // Example 1 (nested): field = 'contact.name', value = "Jane Doe" → state.contact.name = "Jane Doe"
    // Example 2 (root): field = 'email', value = "jane@example.com" → state.email = "jane@example.com"
    set: value => {
      const [base, nested] = field.split('.');
      if (nested) {
        state[base][nested] = value;
      } else {
        state[base] = value;
      }
      emit('update', state);
    },
  });
};

watch(() => props.contactData, updateState, { immediate: true, deep: true });
</script>

<template>
  <div class="flex flex-col">
    <div class="flex flex-col items-start gap-2 px-6 py-5">
      <span class="py-1 text-sm font-medium text-n-slate-12">
        {{ t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.TITLE') }}
      </span>
      <div class="grid w-full grid-cols-2 gap-4">
        <template v-for="item in editDetailsForm" :key="item.key">
          <ComboBox
            v-if="item.key === 'COUNTRY'"
            v-model="state.additional_attributes.country"
            :options="countryOptions"
            :placeholder="item.placeholder"
            class="[&>div>button]:bg-n-alpha-black2 [&>div>button]:!outline-transparent [&>div>button]:h-8"
            @update:model-value="emit('update', state)"
          />
          <Input
            v-else
            v-model="getFormBinding(item.key).value"
            :placeholder="item.placeholder"
            custom-input-class="!border-transparent h-8 !py-1"
            class="w-full"
          />
        </template>
      </div>
    </div>
    <div class="flex flex-col items-start gap-2 px-6 pb-5">
      <span class="py-1 text-sm font-medium text-n-slate-12">
        {{ t('CONTACTS_LAYOUT.CARD.SOCIAL_MEDIA.TITLE') }}
      </span>
      <div class="flex flex-wrap gap-2">
        <div
          v-for="item in socialProfilesForm"
          :key="item.key"
          class="flex items-center h-8 gap-2 px-2 rounded-lg bg-n-slate-2 dark:bg-n-solid-3"
        >
          <Icon
            :icon="item.icon"
            class="flex-shrink-0 text-n-slate-11 size-4"
          />
          <input
            v-model="
              state.additional_attributes.social_profiles[
                item.key.toLowerCase()
              ]
            "
            class="w-auto min-w-[100px] text-sm bg-transparent reset-base text-n-slate-12 dark:text-n-slate-12 placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10"
            :placeholder="item.placeholder"
            :size="item.placeholder.length"
            @input="emit('update', state)"
          />
        </div>
      </div>
    </div>
  </div>
</template>
