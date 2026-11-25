<script setup>
import { computed, ref, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import {
  hasCapability,
  CAPABILITIES,
  isSessionLayerProvider,
} from 'dashboard/helper/whatsappSession';

import SettingsSection from 'dashboard/components/SettingsSection.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

// Standing consent: on every pairing, keep the archive the phone offers.
//
// An inbox-level setting because that is the scope of the decision -- it is answered once
// for the whole inbox and applies to every chat the phone hands over. Asking for one
// thread's older messages is a different act, taken by whoever is reading that thread, and
// it lives at the top of the thread rather than here.
//
// Shared by every provider that can do it, session and legacy alike, and gated on the
// capability rather than on the provider name.
const props = defineProps({
  inbox: { type: Object, required: true },
});

// Mirrors Whatsapp::Session::HistoryMedia::DEFAULT_WINDOW_DAYS: what an inbox that never
// saved the option is held to.
const DEFAULT_HISTORY_MEDIA_DAYS = 30;

const store = useStore();
const { t } = useI18n();

const supported = computed(() =>
  hasCapability(props.inbox, CAPABILITIES.HISTORY_SYNC)
);

// Kept apart from the inbox so a failed save leaves the switch showing what the server
// still holds.
const enabled = ref(false);
watch(
  () => props.inbox.provider_config,
  config => {
    enabled.value = Boolean(config?.history_sync);
  },
  { immediate: true }
);

// The files of the imported history, fetched in the background after the import. Only the
// session layer files history messages that wait for their files, so the legacy providers
// that also import history get no such option.
const historyMediaSupported = computed(
  () => supported.value && isSessionLayerProvider(props.inbox.provider)
);
const fetchMedia = ref(true);
const windowDays = ref(DEFAULT_HISTORY_MEDIA_DAYS);
// A window typed and not saved yet is the operator's: the inbox reloading after the switch
// was saved must not put the stored value back over it.
const windowEdited = ref(false);
const readHistoryMedia = config => {
  fetchMedia.value = config?.history_media_fetch !== false;
  if (!windowEdited.value)
    windowDays.value = config?.history_media_days ?? DEFAULT_HISTORY_MEDIA_DAYS;
};
watch(() => props.inbox.provider_config, readHistoryMedia, { immediate: true });
const editWindowDays = value => {
  windowEdited.value = true;
  windowDays.value = value;
};

const windowDaysValid = computed(
  () => Number.isInteger(windowDays.value) && windowDays.value > 0
);

// One save for every option here, each sending the whole config back: the endpoint
// replaces provider_config, so a partial one would drop the rest. One at a time, with the
// controls locked meanwhile: a second save sent before the first came back would copy the
// config from before it and undo it.
const saving = ref(false);
const saveConfig = async (changes, rollback) => {
  if (saving.value) {
    rollback();
    return;
  }
  saving.value = true;
  try {
    await store.dispatch('inboxes/updateInbox', {
      id: props.inbox.id,
      formData: false,
      channel: {
        provider_config: { ...props.inbox.provider_config, ...changes },
      },
    });
    useAlert(t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
    // The control has already moved by the time this runs, and the next change event
    // needs a different value, so leaving it there would mean toggling away and back to
    // retry.
    rollback();
  } finally {
    saving.value = false;
  }
};

const saveSetting = () =>
  saveConfig({ history_sync: enabled.value }, () => {
    enabled.value = Boolean(props.inbox.provider_config?.history_sync);
  });

const saveFetchMedia = () =>
  saveConfig({ history_media_fetch: fetchMedia.value }, () =>
    readHistoryMedia(props.inbox.provider_config)
  );

const saveWindowDays = async () => {
  if (!windowDaysValid.value) return;
  await saveConfig({ history_media_days: windowDays.value }, () => {
    windowEdited.value = false;
    readHistoryMedia(props.inbox.provider_config);
  });
  if (props.inbox.provider_config?.history_media_days === windowDays.value)
    windowEdited.value = false;
};
</script>

<template>
  <div v-if="supported">
    <SettingsSection
      :title="$t('INBOX_MGMT.ADD.WHATSAPP.SESSION.FIELDS.HISTORY_SYNC.LABEL')"
      :sub-title="
        $t('INBOX_MGMT.ADD.WHATSAPP.SESSION.FIELDS.HISTORY_SYNC.DESCRIPTION')
      "
    >
      <div class="flex items-center gap-2">
        <Switch
          id="history_sync"
          v-model="enabled"
          :disabled="saving"
          @change="saveSetting"
        />
        <span class="text-sm">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.SESSION.FIELDS.HISTORY_SYNC.LABEL') }}
        </span>
      </div>
    </SettingsSection>
    <SettingsSection
      v-if="historyMediaSupported"
      :title="$t('INBOX_MGMT.ADD.WHATSAPP.SESSION.FIELDS.HISTORY_MEDIA.TITLE')"
      :sub-title="
        $t('INBOX_MGMT.ADD.WHATSAPP.SESSION.FIELDS.HISTORY_MEDIA.DESCRIPTION')
      "
    >
      <div class="flex flex-col gap-4">
        <div class="flex items-center gap-2">
          <Switch
            id="history_media_fetch"
            v-model="fetchMedia"
            :disabled="saving"
            @change="saveFetchMedia"
          />
          <span class="text-sm">
            {{
              $t(
                'INBOX_MGMT.ADD.WHATSAPP.SESSION.FIELDS.HISTORY_MEDIA.FETCH_LABEL'
              )
            }}
          </span>
        </div>
        <div class="flex items-end gap-2">
          <Input
            id="history_media_days"
            :model-value="windowDays"
            type="number"
            min="1"
            class="w-48"
            :disabled="saving"
            :label="
              $t(
                'INBOX_MGMT.ADD.WHATSAPP.SESSION.FIELDS.HISTORY_MEDIA.DAYS_LABEL'
              )
            "
            :message="
              windowDaysValid
                ? ''
                : $t(
                    'INBOX_MGMT.ADD.WHATSAPP.SESSION.FIELDS.HISTORY_MEDIA.DAYS_ERROR'
                  )
            "
            :message-type="windowDaysValid ? 'info' : 'error'"
            @update:model-value="editWindowDays"
            @enter="saveWindowDays"
          />
          <NextButton
            :disabled="!windowDaysValid || saving"
            :is-loading="saving"
            :label="
              $t('INBOX_MGMT.ADD.WHATSAPP.SESSION.FIELDS.HISTORY_MEDIA.SAVE')
            "
            @click="saveWindowDays"
          />
        </div>
      </div>
    </SettingsSection>
  </div>
</template>
