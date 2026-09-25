<script setup>
import { computed, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

import Button from 'dashboard/components-next/button/Button.vue';
import CompanyCustomAttributes from 'dashboard/components-next/Companies/CompanyDetail/CompanyCustomAttributes.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import SidePanel from 'dashboard/components-next/side-panel/SidePanel.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import { useCompaniesStore } from 'dashboard/stores/companies';

const props = defineProps({
  company: { type: Object, required: true },
});

const DESCRIPTION_MAX_LENGTH = 1000;
const SOCIAL_NETWORKS = [
  'linkedin',
  'x',
  'facebook',
  'instagram',
  'github',
  'youtube',
];

const { t } = useI18n();
const companiesStore = useCompaniesStore();
const panelRef = ref(null);

const form = reactive({
  name: '',
  domain: '',
  description: '',
  industry: '',
  employees: '',
  city: '',
  country: '',
  phone: '',
  socialProfiles: {},
});
const initialDetails = ref({});

const isUpdating = computed(() => companiesStore.getUIFlags.updatingItem);
const isFormInvalid = computed(() => !form.name.trim());

const socialLabels = computed(() => ({
  linkedin: t('COMPANIES.DETAIL.EDIT.SOCIAL.LINKEDIN'),
  x: t('COMPANIES.DETAIL.EDIT.SOCIAL.X'),
  facebook: t('COMPANIES.DETAIL.EDIT.SOCIAL.FACEBOOK'),
  instagram: t('COMPANIES.DETAIL.EDIT.SOCIAL.INSTAGRAM'),
  github: t('COMPANIES.DETAIL.EDIT.SOCIAL.GITHUB'),
  youtube: t('COMPANIES.DETAIL.EDIT.SOCIAL.YOUTUBE'),
}));

// Industry and employees show the most specific enriched value, so editing
// them replaces that value and clears the less specific one.
const readDetails = attributes => ({
  industry: attributes.sub_industry || attributes.industry || '',
  employees: String(
    attributes.employee_count || attributes.employee_count_range || ''
  ),
  city: attributes.city || '',
  country: attributes.country || '',
  phone: attributes.phone || '',
});

const open = () => {
  const attributes = props.company.additionalAttributes || {};
  const socialProfiles = attributes.social_profiles || {};
  initialDetails.value = readDetails(attributes);

  Object.assign(form, {
    name: props.company.name || '',
    domain: props.company.domain || '',
    description: props.company.description || '',
    ...initialDetails.value,
    socialProfiles: {
      ...Object.fromEntries(
        SOCIAL_NETWORKS.map(network => [network, socialProfiles[network] || ''])
      ),
      x: socialProfiles.x || socialProfiles.twitter || '',
    },
  });
  panelRef.value?.open();
};

const close = () => panelRef.value?.close();

const changed = field =>
  form[field].trim() !== initialDetails.value[field].trim();

const buildAdditionalAttributes = () => {
  const attributes = { ...(props.company.additionalAttributes || {}) };
  const assign = (key, value) => {
    if (value) attributes[key] = value;
    else delete attributes[key];
  };

  if (changed('industry')) {
    assign('industry', form.industry.trim());
    delete attributes.sub_industry;
  }
  if (changed('employees')) {
    assign('employee_count_range', form.employees.trim());
    delete attributes.employee_count;
  }
  if (changed('country')) delete attributes.country_code;
  assign('city', form.city.trim());
  assign('country', form.country.trim());
  assign('phone', form.phone.trim());

  const socialProfiles = Object.fromEntries(
    Object.entries(form.socialProfiles)
      .map(([network, url]) => [network, url.trim()])
      .filter(([, url]) => url)
  );
  delete attributes.social_profiles;
  if (Object.keys(socialProfiles).length) {
    attributes.social_profiles = socialProfiles;
  }

  return attributes;
};

const handleConfirm = async () => {
  if (isFormInvalid.value) return;

  try {
    await companiesStore.update({
      id: props.company.id,
      name: form.name.trim(),
      domain: form.domain.trim() || null,
      description: form.description.trim() || null,
      additionalAttributes: buildAdditionalAttributes(),
    });
    useAlert(t('COMPANIES.DETAIL.PROFILE.MESSAGES.UPDATE_SUCCESS'));
    close();
  } catch {
    useAlert(t('COMPANIES.DETAIL.PROFILE.MESSAGES.UPDATE_ERROR'));
  }
};

defineExpose({ open });
</script>

<template>
  <SidePanel
    ref="panelRef"
    width="2xl"
    :title="t('COMPANIES.DETAIL.EDIT.TITLE')"
  >
    <div class="flex flex-col gap-8">
      <section class="flex flex-col gap-4">
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <Input
            v-model="form.name"
            :label="t('COMPANIES.DETAIL.PROFILE.FIELDS.NAME')"
            :disabled="isUpdating"
            autofocus
          />
          <Input
            v-model="form.domain"
            :label="t('COMPANIES.DETAIL.PROFILE.FIELDS.DOMAIN')"
            :placeholder="t('COMPANIES.DETAIL.EDIT.PLACEHOLDERS.DOMAIN')"
            :disabled="isUpdating"
          />
        </div>
        <div class="flex flex-col gap-1">
          <label class="text-label text-n-slate-12">
            {{ t('COMPANIES.DETAIL.EDIT.DESCRIPTION') }}
          </label>
          <TextArea
            v-model="form.description"
            :placeholder="t('COMPANIES.DETAIL.PROFILE.DESCRIPTION_PLACEHOLDER')"
            :disabled="isUpdating"
            :max-length="DESCRIPTION_MAX_LENGTH"
            class="w-full"
            show-character-count
            auto-height
          />
        </div>
      </section>

      <section class="flex flex-col gap-4">
        <h4 class="mb-0 text-heading-3 text-n-slate-12">
          {{ t('COMPANIES.DETAIL.EDIT.DETAILS') }}
        </h4>
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <Input
            v-model="form.industry"
            :label="t('COMPANIES.DETAIL.FACTS.INDUSTRY')"
            :placeholder="t('COMPANIES.DETAIL.EDIT.PLACEHOLDERS.INDUSTRY')"
            :disabled="isUpdating"
          />
          <Input
            v-model="form.employees"
            :label="t('COMPANIES.DETAIL.FACTS.SIZE')"
            :placeholder="t('COMPANIES.DETAIL.EDIT.PLACEHOLDERS.EMPLOYEES')"
            :disabled="isUpdating"
          />
          <Input
            v-model="form.city"
            :label="t('COMPANIES.DETAIL.EDIT.CITY')"
            :disabled="isUpdating"
          />
          <Input
            v-model="form.country"
            :label="t('COMPANIES.DETAIL.EDIT.COUNTRY')"
            :disabled="isUpdating"
          />
          <Input
            v-model="form.phone"
            :label="t('COMPANIES.DETAIL.EDIT.PHONE')"
            type="tel"
            :disabled="isUpdating"
          />
        </div>
      </section>

      <section class="flex flex-col gap-4">
        <h4 class="mb-0 text-heading-3 text-n-slate-12">
          {{ t('COMPANIES.DETAIL.EDIT.SOCIAL.TITLE') }}
        </h4>
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <Input
            v-for="network in SOCIAL_NETWORKS"
            :key="network"
            v-model="form.socialProfiles[network]"
            :label="socialLabels[network]"
            type="url"
            :placeholder="t('COMPANIES.DETAIL.EDIT.PLACEHOLDERS.URL')"
            :disabled="isUpdating"
          />
        </div>
      </section>

      <section class="flex flex-col gap-4">
        <h4 class="mb-0 text-heading-3 text-n-slate-12">
          {{ t('COMPANIES.DETAIL.ATTRIBUTES.TITLE') }}
        </h4>
        <CompanyCustomAttributes :company="company" />
      </section>
    </div>

    <template #footer>
      <div class="flex items-center justify-end w-full gap-3">
        <Button
          :label="t('DIALOG.BUTTONS.CANCEL')"
          variant="faded"
          color="slate"
          type="button"
          @click="close"
        />
        <Button
          :label="t('COMPANIES.DETAIL.EDIT.SAVE')"
          color="blue"
          type="button"
          :disabled="isFormInvalid || isUpdating"
          :is-loading="isUpdating"
          @click="handleConfirm"
        />
      </div>
    </template>
  </SidePanel>
</template>
