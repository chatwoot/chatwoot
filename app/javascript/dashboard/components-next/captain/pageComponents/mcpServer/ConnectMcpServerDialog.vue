<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useDebounceFn } from '@vueuse/core';
import { useAlert } from 'dashboard/composables';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import McpServersAPI from 'dashboard/api/captain/mcpServers';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { AUTH_TYPES, URL_PREFIX } from './mcpTools';

const props = defineProps({
  assistantId: { type: [String, Number], required: true },
});

// connected: the server is saved and needs no sign-in, so its tools can be picked now
// signIn: an OAuth server was saved, and the page starts its sign-in
const emit = defineEmits(['saved', 'connected', 'signIn']);

const { t } = useI18n();
const { run: runCheck } = useAbortableRequest();

// The URL is checked this long after the user stops typing
const CHECK_DELAY_MS = 500;
// The field shows only what follows https://, which stays fixed in front.
// A pasted URL loses its own scheme, so the address never doubles it.
const SCHEME_PATTERN = /^\s*https?:\/\//i;

const dialogRef = ref(null);
const url = ref(URL_PREFIX);
// The token fields show only when the server answers that it needs a token
const showHeader = ref(false);
const needsToken = ref(false);
const token = ref('');
const authHeader = ref('');
const suggestions = ref([]);
const isBusy = ref(false);
// The last answer from the server, for the URL it was checked with
const check = ref(null);

const serverUrl = computed(() => url.value.trim());
// A token typed for another URL is kept but not sent
const tokenValue = computed(() => (needsToken.value ? token.value.trim() : ''));
const canConnect = computed(() => serverUrl.value !== URL_PREFIX);

const address = computed({
  get: () => url.value.slice(URL_PREFIX.length),
  set: value => {
    url.value = URL_PREFIX + value.replace(SCHEME_PATTERN, '').trim();
  },
});

// Pasting a full URL, or typing https:// or http://, leaves only the address in the field
const onAddressInput = event => {
  address.value = event.target.value;
  if (event.target.value !== address.value) {
    event.target.value = address.value;
  }
};

// Suggestions the assistant does not have yet
const openSuggestions = computed(() =>
  suggestions.value.filter(suggestion => !suggestion.connected)
);
const hasRecommended = computed(() =>
  openSuggestions.value.some(suggestion => suggestion.recommended)
);

// Suggestions only help a new connection, and the dialog works without them
const loadSuggestions = async () => {
  try {
    const { data } = await McpServersAPI.suggestions({
      assistantId: props.assistantId,
    });
    suggestions.value = data.payload;
  } catch {
    suggestions.value = [];
  }
};

// A server that names itself only after sign-in takes the name of the suggestion it came from
const serverName = (checkedUrl, data) => {
  const suggestion = suggestions.value.find(item => item.url === checkedUrl);
  return suggestion && data.name === new URL(checkedUrl).host
    ? suggestion.name
    : data.name;
};

const discover = async checkedUrl => {
  const response = await runCheck(signal =>
    McpServersAPI.discover({
      assistantId: props.assistantId,
      url: checkedUrl,
      signal,
    })
  );
  if (!response) return null;
  check.value = {
    url: checkedUrl,
    authType: response.data.auth_type,
    name: serverName(checkedUrl, response.data),
  };
  needsToken.value = check.value.authType === AUTH_TYPES.TOKEN;
  return check.value;
};

const currentCheck = computed(() =>
  check.value?.url === serverUrl.value ? check.value : null
);

// The background check only sets the button label. Continue checks again if this one failed.
const checkInBackground = async () => {
  if (!canConnect.value || currentCheck.value) return;
  try {
    await discover(serverUrl.value);
  } catch {
    check.value = null;
  }
};
const checkLater = useDebounceFn(checkInBackground, CHECK_DELAY_MS);

watch(serverUrl, () => {
  needsToken.value = false;
  checkLater();
});

const pickSuggestion = suggestion => {
  url.value = suggestion.url;
  checkInBackground();
};
const isPicked = suggestion => suggestion.url === serverUrl.value;

const open = () => {
  url.value = URL_PREFIX;
  showHeader.value = false;
  needsToken.value = false;
  token.value = '';
  authHeader.value = '';
  check.value = null;
  loadSuggestions();
  dialogRef.value.open();
};

const close = () => dialogRef.value.close();

const connectWithToken = async () => {
  const { data } = await McpServersAPI.discover({
    assistantId: props.assistantId,
    url: serverUrl.value,
    token: tokenValue.value,
    authHeader: authHeader.value.trim() || undefined,
  });
  return McpServersAPI.create({
    assistantId: props.assistantId,
    url: serverUrl.value,
    name: serverName(serverUrl.value, data),
    auth_type: AUTH_TYPES.TOKEN,
    auth_header: authHeader.value.trim() || null,
    auth_config: { token: tokenValue.value },
  });
};

// Continue never leaves Chatwoot without saying so first. If the check has not
// answered yet and the server uses OAuth, the button changes to name the sign-in, and the next click redirects.
const connect = async () => {
  if (!canConnect.value || isBusy.value) return;
  isBusy.value = true;
  try {
    if (tokenValue.value) {
      const { data: saved } = await connectWithToken();
      emit('saved');
      close();
      emit('connected', saved);
      return;
    }

    const known = currentCheck.value;
    const result = known || (await discover(serverUrl.value));
    if (!result || result.authType === AUTH_TYPES.TOKEN) return;
    if (!known && result.authType === AUTH_TYPES.OAUTH) return;

    const { data: saved } = await McpServersAPI.create({
      assistantId: props.assistantId,
      url: result.url,
      name: result.name,
      auth_type: result.authType,
    });
    emit('saved');
    close();
    // The server is saved, so a failed sign-in start is retried from its card, not by connecting again
    if (result.authType === AUTH_TYPES.OAUTH) {
      emit('signIn', saved);
    } else {
      emit('connected', saved);
    }
  } catch (error) {
    useAlert(
      parseAPIErrorResponse(error) ||
        t('CAPTAIN.MCP_SERVERS.DIALOG.CHECK_ERROR')
    );
  } finally {
    isBusy.value = false;
  }
};

const redirectsTo = computed(() =>
  !tokenValue.value && currentCheck.value?.authType === AUTH_TYPES.OAUTH
    ? currentCheck.value.name
    : null
);

// The button names what happens next: a sign-in on the server's site, a connection, or a check
const primaryAction = computed(() => {
  if (redirectsTo.value) {
    return {
      label: t('CAPTAIN.MCP_SERVERS.DIALOG.SERVER.CONTINUE_TO', {
        name: redirectsTo.value,
      }),
      icon: 'i-lucide-external-link',
    };
  }
  if (tokenValue.value || currentCheck.value?.authType === AUTH_TYPES.NONE) {
    return { label: t('CAPTAIN.MCP_SERVERS.DIALOG.SERVER.CONNECT') };
  }
  return { label: t('CAPTAIN.MCP_SERVERS.DIALOG.CONTINUE') };
});

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('CAPTAIN.MCP_SERVERS.DIALOG.CONNECT_TITLE')"
    :description="t('CAPTAIN.MCP_SERVERS.DIALOG.SERVER.DESCRIPTION')"
    @confirm="connect"
  >
    <div class="flex flex-col gap-6">
      <section class="flex flex-col gap-3">
        <label
          class="flex items-center h-11 px-3.5 rounded-xl bg-n-alpha-1 outline outline-1 -outline-offset-1 outline-n-weak transition-colors focus-within:outline-n-brand"
        >
          <span class="text-sm select-none shrink-0 text-n-slate-10">
            {{ URL_PREFIX }}
          </span>
          <input
            :value="address"
            type="text"
            spellcheck="false"
            autocomplete="off"
            :aria-label="t('CAPTAIN.MCP_SERVERS.DIALOG.SERVER.URL_LABEL')"
            :placeholder="
              t('CAPTAIN.MCP_SERVERS.DIALOG.SERVER.URL_PLACEHOLDER')
            "
            :disabled="isBusy"
            class="flex-1 min-w-0 !p-0 !m-0 !h-auto text-sm !bg-transparent !border-0 !shadow-none !outline-none !ring-0 text-n-slate-12 placeholder:text-n-slate-10"
            @input="onAddressInput"
          />
        </label>

        <div v-if="needsToken" class="flex flex-col gap-2">
          <input
            v-model="token"
            type="password"
            autocomplete="off"
            :placeholder="t('CAPTAIN.MCP_SERVERS.DIALOG.TOKEN_LABEL')"
            :disabled="isBusy"
            class="!h-11 !px-3.5 !m-0 text-sm !rounded-xl !bg-n-alpha-1 !border-0 !shadow-none outline outline-1 -outline-offset-1 focus:outline-n-brand text-n-slate-12 placeholder:text-n-slate-10"
            :class="tokenValue ? 'outline-n-weak' : 'outline-n-amber-7'"
          />
          <input
            v-if="showHeader"
            v-model="authHeader"
            type="text"
            autocomplete="off"
            :placeholder="
              t('CAPTAIN.MCP_SERVERS.DIALOG.SERVER.HEADER_PLACEHOLDER')
            "
            :disabled="isBusy"
            class="!h-11 !px-3.5 !m-0 text-sm !rounded-xl !bg-n-alpha-1 !border-0 !shadow-none outline outline-1 -outline-offset-1 outline-n-weak focus:outline-n-brand text-n-slate-12 placeholder:text-n-slate-10"
          />
          <p class="m-0 text-xs text-n-slate-11">
            {{ t('CAPTAIN.MCP_SERVERS.DIALOG.SERVER.NEEDS_TOKEN') }}
            {{ t('CAPTAIN.MCP_SERVERS.DIALOG.SERVER.TOKEN_HELP') }}
            <button
              v-if="!showHeader"
              type="button"
              class="p-0 font-medium text-n-blue-11 hover:underline"
              @click="showHeader = true"
            >
              {{ t('CAPTAIN.MCP_SERVERS.DIALOG.SERVER.CUSTOM_HEADER') }}
            </button>
          </p>
        </div>
      </section>

      <section v-if="openSuggestions.length" class="flex flex-col gap-2.5">
        <div class="flex items-center justify-between gap-3">
          <span class="text-xs font-medium text-n-slate-11">
            {{ t('CAPTAIN.MCP_SERVERS.SUGGESTIONS.TITLE') }}
          </span>
          <span
            v-if="hasRecommended"
            class="inline-flex items-center gap-1.5 text-xs text-n-slate-10"
          >
            <span class="rounded-full size-1.5 bg-n-teal-9" />
            {{ t('CAPTAIN.MCP_SERVERS.SUGGESTIONS.RECOMMENDED') }}
          </span>
        </div>
        <div class="flex flex-wrap gap-2">
          <button
            v-for="suggestion in openSuggestions"
            :key="suggestion.id"
            type="button"
            class="inline-flex items-center gap-1.5 h-8 px-3 text-sm rounded-full outline outline-1 -outline-offset-1 transition-colors disabled:opacity-50"
            :class="
              isPicked(suggestion)
                ? 'outline-n-brand bg-n-blue-2 text-n-blue-11'
                : 'outline-n-weak bg-n-solid-1 text-n-slate-12 hover:bg-n-alpha-2'
            "
            :disabled="isBusy"
            @click="pickSuggestion(suggestion)"
          >
            <span
              v-if="suggestion.recommended"
              class="rounded-full size-1.5 bg-n-teal-9"
            />
            {{ suggestion.name }}
          </button>
        </div>
      </section>
    </div>

    <template #footer>
      <!-- The hint shares the row with the buttons, so showing it does not change the dialog height -->
      <div class="flex items-center gap-4">
        <p class="flex-1 min-w-0 m-0 text-xs line-clamp-2 text-n-slate-11">
          <template v-if="redirectsTo">
            {{
              t('CAPTAIN.MCP_SERVERS.DIALOG.SERVER.REDIRECT_HINT', {
                name: redirectsTo,
              })
            }}
          </template>
        </p>
        <div class="flex items-center gap-3 shrink-0">
          <Button
            type="button"
            faded
            slate
            :label="t('DIALOG.BUTTONS.CANCEL')"
            :disabled="isBusy"
            @click="close"
          />
          <Button
            type="submit"
            :label="primaryAction.label"
            :icon="primaryAction.icon"
            :trailing-icon="!!primaryAction.icon"
            :is-loading="isBusy"
            :disabled="!canConnect || isBusy"
          />
        </div>
      </div>
    </template>
  </Dialog>
</template>
