<script setup>
import { computed, onMounted, ref } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

import { INBOX_TYPES } from 'dashboard/helper/inbox';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Label from 'dashboard/components-next/label/Label.vue';
import ToggleSwitch from 'dashboard/components-next/switch/Switch.vue';

const PATHORS_APP_URL = 'https://app.pathors.com';
// Referenced via :src binding so the Vue compiler treats it as a runtime
// string. A static src attribute is compiled to a module import, which the
// test-mode Rollup build cannot resolve for public/ paths — and eslint's
// vue/no-useless-v-bind auto-"fixes" an inline literal :src back into exactly
// that broken static form, so the value must live here in the script.
const PATHORS_LOGO_URL = '/dashboard/images/integrations/pathors.png';
// Pathors provisioning points the agent bot at
// `{PATHORS_BACKEND}/project/{projectId}/integration/chatwoot/callback`
const PATHORS_CALLBACK_REGEX =
  /\/project\/([^/]+)\/integration\/chatwoot\/callback/;
// Voice inboxes are driven by the Pathors voice agent, never by the chat bot.
const isVoiceInbox = inbox => inbox.channel_type === INBOX_TYPES.VOICE;

const store = useStore();
const { t } = useI18n();

const isLoaded = ref(false);
const inboxIdBeingUpdated = ref(null);
const disconnectDialogRef = ref(null);
const isDisconnecting = ref(false);
// The switch keeps an optimistic local value. When a toggle fails, nothing in
// the store changes, so bump this counter to remount the switch and let it
// pick the (unchanged) truth back up.
const failedToggleCount = ref(0);

const integration = useMapGetter('integrations/getIntegration');
const inboxes = useMapGetter('inboxes/getInboxes');
const agentBots = useMapGetter('agentBots/getBots');
const activeAgentBot = useMapGetter('agentBots/getActiveAgentBot');

const pathorsApp = computed(() => integration.value('pathors'));

// The connected state is derived from the agent bot list rather than from the
// `enabled` flag on the app payload. The page needs the bot record anyway (its
// id to assign inboxes, its outgoing_url to build the deep link), so reading
// both facts from one source keeps them from drifting apart mid-session.
const pathorsBot = computed(() =>
  agentBots.value.find(bot =>
    PATHORS_CALLBACK_REGEX.test(bot.outgoing_url ?? '')
  )
);

const isConnected = computed(() => Boolean(pathorsBot.value));

// Written into the OAuth hook when the authorization code is redeemed. The
// hook payload only carries `settings` for administrators and only for the
// app's visible_properties, which is exactly where this lives.
const organizationId = computed(
  () => pathorsApp.value?.hooks?.[0]?.settings?.organization_id ?? null
);

const manageUrl = computed(() => {
  if (organizationId.value) {
    return `${PATHORS_APP_URL}/org/${organizationId.value}/inbox`;
  }
  // Connections made before consent bound whole organizations have no
  // organization on the hook; the project in the bot's callback URL is the
  // only handle they leave behind.
  const [, projectId] =
    pathorsBot.value?.outgoing_url?.match(PATHORS_CALLBACK_REGEX) ?? [];
  if (!projectId) return PATHORS_APP_URL;
  return `${PATHORS_APP_URL}/project/${projectId}/integrations/chatwoot`;
});

// The OAuth hook is written by this side when the authorization code is
// redeemed; the agent bot is provisioned by the Pathors side. A hook without a
// bot means the handshake started but never finished — either provisioning
// failed, or the bot was deleted in Chatwoot afterwards. That is a different
// state from "never connected" and needs its own copy, so the administrator
// knows a retry is what is being offered.
const isIncomplete = computed(
  () => !isConnected.value && Boolean(pathorsApp.value?.hooks?.length)
);

const statusLabel = computed(() => {
  if (isConnected.value)
    return t('INTEGRATION_SETTINGS.PATHORS.STATUS.CONNECTED');
  if (isIncomplete.value)
    return t('INTEGRATION_SETTINGS.PATHORS.STATUS.INCOMPLETE');
  return t('INTEGRATION_SETTINGS.PATHORS.STATUS.NOT_CONNECTED');
});

const statusColor = computed(() => {
  if (isConnected.value) return 'teal';
  return isIncomplete.value ? 'amber' : 'slate';
});

// OAuth connect URL, minted server-side (signed per-account token) and only
// serialized for administrators. Absent when the deployment has no Pathors
// OAuth client configured — connecting is then impossible until an operator
// sets it up, so the card says so instead of offering a link that dead-ends.
const connectUrl = computed(() => pathorsApp.value?.action || null);

// Nothing can be connected without the OAuth URL, so that state owns the whole
// panel: no title about picking a project, and no button to press.
const showIncompletePanel = computed(
  () => Boolean(connectUrl.value) && isIncomplete.value
);

const connectPanelTitle = computed(() => {
  if (!connectUrl.value)
    return t('INTEGRATION_SETTINGS.PATHORS.UNCONFIGURED.TITLE');
  if (showIncompletePanel.value)
    return t('INTEGRATION_SETTINGS.PATHORS.INCOMPLETE.TITLE');
  return t('INTEGRATION_SETTINGS.PATHORS.NOT_CONNECTED.TITLE');
});

const connectPanelDescription = computed(() => {
  if (!connectUrl.value)
    return t('INTEGRATION_SETTINGS.PATHORS.UNCONFIGURED.DESCRIPTION');
  if (showIncompletePanel.value)
    return t('INTEGRATION_SETTINGS.PATHORS.INCOMPLETE.DESCRIPTION');
  return t('INTEGRATION_SETTINGS.PATHORS.NOT_CONNECTED.DESCRIPTION');
});

const connectButtonLabel = computed(() =>
  showIncompletePanel.value
    ? t('INTEGRATION_SETTINGS.PATHORS.INCOMPLETE.RECONNECT_BUTTON_TEXT')
    : t('INTEGRATION_SETTINGS.PATHORS.NOT_CONNECTED.CONNECT_BUTTON_TEXT')
);

const managedInboxes = computed(() =>
  inboxes.value.filter(inbox => !isVoiceInbox(inbox))
);

const voiceInboxes = computed(() => inboxes.value.filter(isVoiceInbox));

const isHandledByPathors = inboxId =>
  Boolean(pathorsBot.value) &&
  activeAgentBot.value(inboxId)?.id === pathorsBot.value.id;

const toggleInbox = async (inbox, shouldHandle) => {
  inboxIdBeingUpdated.value = inbox.id;
  try {
    if (shouldHandle) {
      await store.dispatch('agentBots/setAgentBotInbox', {
        inboxId: inbox.id,
        botId: pathorsBot.value.id,
      });
      useAlert(t('INTEGRATION_SETTINGS.PATHORS.INBOXES.ENABLED_SUCCESS'));
    } else {
      await store.dispatch('agentBots/disconnectBot', { inboxId: inbox.id });
      useAlert(t('INTEGRATION_SETTINGS.PATHORS.INBOXES.DISABLED_SUCCESS'));
    }
  } catch (error) {
    failedToggleCount.value += 1;
    useAlert(error?.message || t('INTEGRATION_SETTINGS.PATHORS.INBOXES.ERROR'));
  } finally {
    inboxIdBeingUpdated.value = null;
  }
};

const openDisconnectDialog = () => disconnectDialogRef.value?.open();

// The connected state is read from the agent bot list and the card copy from
// the integration payload, so both have to be refetched for the page to fall
// back to its not-connected form.
const confirmDisconnect = async () => {
  isDisconnecting.value = true;
  try {
    await store.dispatch('integrations/disconnectPathors');
    await Promise.all([
      store.dispatch('integrations/get'),
      store.dispatch('agentBots/get'),
    ]);
    disconnectDialogRef.value?.close();
    useAlert(t('INTEGRATION_SETTINGS.PATHORS.DISCONNECT.SUCCESS'));
  } catch (error) {
    useAlert(
      error?.message || t('INTEGRATION_SETTINGS.PATHORS.DISCONNECT.ERROR')
    );
  } finally {
    isDisconnecting.value = false;
  }
};

const initializePathorsIntegration = async () => {
  await Promise.all([
    store.dispatch('integrations/get'),
    store.dispatch('agentBots/get'),
    store.dispatch('inboxes/get'),
  ]);
  // The per-inbox assignment is only rendered once a Pathors bot exists.
  if (isConnected.value) {
    await Promise.all(
      managedInboxes.value.map(inbox =>
        store.dispatch('agentBots/fetchAgentBotInbox', inbox.id)
      )
    );
  }
  isLoaded.value = true;
};

onMounted(() => {
  initializePathorsIntegration();
});
</script>

<template>
  <SettingsLayout :is-loading="!isLoaded">
    <template #header>
      <BaseSettingsHeader
        :title="$t('INTEGRATION_SETTINGS.PATHORS.HEADER')"
        description=""
        :back-button-label="$t('INTEGRATION_SETTINGS.HEADER')"
      />
    </template>
    <template #body>
      <div class="flex flex-col gap-6">
        <div
          class="flex flex-col lg:flex-row lg:items-center justify-between gap-6 p-6 outline outline-1 outline-n-container bg-n-card rounded-xl"
        >
          <div
            class="flex flex-col lg:flex-row lg:items-center items-start flex-1 gap-6"
          >
            <div class="flex items-center justify-center flex-shrink-0 size-16">
              <img
                :src="PATHORS_LOGO_URL"
                alt=""
                class="max-w-full border rounded-md shadow-sm border-n-weak bg-n-alpha-3 dark:bg-n-alpha-2"
              />
            </div>
            <div>
              <div class="flex items-center gap-2 mb-1">
                <h3 class="text-heading-1 text-n-slate-12">
                  {{
                    pathorsApp.name || $t('INTEGRATION_SETTINGS.PATHORS.HEADER')
                  }}
                </h3>
                <Label :label="statusLabel" :color="statusColor" compact />
              </div>
              <p class="text-n-slate-11 text-body-main">
                {{ pathorsApp.description }}
              </p>
            </div>
          </div>
          <div v-if="isConnected" class="flex items-center flex-shrink-0 gap-2">
            <a :href="manageUrl" target="_blank" rel="noopener noreferrer">
              <Button
                faded
                blue
                :label="$t('INTEGRATION_SETTINGS.PATHORS.MANAGE_BUTTON_TEXT')"
                icon="i-lucide-external-link"
                trailing-icon
              />
            </a>
            <Button
              faded
              ruby
              :label="$t('INTEGRATION_SETTINGS.PATHORS.DISCONNECT.BUTTON_TEXT')"
              :is-loading="isDisconnecting"
              @click="openDisconnectDialog"
            />
          </div>
        </div>

        <div
          v-if="!isConnected"
          class="flex flex-col items-start gap-3 p-6 outline outline-1 rounded-xl"
          :class="
            showIncompletePanel
              ? 'outline-n-amber-4 bg-n-amber-2'
              : 'outline-n-container bg-n-card'
          "
        >
          <h4
            class="text-heading-3"
            :class="showIncompletePanel ? 'text-n-amber-11' : 'text-n-slate-12'"
          >
            {{ connectPanelTitle }}
          </h4>
          <p class="max-w-2xl text-n-slate-11 text-body-main">
            {{ connectPanelDescription }}
          </p>
          <a v-if="connectUrl" :href="connectUrl">
            <Button
              :label="connectButtonLabel"
              icon="i-lucide-plug"
              trailing-icon
            />
          </a>
        </div>

        <div
          v-else
          class="flex flex-col outline outline-1 outline-n-container bg-n-card rounded-xl"
        >
          <div class="flex flex-col gap-1 px-6 py-4 border-b border-n-weak">
            <h4 class="text-heading-3 text-n-slate-12">
              {{ $t('INTEGRATION_SETTINGS.PATHORS.INBOXES.TITLE') }}
            </h4>
            <p class="text-n-slate-11 text-body-main">
              {{ $t('INTEGRATION_SETTINGS.PATHORS.INBOXES.DESCRIPTION') }}
            </p>
          </div>
          <p
            v-if="!inboxes.length"
            class="px-6 py-6 text-n-slate-11 text-body-main"
          >
            {{ $t('INTEGRATION_SETTINGS.PATHORS.INBOXES.EMPTY') }}
          </p>
          <ul v-else class="flex flex-col m-0 list-none">
            <li
              v-for="inbox in managedInboxes"
              :key="inbox.id"
              class="flex items-center justify-between gap-4 px-6 py-3 border-b border-n-weak last:border-b-0"
            >
              <span class="text-body-main text-n-slate-12">
                {{ inbox.name }}
              </span>
              <ToggleSwitch
                :key="`${inbox.id}-${failedToggleCount}`"
                :model-value="isHandledByPathors(inbox.id)"
                :disabled="inboxIdBeingUpdated === inbox.id"
                :aria-label="
                  $t('INTEGRATION_SETTINGS.PATHORS.INBOXES.TOGGLE_LABEL')
                "
                @update:model-value="value => toggleInbox(inbox, value)"
              />
            </li>
            <li
              v-for="inbox in voiceInboxes"
              :key="inbox.id"
              class="flex items-center justify-between gap-4 px-6 py-3 border-b border-n-weak last:border-b-0"
            >
              <span class="text-body-main text-n-slate-11">
                {{ inbox.name }}
              </span>
              <span
                class="flex items-center gap-1.5 text-label-small text-n-slate-10"
              >
                <span class="i-lucide-lock size-3.5" aria-hidden="true" />
                {{ $t('INTEGRATION_SETTINGS.PATHORS.INBOXES.VOICE_LOCKED') }}
              </span>
            </li>
          </ul>
        </div>

        <Dialog
          ref="disconnectDialogRef"
          type="alert"
          :title="$t('INTEGRATION_SETTINGS.PATHORS.DISCONNECT.DIALOG_TITLE')"
          :description="
            $t('INTEGRATION_SETTINGS.PATHORS.DISCONNECT.DIALOG_MESSAGE')
          "
          :confirm-button-label="
            $t('INTEGRATION_SETTINGS.PATHORS.DISCONNECT.CONFIRM')
          "
          :is-loading="isDisconnecting"
          @confirm="confirmDisconnect"
        />
      </div>
    </template>
  </SettingsLayout>
</template>
