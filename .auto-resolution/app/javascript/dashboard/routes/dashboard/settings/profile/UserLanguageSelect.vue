<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useConfig } from 'dashboard/composables/useConfig';
import { useAccount } from 'dashboard/composables/useAccount';
import { useUISettings } from 'dashboard/composables/useUISettings';

import FormSelect from 'v3/components/Form/Select.vue';

defineProps({
  label: { type: String, default: '' },
  description: { type: String, default: '' },
});

const { t, locale } = useI18n();
const { updateUISettings, uiSettings } = useUISettings();
const { enabledLanguages } = useConfig();
const { currentAccount } = useAccount();

const currentLanguage = computed(() => uiSettings.value?.locale ?? '');

const languageOptions = computed(() => [
  {
    name: t(
      'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.LANGUAGE.USE_ACCOUNT_DEFAULT'
    ),
    iso_639_1_code: '',
  },
  ...(enabledLanguages ?? []),
]);

const updateLanguage = async languageCode => {
  try {
    if (!languageCode) {
      // Clear preference to use account default
      await updateUISettings({ locale: null });
      locale.value = currentAccount.value.locale;
      useAlert(
        t('PROFILE_SETTINGS.FORM.INTERFACE_SECTION.LANGUAGE.UPDATE_SUCCESS')
      );
      return;
    }

    const valid = (enabledLanguages || []).some(
      l => l.iso_639_1_code === languageCode
    );
    if (!valid) {
      throw new Error(`Invalid language code: ${languageCode}`);
    }

    await updateUISettings({ locale: languageCode });
    // Apply immediately if the user explicitly chose a preference
    locale.value = languageCode;

    useAlert(
      t('PROFILE_SETTINGS.FORM.INTERFACE_SECTION.LANGUAGE.UPDATE_SUCCESS')
    );
  } catch (error) {
    useAlert(
      t('PROFILE_SETTINGS.FORM.INTERFACE_SECTION.LANGUAGE.UPDATE_ERROR')
    );
    throw error;
  }
};

const selectedValue = computed({
  get: () => currentLanguage.value,
  set: value => {
    updateLanguage(value);
  },
});
</script>

<template>
  <div class="flex gap-2 justify-between w-full items-start">
    <div>
      <label class="text-n-gray-12 font-medium leading-6 text-sm">
        {{ label }}
      </label>
      <p class="text-n-gray-11">
        {{ description }}
      </p>
    </div>
    <FormSelect
      v-model="selectedValue"
      name="language"
      spacing="compact"
      class="min-w-28 mt-px"
      :options="languageOptions"
      label=""
    >
      <option
        v-for="option in languageOptions"
        :key="option.iso_639_1_code || 'default'"
        :value="option.iso_639_1_code"
        :selected="option.iso_639_1_code === selectedValue"
      >
        {{ option.name }}
      </option>
    </FormSelect>
  </div>
</template>
