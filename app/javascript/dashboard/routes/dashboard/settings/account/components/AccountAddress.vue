<script setup>
import { ref, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import AccountAPI from 'dashboard/api/account';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import NextInput from 'next/input/Input.vue';
import TextArea from 'next/textarea/TextArea.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const store = useStore();
const { currentAccount } = useAccount();

const isExpanded = ref(false);
const isSubmitting = ref(false);
const addressId = ref(null);
const fieldErrors = ref({});
const street = ref('');
const exteriorNumber = ref('');
const interiorNumber = ref('');
const neighborhood = ref('');
const postalCode = ref('');
const city = ref('');
const state = ref('');
const email = ref('');
const phone = ref('');
const webpage = ref('');
const establishmentSummary = ref('');

const hasRequiredFields = computed(() => {
  return (
    street.value &&
    exteriorNumber.value &&
    neighborhood.value &&
    postalCode.value &&
    city.value &&
    state.value
  );
});

const toggleExpanded = () => {
  isExpanded.value = !isExpanded.value;
};

watch(
  currentAccount,
  () => {
    const address = currentAccount.value?.account_address;
    if (address) {
      addressId.value = address.id;
      street.value = address.street || '';
      exteriorNumber.value = address.exterior_number || '';
      interiorNumber.value = address.interior_number || '';
      neighborhood.value = address.neighborhood || '';
      postalCode.value = address.postal_code || '';
      city.value = address.city || '';
      state.value = address.state || '';
      email.value = address.email || '';
      phone.value = address.phone || '';
      webpage.value = address.webpage || '';
      establishmentSummary.value = address.establishment_summary || '';
    }
  },
  { deep: true, immediate: true }
);

const fieldNameMap = {
  street: 'STREET',
  exterior_number: 'EXTERIOR_NUMBER',
  interior_number: 'INTERIOR_NUMBER',
  neighborhood: 'NEIGHBORHOOD',
  postal_code: 'POSTAL_CODE',
  city: 'CITY',
  state: 'STATE',
  email: 'EMAIL',
  phone: 'PHONE',
  webpage: 'WEBPAGE',
  establishment_summary: 'ESTABLISHMENT_SUMMARY',
};

const handleSubmit = async () => {
  fieldErrors.value = {};

  if (!hasRequiredFields.value) {
    useAlert(t('GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.ERROR'));
    return;
  }

  try {
    isSubmitting.value = true;
    const payload = {
      account_address: {
        id: addressId.value,
        street: street.value,
        exterior_number: exteriorNumber.value,
        interior_number: interiorNumber.value,
        neighborhood: neighborhood.value,
        postal_code: postalCode.value,
        city: city.value,
        state: state.value,
        email: email.value,
        phone: phone.value,
        webpage: webpage.value,
        establishment_summary: establishmentSummary.value,
      },
    };
    const response = await AccountAPI.update('', payload);
    store.commit('accounts/EDIT_ACCOUNT', response.data);
    useAlert(t('GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.API.SUCCESS'));
  } catch (error) {
    const errorData = error?.response?.data;

    if (errorData?.attributes?.length) {
      errorData.attributes.forEach(attr => {
        fieldErrors.value[attr] = true;
      });
      const fieldNames = errorData.attributes
        .map(attr => t(`GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.${fieldNameMap[attr] || attr.toUpperCase()}`))
        .join(', ');
      useAlert(`${errorData.message}: ${fieldNames}`);
    } else {
      useAlert(errorData?.message || t('GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.API.ERROR'));
    }
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <div class="grid grid-cols-1 pt-8 gap-5 border-t border-n-weak pb-8">
    <button
      type="button"
      class="w-full flex items-center justify-between text-left cursor-pointer group"
      @click="toggleExpanded"
    >
      <div class="flex-1">
        <h4 class="text-lg font-medium text-n-slate-12">
          {{ t('GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.TITLE') }}
        </h4>
        <p class="text-n-slate-11 text-sm mt-2">
          {{ t('GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.NOTE') }}
        </p>
      </div>
      <fluent-icon
        icon="chevron-down"
        size="20"
        class="ml-4 text-n-slate-11 transition-transform duration-200"
        :class="{ 'rotate-180': isExpanded }"
      />
    </button>

    <transition
      enter-active-class="transition-all duration-200 ease-out"
      leave-active-class="transition-all duration-200 ease-in"
      enter-from-class="opacity-0 max-h-0"
      enter-to-class="opacity-100 max-h-[2000px]"
      leave-from-class="opacity-100 max-h-[2000px]"
      leave-to-class="opacity-0 max-h-0"
    >
      <form
        v-show="isExpanded"
        class="grid gap-4 mt-4 overflow-hidden"
        @submit.prevent="handleSubmit"
      >
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <WithLabel :label="t('GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.STREET')">
            <NextInput
              v-model="street"
              type="text"
              class="w-full"
              :placeholder="
                t('GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.STREET_PLACEHOLDER')
              "
            />
          </WithLabel>
          <div class="grid grid-cols-2 gap-4">
            <WithLabel
              :label="t('GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.EXTERIOR_NUMBER')"
            >
              <NextInput
                v-model="exteriorNumber"
                type="text"
                class="w-full"
                :placeholder="
                  t(
                    'GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.EXTERIOR_NUMBER_PLACEHOLDER'
                  )
                "
              />
            </WithLabel>
            <WithLabel
              :label="t('GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.INTERIOR_NUMBER')"
            >
              <NextInput
                v-model="interiorNumber"
                type="text"
                class="w-full"
                :placeholder="
                  t(
                    'GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.INTERIOR_NUMBER_PLACEHOLDER'
                  )
                "
              />
            </WithLabel>
          </div>
        </div>

        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <WithLabel
            :label="t('GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.NEIGHBORHOOD')"
          >
            <NextInput
              v-model="neighborhood"
              type="text"
              class="w-full"
              :placeholder="
                t('GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.NEIGHBORHOOD_PLACEHOLDER')
              "
            />
          </WithLabel>
          <WithLabel
            :label="t('GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.POSTAL_CODE')"
          >
            <NextInput
              v-model="postalCode"
              type="text"
              class="w-full"
              :placeholder="
                t('GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.POSTAL_CODE_PLACEHOLDER')
              "
            />
          </WithLabel>
        </div>

        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <WithLabel :label="t('GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.CITY')">
            <NextInput
              v-model="city"
              type="text"
              class="w-full"
              :placeholder="
                t('GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.CITY_PLACEHOLDER')
              "
            />
          </WithLabel>
          <WithLabel :label="t('GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.STATE')">
            <NextInput
              v-model="state"
              type="text"
              class="w-full"
              :placeholder="
                t('GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.STATE_PLACEHOLDER')
              "
            />
          </WithLabel>
        </div>

        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <WithLabel
            :label="t('GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.EMAIL')"
            :has-error="fieldErrors.email"
          >
            <NextInput
              v-model="email"
              type="email"
              class="w-full"
              :message-type="fieldErrors.email ? 'error' : 'info'"
              :placeholder="
                t('GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.EMAIL_PLACEHOLDER')
              "
            />
          </WithLabel>
          <WithLabel
            :label="t('GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.PHONE')"
            :has-error="fieldErrors.phone"
          >
            <NextInput
              v-model="phone"
              type="tel"
              class="w-full"
              :message-type="fieldErrors.phone ? 'error' : 'info'"
              :placeholder="
                t('GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.PHONE_PLACEHOLDER')
              "
            />
          </WithLabel>
        </div>

        <WithLabel
          :label="t('GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.WEBPAGE')"
          :has-error="fieldErrors.webpage"
        >
          <NextInput
            v-model="webpage"
            type="url"
            class="w-full"
            :message-type="fieldErrors.webpage ? 'error' : 'info'"
            :placeholder="
              t('GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.WEBPAGE_PLACEHOLDER')
            "
          />
        </WithLabel>

        <WithLabel
          :label="t('GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.ESTABLISHMENT_SUMMARY')"
        >
          <TextArea
            v-model="establishmentSummary"
            class="w-full"
            :placeholder="
              t(
                'GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.ESTABLISHMENT_SUMMARY_PLACEHOLDER'
              )
            "
            rows="3"
          />
        </WithLabel>

        <div class="flex gap-2">
          <NextButton
            blue
            type="submit"
            :is-loading="isSubmitting"
            :label="t('GENERAL_SETTINGS.FORM.ACCOUNT_ADDRESS.UPDATE_BUTTON')"
          />
        </div>
      </form>
    </transition>
  </div>
</template>
