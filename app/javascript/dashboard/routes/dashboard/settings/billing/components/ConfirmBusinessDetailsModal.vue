<script setup>
import { ref, computed, reactive } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, email } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import EnterpriseAccountAPI from 'dashboard/api/enterprise/account';

const props = defineProps({
  billingDetails: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['confirmed']);
const { t } = useI18n();

const dialogRef = ref(null);
const isLoading = ref(false);

const hasPreExistingData = computed(() => {
  return Boolean(
    props.billingDetails.business_name ||
      props.billingDetails.business_address ||
      props.billingDetails.billing_email
  );
});

const formValues = reactive({
  businessName: '',
  businessAddress: '',
  billingEmail: '',
});

const validationRules = computed(() => ({
  businessName: { required },
  businessAddress: { required },
  billingEmail: { required, email },
}));

const v$ = useVuelidate(validationRules, formValues);

const fieldKeyMap = {
  businessName: 'BUSINESS_NAME',
  businessAddress: 'BUSINESS_ADDRESS',
  billingEmail: 'BILLING_EMAIL',
};

const getErrorMessage = field => {
  const fieldState = v$.value[field];
  if (!fieldState || !fieldState.$error) return '';

  if (fieldState.required?.$invalid) {
    return t(
      `BILLING_SETTINGS.CONFIRM_BUSINESS.${fieldKeyMap[field]}.REQUIRED`
    );
  }
  if (fieldState.email?.$invalid) {
    return t('BILLING_SETTINGS.CONFIRM_BUSINESS.BILLING_EMAIL.INVALID');
  }
  return '';
};

const open = () => {
  v$.value.$reset();
  formValues.businessName = props.billingDetails.business_name || '';
  formValues.businessAddress = props.billingDetails.business_address || '';
  formValues.billingEmail = props.billingDetails.billing_email || '';
  dialogRef.value?.open();
};

const close = () => {
  dialogRef.value?.close();
};

const handleConfirm = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  isLoading.value = true;
  try {
    const { data } = await EnterpriseAccountAPI.confirmBillingDetails({
      businessName: formValues.businessName,
      businessAddress: formValues.businessAddress,
      billingEmail: formValues.billingEmail,
    });
    emit('confirmed', data.redirect_url);
    close();
  } catch {
    useAlert(t('BILLING_SETTINGS.CONFIRM_BUSINESS.ERROR'));
  } finally {
    isLoading.value = false;
  }
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="$t('BILLING_SETTINGS.CONFIRM_BUSINESS.TITLE')"
    :description="$t('BILLING_SETTINGS.CONFIRM_BUSINESS.DESCRIPTION')"
    :show-confirm-button="false"
    :show-cancel-button="false"
    width="lg"
  >
    <div class="flex flex-col gap-4">
      <div
        v-if="hasPreExistingData"
        class="flex items-center gap-3 p-3 rounded-lg bg-n-teal-2 border border-n-teal-6"
      >
        <fluent-icon
          icon="checkmark-circle"
          size="18"
          class="text-n-teal-11 shrink-0"
        />
        <p class="text-sm text-n-teal-11">
          {{ $t('BILLING_SETTINGS.CONFIRM_BUSINESS.PREFILLED_BANNER') }}
        </p>
      </div>

      <div>
        <label class="mb-1 text-heading-3 text-n-slate-12">
          {{ $t('BILLING_SETTINGS.CONFIRM_BUSINESS.BUSINESS_NAME.LABEL') }}
          <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
          <span class="text-n-ruby-9">*</span>
        </label>
        <Input
          v-model="formValues.businessName"
          :placeholder="
            $t('BILLING_SETTINGS.CONFIRM_BUSINESS.BUSINESS_NAME.PLACEHOLDER')
          "
          :message="getErrorMessage('businessName')"
          :message-type="v$.businessName.$error ? 'error' : 'info'"
          @blur="v$.businessName.$touch"
        />
      </div>

      <div>
        <label class="mb-1 text-heading-3 text-n-slate-12">
          {{ $t('BILLING_SETTINGS.CONFIRM_BUSINESS.BUSINESS_ADDRESS.LABEL') }}
          <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
          <span class="text-n-ruby-9">*</span>
        </label>
        <TextArea
          v-model="formValues.businessAddress"
          :placeholder="
            $t('BILLING_SETTINGS.CONFIRM_BUSINESS.BUSINESS_ADDRESS.PLACEHOLDER')
          "
          :message="getErrorMessage('businessAddress')"
          :message-type="v$.businessAddress.$error ? 'error' : 'info'"
          :max-length="500"
          min-height="5rem"
          max-height="8rem"
          @blur="v$.businessAddress.$touch"
        />
      </div>

      <div>
        <label class="mb-1 text-heading-3 text-n-slate-12">
          {{ $t('BILLING_SETTINGS.CONFIRM_BUSINESS.BILLING_EMAIL.LABEL') }}
          <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
          <span class="text-n-ruby-9">*</span>
        </label>
        <Input
          v-model="formValues.billingEmail"
          type="email"
          :placeholder="
            $t('BILLING_SETTINGS.CONFIRM_BUSINESS.BILLING_EMAIL.PLACEHOLDER')
          "
          :message="getErrorMessage('billingEmail')"
          :message-type="v$.billingEmail.$error ? 'error' : 'info'"
          @blur="v$.billingEmail.$touch"
        />
        <p v-if="!v$.billingEmail.$error" class="mt-1 text-xs text-n-slate-10">
          {{ $t('BILLING_SETTINGS.CONFIRM_BUSINESS.BILLING_EMAIL.HELP_TEXT') }}
        </p>
      </div>
    </div>

    <template #footer>
      <div class="flex items-center justify-between w-full gap-3">
        <Button
          variant="faded"
          color="slate"
          :label="$t('BILLING_SETTINGS.CONFIRM_BUSINESS.CANCEL')"
          class="w-full"
          :disabled="isLoading"
          @click="close"
        />
        <Button
          color="blue"
          :label="$t('BILLING_SETTINGS.CONFIRM_BUSINESS.CONTINUE')"
          class="w-full"
          :is-loading="isLoading"
          @click="handleConfirm"
        />
      </div>
    </template>
  </Dialog>
</template>
