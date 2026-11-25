<script setup>
import { computed, ref, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { requestPairing } from 'dashboard/helper/whatsappPairingRequest';
import { required } from '@vuelidate/validators';
import { isPhoneE164OrEmpty } from 'shared/helpers/Validators';
import { isHttpUrl } from 'dashboard/helper/whatsappSession';

import NextButton from 'dashboard/components-next/button/Button.vue';
import SessionWhatsappField from './SessionWhatsappField.vue';

const props = defineProps({
  // The provider's entry in the catalog: its key, the fields its form asks for and what
  // it can do once connected. Owned by the page, so the form is a pure function of it.
  descriptor: { type: Object, required: true },
  mode: {
    type: String,
    default: 'create',
    validator: value => ['create', 'convert'].includes(value),
  },
  inbox: { type: Object, default: null },
});

const isConvertMode = computed(() => props.mode === 'convert');

const router = useRouter();
const store = useStore();
const { t } = useI18n();

const descriptor = computed(() => props.descriptor);
// Everything the provider asks for, in the order the server declared it. The catalog says
// which fields are advanced (optional, with a sane default, unused by most inboxes), and
// those sit behind the toggle whatever their type.
const fields = computed(() => descriptor.value?.fields ?? []);
const basicFields = computed(() => fields.value.filter(f => !f.advanced));
const advancedFields = computed(() => fields.value.filter(f => f.advanced));
const textFields = computed(() =>
  fields.value.filter(f => f.type !== 'boolean')
);

const inboxName = ref(isConvertMode.value ? props.inbox?.name || '' : '');
const phoneNumber = ref(
  isConvertMode.value ? props.inbox?.phone_number || '' : ''
);
const showAdvancedOptions = ref(false);
const fieldValues = ref({});

const emptyValue = field =>
  field.default ?? (field.type === 'boolean' ? false : '');

// An advanced field holding anything but its default is never left out of sight: a
// proxy set on the inbox, or one the server just refused, stays where it can be read.
const advancedFieldSet = computed(() =>
  advancedFields.value.some(
    field => (fieldValues.value[field.name] ?? '') !== emptyValue(field)
  )
);

// The form is rendered from a catalog that arrives over the network, so the values are
// seeded once it lands rather than at setup.
watch(
  descriptor,
  value => {
    if (!value) return;
    const existing = isConvertMode.value ? {} : props.inbox?.provider_config;
    fieldValues.value = Object.fromEntries(
      value.fields.map(field => [
        field.name,
        existing?.[field.name] ?? emptyValue(field),
      ])
    );
  },
  { immediate: true }
);

watch(
  advancedFieldSet,
  isSet => {
    if (isSet) showAdvancedOptions.value = true;
  },
  { immediate: true }
);

const uiFlags = computed(() => store.getters['inboxes/getUIFlags']);

const fieldRules = field => {
  const rules = {};
  if (field.required) rules.required = required;
  if (field.type === 'url')
    rules.isHttpUrl = value => !value || isHttpUrl(value);
  return rules;
};

const rules = computed(() => ({
  inboxName: { required },
  phoneNumber: { required, isPhoneE164OrEmpty },
  fieldValues: Object.fromEntries(
    textFields.value.map(field => [field.name, fieldRules(field)])
  ),
}));

const v$ = useVuelidate(rules, { inboxName, phoneNumber, fieldValues });

// Booleans carry no rules, so they have no entry under v$.fieldValues.
const fieldError = field => Boolean(v$.value.fieldValues[field.name]?.$error);
const touchField = field => v$.value.fieldValues[field.name]?.$touch();

const submit = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  const providerConfig = { ...fieldValues.value };

  try {
    if (isConvertMode.value) {
      await store.dispatch('inboxes/convertProvider', {
        inboxId: props.inbox.id,
        provider: props.descriptor.key,
        providerConfig,
      });

      useAlert(t('INBOX_MGMT.CONVERT.API.SUCCESS_MESSAGE'));
      // The inbox comes out of the conversion unpaired: the settings open the pairing.
      requestPairing(props.inbox.id);
      router.replace({
        name: 'settings_inbox_show',
        params: {
          accountId: router.currentRoute.value.params.accountId,
          inboxId: props.inbox.id,
        },
      });
      return;
    }

    const channel = await store.dispatch('inboxes/createChannel', {
      name: inboxName.value,
      channel: {
        type: 'whatsapp',
        phone_number: phoneNumber.value,
        provider: props.descriptor.key,
        provider_config: providerConfig,
      },
    });

    router.replace({
      name: 'settings_inboxes_add_agents',
      params: { page: 'new', inbox_id: channel.id },
    });
  } catch (error) {
    useAlert(
      error.message ||
        t(
          isConvertMode.value
            ? 'INBOX_MGMT.CONVERT.API.ERROR_MESSAGE'
            : 'INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE'
        )
    );
  }
};
</script>

<template>
  <form class="flex flex-wrap mx-0" @submit.prevent="submit()">
    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
      <label :class="{ error: v$.inboxName.$error }">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.LABEL') }}
        <input
          v-model="inboxName"
          type="text"
          :disabled="isConvertMode"
          :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.PLACEHOLDER')"
          @blur="v$.inboxName.$touch"
        />
        <span v-if="v$.inboxName.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.ERROR') }}
        </span>
      </label>
    </div>

    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
      <label :class="{ error: v$.phoneNumber.$error }">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.LABEL') }}
        <input
          v-model="phoneNumber"
          type="text"
          :disabled="isConvertMode"
          :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.PLACEHOLDER')"
          @blur="v$.phoneNumber.$touch"
        />
        <span v-if="v$.phoneNumber.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.ERROR') }}
        </span>
      </label>
    </div>

    <SessionWhatsappField
      v-for="field in basicFields"
      :key="field.name"
      v-model="fieldValues[field.name]"
      :field="field"
      :error="fieldError(field)"
      @blur="touchField(field)"
    />

    <div
      v-if="!showAdvancedOptions && advancedFields.length"
      class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%] mb-4"
    >
      <NextButton
        type="button"
        icon="i-lucide-plus"
        sm
        link
        @click="showAdvancedOptions = true"
      >
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.ADVANCED_OPTIONS') }}
      </NextButton>
    </div>
    <template v-else-if="advancedFields.length">
      <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
        <span class="text-sm text-gray-600">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.ADVANCED_OPTIONS') }}
        </span>
      </div>
      <SessionWhatsappField
        v-for="field in advancedFields"
        :key="field.name"
        v-model="fieldValues[field.name]"
        :field="field"
        :error="fieldError(field)"
        @blur="touchField(field)"
      />
    </template>

    <div class="w-full">
      <NextButton
        :is-loading="uiFlags.isCreating || uiFlags.isUpdating"
        type="submit"
        solid
        blue
        :label="
          isConvertMode
            ? $t('INBOX_MGMT.CONVERT.SUBMIT_BUTTON')
            : $t('INBOX_MGMT.ADD.WHATSAPP.SUBMIT_BUTTON')
        "
      />
    </div>
  </form>
</template>
