<script setup>
import { computed, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { requestPairing } from 'dashboard/helper/whatsappPairingRequest';
import { required } from '@vuelidate/validators';
import { isPhoneE164OrEmpty } from 'shared/helpers/Validators';

import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  mode: {
    type: String,
    default: 'create',
    validator: value => ['create', 'convert'].includes(value),
  },
  inbox: {
    type: Object,
    default: null,
  },
});

const isConvertMode = computed(() => props.mode === 'convert');

const router = useRouter();
const store = useStore();
const { t } = useI18n();

const inboxName = ref(isConvertMode.value ? props.inbox?.name || '' : '');
const phoneNumber = ref(
  isConvertMode.value ? props.inbox?.phone_number || '' : ''
);
const instanceId = ref('');
const token = ref('');
const clientToken = ref('');

const uiFlags = computed(() => store.getters['inboxes/getUIFlags']);

const rules = computed(() => ({
  inboxName: { required },
  phoneNumber: { required, isPhoneE164OrEmpty },
  instanceId: { required },
  token: { required },
  clientToken: { required },
}));

const v$ = useVuelidate(rules, {
  inboxName,
  phoneNumber,
  instanceId,
  token,
  clientToken,
});

const buildProviderConfig = () => ({
  instance_id: instanceId.value,
  token: token.value,
  client_token: clientToken.value,
});

const createChannel = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) {
    return;
  }

  try {
    if (isConvertMode.value) {
      await store.dispatch('inboxes/convertProvider', {
        inboxId: props.inbox.id,
        provider: 'zapi',
        providerConfig: buildProviderConfig(),
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

    const whatsappChannel = await store.dispatch('inboxes/createChannel', {
      name: inboxName.value,
      channel: {
        type: 'whatsapp',
        phone_number: phoneNumber.value,
        provider: 'zapi',
        provider_config: buildProviderConfig(),
      },
    });

    router.replace({
      name: 'settings_inboxes_add_agents',
      params: {
        page: 'new',
        inbox_id: whatsappChannel.id,
      },
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
  <form class="flex flex-wrap mx-0" @submit.prevent="createChannel()">
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

    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
      <label :class="{ error: v$.instanceId.$error }">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.INSTANCE_ID.LABEL') }}
        <input
          v-model="instanceId"
          type="password"
          :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.INSTANCE_ID.PLACEHOLDER')"
          @blur="v$.instanceId.$touch"
        />
        <span v-if="v$.instanceId.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.INSTANCE_ID.ERROR') }}
        </span>
      </label>
    </div>

    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
      <label :class="{ error: v$.token.$error }">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.TOKEN.LABEL') }}
        <input
          v-model="token"
          type="password"
          :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.TOKEN.PLACEHOLDER')"
          @blur="v$.token.$touch"
        />
        <span v-if="v$.token.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.TOKEN.ERROR') }}
        </span>
      </label>
    </div>

    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
      <label :class="{ error: v$.clientToken.$error }">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.CLIENT_TOKEN.LABEL') }}
        <input
          v-model="clientToken"
          type="password"
          :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.CLIENT_TOKEN.PLACEHOLDER')"
          @blur="v$.clientToken.$touch"
        />
        <span v-if="v$.clientToken.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.CLIENT_TOKEN.ERROR') }}
        </span>
      </label>
    </div>

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
