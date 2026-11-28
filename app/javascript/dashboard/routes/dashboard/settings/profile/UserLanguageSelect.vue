<script setup>
import { computed, useId } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useConfig } from 'dashboard/composables/useConfig';
import { useAccount } from 'dashboard/composables/useAccount';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { languageOption } from 'shared/helpers/languageSearch';

import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

defineProps({
  label: { type: String, default: '' },
  description: { type: String, default: '' },
});

const { t, locale } = useI18n();
const { updateUISettings, uiSettings } = useUISettings();
const { enabledLanguages } = useConfig();
const { currentAccount } = useAccount();

const languageLabelId = useId();
const currentLanguage = computed(() => uiSettings.value?.locale ?? '');

const languageOptions = computed(() => [
  {
    label: t(
      'PROFILE_SETTINGS.FORM.INTERFACE_SECTION.LANGUAGE.USE_ACCOUNT_DEFAULT'
    ),
    value: '',
  },
  ...(enabledLanguages ?? []).map(({ name, iso_639_1_code: code }) =>
    languageOption(name, code)
  ),
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
      <label
        :id="languageLabelId"
        class="text-n-gray-12 font-medium leading-6 text-sm"
      >
        {{ label }}
      </label>
      <p class="text-n-gray-11">
        {{ description }}
      </p>
    </div>
    <ComboBox
      v-model="selectedValue"
      :labelled-by="languageLabelId"
      class="!w-64 shrink-0 max-w-[50%] mt-px"
      :options="languageOptions"
      :allow-deselect="false"
      keyboard-navigation
    />
  </div>
</template>
