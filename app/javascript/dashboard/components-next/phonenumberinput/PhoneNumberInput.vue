<script setup>
import { ref, computed, watch } from 'vue';
import { parsePhoneNumberFromString } from 'libphonenumber-js';
import { formatAsYouTypeInput } from 'shared/helpers/PhoneNumberHelper';
import { useI18n } from 'vue-i18n';
import countries from 'shared/constants/countries.js';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import {
  getActiveCountryCode,
  getActiveDialCode,
} from 'shared/components/PhoneInput/helper';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  placeholder: {
    type: String,
    default: '',
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  showBorder: {
    type: Boolean,
    default: true,
  },
});

const modelValue = defineModel({
  type: [String, Number],
  default: '',
});

const { t } = useI18n();

const showDropdown = ref(false);
const searchQuery = ref('');
const activeCountryCode = ref(getActiveCountryCode());
const activeDialCode = ref(getActiveDialCode());
const phoneNumber = ref('');

const rules = {
  phoneNumber: {
    minLength: minLength(2),
    validFormat: value => !value || /^[\d\s()+-]+$/.test(value),
  },
  activeDialCode: {
    required,
    validDialCode: value => {
      return countries.some(country => country.dial_code === value);
    },
  },
};

const v$ = useVuelidate(rules, {
  phoneNumber,
  activeDialCode,
});

const hasError = computed(() => v$.value.$invalid);

const countryList = computed(() => {
  return countries.map(country => ({
    value: country.id,
    label: country.name,
    dialCode: country.dial_code,
    emoji: country.emoji,
    isSelected: String(activeCountryCode.value) === String(country.id),
    action: 'phoneNumberInput',
  }));
});

const filteredCountries = computed(() => {
  const query = searchQuery.value.toLowerCase();
  return countryList.value.filter(({ label, dialCode, value }) =>
    [label, dialCode, value].some(field => field.toLowerCase().includes(query))
  );
});

const activeCountry = computed(() =>
  activeCountryCode.value
    ? countryList.value.find(
        country => country.value === activeCountryCode.value
      )
    : ''
);

const inputBorderClass = computed(() => {
  const errorClass =
    'outline-n-ruby-8 dark:outline-n-ruby-8 hover:outline-n-ruby-9 dark:hover:outline-n-ruby-9 disabled:outline-n-ruby-8 dark:disabled:outline-n-ruby-8';
  const focusClass =
    'has-[:focus]:outline-n-brand dark:has-[:focus]:outline-n-brand';

  if (!props.showBorder) {
    if (hasError.value) return errorClass;
    return `outline-transparent ${focusClass}`;
  }

  if (hasError.value) {
    return errorClass;
  }
  return `${focusClass} outline-n-weak dark:outline-n-weak hover:outline-n-slate-6 dark:hover:outline-n-slate-6 disabled:outline-n-weak dark:disabled:outline-n-weak`;
});

const phoneNumberError = computed(() => {
  if (!v$.value.$dirty) return '';
  return v$.value.activeDialCode.$invalid
    ? t('PHONE_INPUT.DIAL_CODE_ERROR')
    : v$.value.phoneNumber.$invalid && t('PHONE_INPUT.ERROR');
});

const emitPhoneNumber = value => {
  const cleanDigits = (value || '').replace(/\D/g, '');
  const newValue = cleanDigits ? `${activeDialCode.value}${cleanDigits}` : '';
  modelValue.value = newValue;
};

const onSelectCountry = async ({ value, dialCode }) => {
  if (!value || !showDropdown.value) return;

  activeCountryCode.value = value;
  activeDialCode.value = dialCode;
  searchQuery.value = '';
  showDropdown.value = false;
  if (phoneNumber.value) {
    if (!/^[\d\s()+-]*$/.test(phoneNumber.value)) {
      await v$.value.$touch();
      return;
    }
    phoneNumber.value = formatAsYouTypeInput(
      dialCode,
      value,
      phoneNumber.value
    );
  }
  if (!v$.value.$invalid && phoneNumber.value) {
    emitPhoneNumber(phoneNumber.value);
  }
};

const toggleCountryDropdown = () => {
  showDropdown.value = !showDropdown.value;
};

const closeCountryDropdown = () => {
  showDropdown.value = false;
};

watch(phoneNumber, async value => {
  if (!value) {
    emitPhoneNumber('');
    return;
  }

  // Prevent formatters from silently stripping invalid characters (e.g., 1-800-FLOWERS)
  // Let invalid characters remain so Vuelidate triggers the format validation error.
  const hasInvalidCharacters = !/^[\d\s()+-]*$/.test(value);
  if (hasInvalidCharacters) {
    await v$.value.$touch();
    return;
  }

  if (value.startsWith('+')) {
    const parsed = parsePhoneNumberFromString(value);
    if (parsed && parsed.country && parsed.countryCallingCode) {
      activeCountryCode.value = parsed.country;
      activeDialCode.value = `+${parsed.countryCallingCode}`;
      const raw = value.replace(`+${parsed.countryCallingCode}`, '').trim();
      phoneNumber.value = formatAsYouTypeInput(
        `+${parsed.countryCallingCode}`,
        parsed.country,
        raw
      );
      return;
    }
  }

  const formatted = formatAsYouTypeInput(
    activeDialCode.value,
    activeCountryCode.value,
    value
  );
  if (formatted !== value) {
    phoneNumber.value = formatted;
    return;
  }
  await v$.value.$touch();
  if (!v$.value.$invalid) {
    emitPhoneNumber(value);
  }
});

watch(
  modelValue,
  newValue => {
    if (!newValue) {
      phoneNumber.value = '';
      return;
    }
    const number = parsePhoneNumberFromString(newValue);
    if (number) {
      if (number?.country) activeCountryCode.value = number.country;
      if (number?.countryCallingCode)
        activeDialCode.value = `+${number.countryCallingCode}`;
      const raw = newValue.replace(`+${number.countryCallingCode}`, '');
      const formatted = formatAsYouTypeInput(
        `+${number.countryCallingCode}`,
        number.country,
        raw
      );
      if (phoneNumber.value !== formatted) {
        phoneNumber.value = formatted;
      }
    }
  },
  { immediate: true }
);
</script>

<template>
  <div>
    <div
      v-on-clickaway="() => closeCountryDropdown()"
      class="relative flex items-center h-8 transition-all duration-500 ease-in-out outline outline-1 outline-offset-[-1px] rounded-lg bg-n-alpha-black2"
      :class="[inputBorderClass, { 'cursor-not-allowed opacity-50': disabled }]"
    >
      <Input
        v-model="phoneNumber"
        type="tel"
        :placeholder="placeholder"
        :disabled="disabled"
        custom-input-class="!border-0 !outline-none h-8 !py-0.5 !bg-transparent ltr:!pl-1 rtl:!pr-1"
        class="w-full !flex-row"
      >
        <template #prefix>
          <div class="flex items-center flex-shrink-0">
            <Button
              :label="activeCountry?.emoji || ''"
              color="slate"
              size="sm"
              :icon="
                !activeCountry ? 'i-lucide-globe' : 'i-lucide-chevron-down'
              "
              trailing-icon
              :disabled="disabled"
              type="button"
              class="!h-[1.875rem] top-1 ltr:ml-px rtl:mr-px !px-2 outline-0 !outline-none !rounded-lg border-0 ltr:!rounded-r-none rtl:!rounded-l-none"
              @click="toggleCountryDropdown"
            >
              <span
                v-if="activeCountry"
                class="inline-flex justify-center text-sm whitespace-nowrap"
              >
                {{ activeCountry?.emoji }}
              </span>
            </Button>
            <span
              v-if="activeCountry"
              class="text-sm left-[38px] top-2.5 text-n-slate-11 ltr:!pl-1 rtl:!pr-1"
            >
              {{ activeDialCode }}
            </span>
          </div>
        </template>
      </Input>
      <DropdownMenu
        v-if="showDropdown"
        :menu-items="filteredCountries"
        show-search
        class="z-[100] w-48 mt-2 ltr:left-0 rtl:right-0 top-full max-h-52"
        @action="onSelectCountry"
      />
    </div>
    <template v-if="phoneNumberError">
      <p
        v-if="phoneNumberError"
        class="min-w-0 mt-1 mb-0 text-xs truncate transition-all duration-500 ease-in-out text-n-ruby-9 dark:text-n-ruby-9"
      >
        {{ phoneNumberError }}
      </p>
    </template>
  </div>
</template>
