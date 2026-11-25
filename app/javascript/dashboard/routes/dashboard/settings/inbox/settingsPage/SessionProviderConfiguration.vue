<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { isHttpUrl } from 'dashboard/helper/whatsappSession';
import { useWhatsappSessionProviders } from 'dashboard/composables/useWhatsappSessionProviders';

import SettingsSection from 'dashboard/components/SettingsSection.vue';
import WhatsappHistorySync from './WhatsappHistorySync.vue';
import WhatsappLinkDeviceModal from '../components/WhatsappLinkDeviceModal.vue';
import InboxName from 'dashboard/components/widgets/InboxName.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Label from 'dashboard/components-next/label/Label.vue';

const props = defineProps({
  inbox: { type: Object, required: true },
});

const store = useStore();
const { t, te } = useI18n();
const { descriptorFor, fetchProviders } = useWhatsappSessionProviders();
onMounted(fetchProviders);

const descriptor = computed(() => descriptorFor(props.inbox.provider));
// Said where the inbox is managed, not only where it was picked: whoever inherits an
// inbox never saw the picker, and this is the page they change its credentials on.
const isBeta = computed(() => Boolean(descriptor.value?.beta));
const credentialFields = computed(
  () => descriptor.value?.fields?.filter(f => f.type !== 'boolean') ?? []
);
// history_sync is left out on purpose: it is rendered by WhatsappHistorySync, next to the
// on-demand button it shares a subject with, and by the legacy providers that have no
// descriptor form at all.
const preferenceFields = computed(
  () =>
    descriptor.value?.fields?.filter(
      f => f.type === 'boolean' && f.name !== 'history_sync'
    ) ?? []
);

// Edited values live apart from the inbox so a failed save leaves the record showing
// what the server still holds.
const values = ref({});
watch(
  [descriptor, () => props.inbox.provider_config],
  ([shape, config]) => {
    if (!shape) return;
    values.value = Object.fromEntries(
      shape.fields.map(field => [
        field.name,
        // A secret is never served back, so its input starts empty and an untouched one
        // is left alone on save rather than overwriting the stored credential with ''.
        field.secret
          ? ''
          : (config?.[field.name] ??
            field.default ??
            (field.type === 'boolean' ? false : '')),
      ])
    );
  },
  { immediate: true }
);

const showLinkDeviceModal = ref(false);

const fieldKey = field =>
  `INBOX_MGMT.ADD.WHATSAPP.SESSION.FIELDS.${field.name.toUpperCase()}`;

// A field that needs explaining says so in DESCRIPTION; the rest repeat their placeholder,
// which for a token or a URL is all there is to say.
const fieldHint = field => {
  const key = `${fieldKey(field)}.DESCRIPTION`;
  return te(key) ? t(key) : t(`${fieldKey(field)}.PLACEHOLDER`);
};

const isInvalid = field => {
  const value = values.value[field.name];
  if (field.required && field.secret) return false;
  if (field.required && !value) return true;
  return field.type === 'url' && value && !isHttpUrl(value);
};

const save = async field => {
  if (isInvalid(field)) return;

  const value = values.value[field.name];
  // An untouched secret input means "leave it as it is", not "clear it".
  if (field.secret && !value) return;

  try {
    await store.dispatch('inboxes/updateInbox', {
      id: props.inbox.id,
      formData: false,
      channel: {
        provider_config: {
          ...props.inbox.provider_config,
          [field.name]: value,
        },
      },
    });
    useAlert(t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (error) {
    // The server says which field it refused (a proxy it would not route through, say),
    // which is the part the operator can act on.
    useAlert(error.message || t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
    // A switch has already moved by the time this runs, so leaving it there shows a
    // setting the server never took -- and since the next change event needs a different
    // value, retrying the one that failed means toggling away and back. Text keeps what
    // was typed: there the value is the user's work and they can correct and save again.
    if (field.type === 'boolean') {
      values.value[field.name] =
        props.inbox.provider_config?.[field.name] ?? field.default ?? false;
    }
  }
};
</script>

<template>
  <div>
    <WhatsappLinkDeviceModal
      v-if="showLinkDeviceModal"
      :show="showLinkDeviceModal"
      :on-close="() => (showLinkDeviceModal = false)"
      :inbox="inbox"
    />
    <div class="mx-8">
      <SettingsSection
        :title="
          $t(
            'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANAGE_PROVIDER_CONNECTION_TITLE'
          )
        "
        :sub-title="
          $t(
            'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANAGE_PROVIDER_CONNECTION_SUBHEADER'
          )
        "
      >
        <div class="flex flex-col gap-2">
          <div class="flex items-center gap-2">
            <InboxName
              :inbox="inbox"
              class="!text-lg !m-0"
              with-phone-number
              with-provider-connection-status
            />
            <Label
              v-if="isBeta"
              v-tooltip.top="t('GENERAL.BETA_DESCRIPTION')"
              :label="t('GENERAL.BETA')"
              color="blue"
              compact
            />
          </div>
          <NextButton class="w-fit" @click="showLinkDeviceModal = true">
            {{
              $t(
                'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANAGE_PROVIDER_CONNECTION_BUTTON'
              )
            }}
          </NextButton>
        </div>
      </SettingsSection>

      <WhatsappHistorySync :inbox="inbox" />

      <SettingsSection
        v-for="field in credentialFields"
        :key="field.name"
        :title="$t(`${fieldKey(field)}.LABEL`)"
        :sub-title="fieldHint(field)"
      >
        <div class="flex items-center justify-between flex-1 mt-2">
          <woot-input
            v-model="values[field.name]"
            :type="field.type === 'password' ? 'password' : 'text'"
            class="flex-1 mr-2 items-center"
            :placeholder="$t(`${fieldKey(field)}.PLACEHOLDER`)"
          />
          <NextButton
            :disabled="isInvalid(field)"
            :label="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
            @click="save(field)"
          />
        </div>
      </SettingsSection>

      <SettingsSection
        v-for="field in preferenceFields"
        :key="field.name"
        :title="$t(`${fieldKey(field)}.LABEL`)"
        :sub-title="$t(`${fieldKey(field)}.DESCRIPTION`)"
      >
        <div class="flex items-center gap-2">
          <Switch
            :id="field.name"
            v-model="values[field.name]"
            @change="save(field)"
          />
          <span class="text-sm">{{ $t(`${fieldKey(field)}.LABEL`) }}</span>
        </div>
      </SettingsSection>
    </div>
  </div>
</template>
