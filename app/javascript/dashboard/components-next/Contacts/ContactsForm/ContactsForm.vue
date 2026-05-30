<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { required, email } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';
import { splitName } from '@chatwoot/utils';
import countries from 'shared/constants/countries.js';
import CompanyAPI from 'dashboard/api/companies';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
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
const { currentAccount, isCloudFeatureEnabled } = useAccount();

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

const defaultState = {
  id: 0,
  name: '',
  email: '',
  companyId: '',
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
};

const state = reactive({ ...defaultState });
const companyOptions = ref([]);
const companySearch = ref('');
let companySearchRequestToken = 0;

const validationRules = {
  firstName: { required },
  email: { email },
};

const v$ = useVuelidate(validationRules, state);

const isFormInvalid = computed(() => v$.value.$invalid);
const hasCompaniesFeature = computed(
  () =>
    currentAccount.value?.id && isCloudFeatureEnabled(FEATURE_FLAGS.COMPANIES)
);
const showCompanySelector = computed(
  () =>
    hasCompaniesFeature.value &&
    (Boolean(state.companyId) || !state.additionalAttributes.companyName)
);

const normalizeCompanyOptions = companies =>
  companies.map(company => ({
    label: company.name,
    value: company.id,
  }));

const selectedCompanyOption = computed(() => {
  const { companyId, additionalAttributes } = state;
  if (!companyId || !additionalAttributes.companyName) return null;

  return {
    label: additionalAttributes.companyName,
    value: Number(companyId),
  };
});

const ensureSelectedCompanyOption = options => {
  const selected = selectedCompanyOption.value;
  if (!selected || options.some(option => option.value === selected.value)) {
    return options;
  }

  return [selected, ...options];
};

const createCompanyOption = computed(() => {
  const name = companySearch.value.trim();
  if (!name) return null;

  const alreadyExists = companyOptions.value.some(
    option => option.label.toLowerCase() === name.toLowerCase()
  );
  if (alreadyExists) return null;

  return {
    label: t('COMPANIES.SELECTOR.CREATE_OPTION', { name }),
    value: `create:${name}`,
  };
});

const companySelectOptions = computed(() => {
  const createOption = createCompanyOption.value;
  return createOption
    ? [...companyOptions.value, createOption]
    : companyOptions.value;
});

const loadCompanyOptions = async query => {
  if (!hasCompaniesFeature.value) return;

  companySearch.value = query || '';
  const requestToken = companySearchRequestToken + 1;
  companySearchRequestToken = requestToken;

  try {
    const {
      data: { payload },
    } = query?.trim()
      ? await CompanyAPI.search(query)
      : await CompanyAPI.get({ page: 1 });

    if (companySearchRequestToken !== requestToken) return;
    companyOptions.value = ensureSelectedCompanyOption(
      normalizeCompanyOptions(payload || [])
    );
  } catch {
    if (companySearchRequestToken === requestToken) {
      companyOptions.value = ensureSelectedCompanyOption([]);
    }
  }
};

const emitContactUpdate = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) return;

  const { firstName, lastName, ...stateWithoutNames } = state;
  emit('update', stateWithoutNames);
};

const prepareStateBasedOnProps = () => {
  if (props.isNewContact) {
    return; // Added to prevent state update for new contact form
  }

  const {
    id,
    name = '',
    email: emailAddress,
    phoneNumber,
    companyId = '',
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
    companyId: companyId || '',
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

      await emitContactUpdate();
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

const selectCompany = async company => {
  state.companyId = company.id;
  state.additionalAttributes.companyName = company.name;
  companyOptions.value = ensureSelectedCompanyOption([
    { label: company.name, value: company.id },
    ...companyOptions.value,
  ]);

  await emitContactUpdate();
};

const createCompany = async name => {
  try {
    const {
      data: { payload },
    } = await CompanyAPI.create({ company: { name } });
    await selectCompany(payload);
    useAlert(t('COMPANIES.CREATE.MESSAGES.SUCCESS'));
  } catch {
    useAlert(t('COMPANIES.CREATE.MESSAGES.ERROR'));
  }
};

const handleCompanySelection = async value => {
  if (typeof value === 'string' && value.startsWith('create:')) {
    await createCompany(value.replace('create:', ''));
    return;
  }

  const companyId = value ? Number(value) : '';
  const selectedCompany = companyOptions.value.find(
    option => option.value === companyId
  );
  state.companyId = companyId;
  state.additionalAttributes.companyName = selectedCompany?.label || '';

  await emitContactUpdate();
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
    if (id) {
      prepareStateBasedOnProps();
      companyOptions.value = ensureSelectedCompanyOption(companyOptions.value);
    }
  },
  { immediate: true }
);

watch(
  hasCompaniesFeature,
  enabled => {
    if (enabled) loadCompanyOptions();
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
          <ComboBox
            v-else-if="item.key === 'COMPANY_NAME' && showCompanySelector"
            :model-value="state.companyId"
            :options="companySelectOptions"
            :placeholder="t('COMPANIES.SELECTOR.PLACEHOLDER')"
            :search-placeholder="t('COMPANIES.SEARCH_PLACEHOLDER')"
            use-api-results
            class="[&>div>button]:h-8"
            :class="{
              '[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:!outline-transparent':
                !isDetailsView,
              '[&>div>button]:!bg-n-alpha-black2': isDetailsView,
            }"
            @search="loadCompanyOptions"
            @update:model-value="handleCompanySelection"
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
