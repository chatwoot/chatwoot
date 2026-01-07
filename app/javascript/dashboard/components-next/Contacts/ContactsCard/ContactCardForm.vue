<script setup>
import { computed, reactive, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { required, email as emailValidator } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';
import { splitName } from '@chatwoot/utils';
import Input from 'dashboard/components-next/input/Input.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import PhoneNumberInput from 'dashboard/components-next/phonenumberinput/PhoneNumberInput.vue';
import CountryDropdown from 'dashboard/components-next/Countries/CountryDropdown.vue';
import CompaniesDropdown from 'dashboard/components-next/Companies/CompaniesDropdown.vue';
import AddContactNote from './AddContactNote.vue';
import ContactLabels from 'dashboard/components-next/Contacts/ContactLabels/ContactLabels.vue';

const props = defineProps({
  contactData: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['update']);

const { t } = useI18n();

const SOCIAL_CONFIG = {
  LINKEDIN: 'i-woot-linkedin',
  FACEBOOK: 'i-woot-facebook',
  INSTAGRAM: 'i-woot-instagram',
  TWITTER: 'i-woot-x',
  GITHUB: 'i-woot-github',
};

const formState = reactive({
  firstName: '',
  lastName: '',
  email: '',
  phoneNumber: '',
  city: '',
  countryCode: '',
  bio: '',
  companyName: '',
  companyId: null,
  socialProfiles: {
    facebook: '',
    github: '',
    instagram: '',
    linkedin: '',
    twitter: '',
  },
});

const validationRules = {
  firstName: { required },
  email: { email: emailValidator },
};

const v$ = useVuelidate(validationRules, formState);

const isFormInvalid = computed(() => v$.value.$invalid);

const prepareStateBasedOnProps = () => {
  const {
    name = '',
    email: emailAddress = '',
    phoneNumber: phone = '',
    additionalAttributes = {},
  } = props.contactData || {};

  const { firstName: fName, lastName: lName } = splitName(name || '');
  const {
    description = '',
    countryCode: country = '',
    city: cityName = '',
    socialProfiles: profiles = {},
    companyName: company = '',
  } = additionalAttributes || {};

  formState.firstName = fName;
  formState.lastName = lName;
  formState.email = emailAddress;
  formState.phoneNumber = phone || '';
  formState.city = cityName;
  formState.countryCode = country;
  formState.bio = description;
  formState.companyName = company;
  formState.socialProfiles = { ...formState.socialProfiles, ...profiles };
};

const socialProfilesForm = computed(() =>
  Object.entries(SOCIAL_CONFIG).map(([key, icon]) => ({
    key,
    placeholder: t(`CONTACTS_LAYOUT.CARD.SOCIAL_MEDIA.FORM.${key}.PLACEHOLDER`),
    icon,
  }))
);

const handleCompanyChange = company => {
  formState.companyName = company?.name || '';
};

const handleUpdate = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) return;

  const contactData = {
    name: `${formState.firstName} ${formState.lastName}`.trim(),
    email: formState.email,
    phoneNumber: formState.phoneNumber,
    additionalAttributes: {
      description: formState.bio,
      city: formState.city,
      countryCode: formState.countryCode,
      companyName: formState.companyName,
      socialProfiles: formState.socialProfiles,
    },
  };

  emit('update', contactData);
};

const resetValidation = () => {
  v$.value.$reset();
};

const resetForm = () => {
  Object.assign(formState, {
    firstName: '',
    lastName: '',
    email: '',
    phoneNumber: '',
    city: '',
    countryCode: '',
    bio: '',
    companyName: '',
    companyId: null,
    socialProfiles: {
      facebook: '',
      github: '',
      instagram: '',
      linkedin: '',
      twitter: '',
    },
  });
};

watch(
  () => props.contactData?.id,
  id => {
    if (id) prepareStateBasedOnProps();
  },
  { immediate: true }
);

defineExpose({
  resetValidation,
  isFormInvalid,
  resetForm,
  handleUpdate,
});
</script>

<template>
  <div class="flex flex-col">
    <AddContactNote :contact-id="contactData?.id" />

    <div class="flex flex-col items-start gap-4 pt-2 pb-3">
      <span
        class="py-1 text-heading-3 text-n-slate-12 z-10 h-6 bg-n-surface-1 inline-flex items-center gap-2"
      >
        <Icon
          icon="i-lucide-settings-2"
          class="size-4 text-n-slate-11 hidden lg:block"
        />
        {{ t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.TITLE') }}
      </span>

      <div
        class="lg:grid lg:grid-cols-[1fr_auto_1fr] flex flex-col items-start lg:items-center w-full gap-3 lg:px-6"
      >
        <div class="grid grid-cols-2 gap-2 min-w-0 w-full">
          <Input
            v-model="formState.firstName"
            :placeholder="
              t(
                'CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.FORM.FIRST_NAME.PLACEHOLDER'
              )
            "
            :message-type="v$.firstName.$error ? 'error' : 'info'"
            class="h-8 min-w-0"
            @input="v$.firstName.$touch()"
            @blur="v$.firstName.$touch()"
          />
          <Input
            v-model="formState.lastName"
            :placeholder="
              t(
                'CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.FORM.LAST_NAME.PLACEHOLDER'
              )
            "
            class="h-8 min-w-0"
          />
        </div>

        <div class="w-px h-3 bg-n-strong hidden lg:block" />

        <div class="grid grid-cols-3 gap-3 min-w-0 w-full">
          <CompaniesDropdown
            v-model="formState.companyId"
            :placeholder="
              t(
                'CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.FORM.COMPANY_NAME.PLACEHOLDER'
              )
            "
            :selected-company-name="formState.companyName"
            class="min-w-0"
            @change="handleCompanyChange"
          />
          <Input
            v-model="formState.city"
            :placeholder="
              t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.FORM.CITY.PLACEHOLDER')
            "
            class="h-8 min-w-0"
          />
          <CountryDropdown
            v-model="formState.countryCode"
            :placeholder="
              t(
                'CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.FORM.COUNTRY.PLACEHOLDER'
              )
            "
            class="min-w-0"
          />
        </div>
      </div>

      <div
        class="lg:grid lg:grid-cols-[1fr_auto_1fr] flex flex-col lg:items-center w-full gap-3 lg:px-6"
      >
        <div class="grid grid-cols-2 gap-2 min-w-0 w-full">
          <Input
            v-model="formState.email"
            type="email"
            :placeholder="
              t(
                'CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.FORM.EMAIL_ADDRESS.PLACEHOLDER'
              )
            "
            :message-type="v$.email.$error ? 'error' : 'info'"
            class="h-8 min-w-0 [&>input]:ltr:!pl-8 [&>input]:rtl:!pr-8"
            @input="v$.email.$touch()"
            @blur="v$.email.$touch()"
          >
            <template #prefix>
              <Icon
                icon="i-woot-mail"
                class="absolute -translate-y-1/2 text-n-slate-11 size-4 top-1/2 ltr:left-2.5 rtl:right-2.5"
              />
            </template>
          </Input>
          <PhoneNumberInput
            v-model="formState.phoneNumber"
            :placeholder="
              t(
                'CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.FORM.PHONE_NUMBER.PLACEHOLDER'
              )
            "
            class="min-w-0"
          />
        </div>

        <div class="w-px h-3 bg-n-strong hidden lg:block" />

        <Input
          v-model="formState.bio"
          :placeholder="
            t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.FORM.BIO.PLACEHOLDER')
          "
          class="h-8 min-w-0"
        />
      </div>

      <div v-if="contactData?.id" class="lg:px-6">
        <ContactLabels :contact-id="contactData.id" />
      </div>
    </div>

    <div class="flex flex-col items-start gap-4 py-2">
      <span
        class="py-1 text-heading-3 text-n-slate-12 z-10 h-6 bg-n-surface-1 inline-flex items-center gap-2"
      >
        <Icon
          icon="i-lucide-globe"
          class="size-4 text-n-slate-11 hidden lg:block"
        />
        {{ t('CONTACTS_LAYOUT.CARD.SOCIAL_MEDIA.TITLE') }}
      </span>
      <div class="flex flex-wrap gap-2 lg:px-6">
        <div
          v-for="item in socialProfilesForm"
          :key="item.key"
          class="flex items-center h-8 gap-2 px-2 rounded-lg bg-n-alpha-2 outline-1 outline outline-n-weak -outline-offset-1 dark:bg-n-solid-2 hover:outline-n-slate-6 transition-all duration-150"
        >
          <Icon
            :icon="item.icon"
            class="flex-shrink-0 text-n-slate-11 size-5"
          />
          <input
            v-model="formState.socialProfiles[item.key.toLowerCase()]"
            class="w-auto min-w-[100px] text-sm bg-transparent outline-none reset-base text-n-slate-12 dark:text-n-slate-12 placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10"
            :placeholder="item.placeholder"
            :size="item.placeholder.length"
          />
        </div>
      </div>
    </div>
  </div>
</template>
