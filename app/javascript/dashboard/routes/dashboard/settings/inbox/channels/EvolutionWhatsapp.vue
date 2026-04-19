<script setup>
import { computed, onBeforeUnmount, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import inboxesAPI from 'dashboard/api/inboxes';
import NextButton from 'dashboard/components-next/button/Button.vue';

const route = useRoute();
const router = useRouter();
const store = useStore();
const { t } = useI18n();

const inboxName = ref('');
const formTouched = ref(false);
const isCreating = ref(false);
const isLoadingState = ref(false);
const isStartingPairing = ref(false);
const isCancellingPairing = ref(false);
const isResolvingConflict = ref(false);
const evolutionState = ref(null);
const redirectScheduled = ref(false);

let pollInterval = null;
const START_REQUIRED_STATUSES = [
  'not_created',
  'qr_timeout',
  'logged_out',
  'connect_failure',
];
const STOP_POLLING_STATUSES = [
  ...START_REQUIRED_STATUSES,
  'temporarily_banned',
  'phone_conflict',
];

const currentInboxId = computed(() => route.query.inbox_id);
const hasCreatedInbox = computed(() => Boolean(currentInboxId.value));
const isInboxNameValid = computed(() => inboxName.value.trim().length > 0);
const showInboxNameError = computed(
  () => formTouched.value && !isInboxNameValid.value
);
const connectionStatus = computed(
  () => evolutionState.value?.connection_status || 'disconnected'
);
const isConnected = computed(() => connectionStatus.value === 'connected');
const connectionStatusLabels = {
  connected: computed(() =>
    t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.STATUS.connected')
  ),
  awaiting_qr: computed(() =>
    t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.STATUS.awaiting_qr')
  ),
  pairing: computed(() =>
    t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.STATUS.pairing')
  ),
  disconnected: computed(() =>
    t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.STATUS.disconnected')
  ),
  qr_timeout: computed(() =>
    t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.STATUS.qr_timeout')
  ),
  logged_out: computed(() =>
    t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.STATUS.logged_out')
  ),
  temporarily_banned: computed(() =>
    t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.STATUS.temporarily_banned')
  ),
  connect_failure: computed(() =>
    t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.STATUS.connect_failure')
  ),
  not_created: computed(() =>
    t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.STATUS.not_created')
  ),
  phone_conflict: computed(() =>
    t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.STATUS.phone_conflict')
  ),
};
const connectionStatusLabel = computed(
  () =>
    connectionStatusLabels[connectionStatus.value]?.value ||
    connectionStatusLabels.disconnected.value
);
const connectionStatusClass = computed(() =>
  isConnected.value
    ? 'bg-n-ruby-3 text-n-ruby-11'
    : 'bg-n-slate-3 text-n-slate-11'
);
const isStartRequired = computed(() =>
  START_REQUIRED_STATUSES.includes(connectionStatus.value)
);
const hasPhoneConflict = computed(
  () => connectionStatus.value === 'phone_conflict'
);
const phoneConflict = computed(
  () => evolutionState.value?.phone_conflict || null
);
const shouldKeepPolling = computed(
  () =>
    !isConnected.value &&
    !STOP_POLLING_STATUSES.includes(connectionStatus.value)
);
const canStartPairing = computed(
  () =>
    hasCreatedInbox.value &&
    !isConnected.value &&
    !hasPhoneConflict.value &&
    isStartRequired.value
);
const canCancelPairing = computed(
  () =>
    hasCreatedInbox.value &&
    !isConnected.value &&
    !hasPhoneConflict.value &&
    !isStartRequired.value
);
const emptyStateTitle = computed(() =>
  isStartRequired.value
    ? t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.START_REQUIRED_TITLE')
    : t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.WAITING_TITLE')
);
const emptyStateDescription = computed(() => {
  if (isLoadingState.value) {
    return t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.LOADING_STATE');
  }

  return isStartRequired.value
    ? t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.START_REQUIRED_DESCRIPTION')
    : t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.WAITING_DESCRIPTION');
});

const stopPolling = () => {
  if (pollInterval) {
    clearInterval(pollInterval);
    pollInterval = null;
  }
};

const goToAgents = () => {
  if (!currentInboxId.value) return;

  router.replace({
    name: 'settings_inboxes_add_agents',
    params: {
      page: 'new',
      inbox_id: currentInboxId.value,
    },
  });
};

const scheduleRedirect = () => {
  if (!isConnected.value || redirectScheduled.value) {
    return;
  }

  redirectScheduled.value = true;
  stopPolling();
  window.setTimeout(goToAgents, 1200);
};

const fetchEvolutionState = async () => {
  if (!currentInboxId.value) return;

  isLoadingState.value = true;
  try {
    const response = await inboxesAPI.getEvolutionGoState(currentInboxId.value);
    evolutionState.value = response.data;
    scheduleRedirect();
  } catch (error) {
    useAlert(
      error?.response?.data?.error ||
        error?.message ||
        t('INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE')
    );
    stopPolling();
  } finally {
    isLoadingState.value = false;
  }
};

const startPolling = async () => {
  stopPolling();
  await fetchEvolutionState();

  if (!shouldKeepPolling.value) {
    return;
  }

  pollInterval = window.setInterval(fetchEvolutionState, 5000);
};

const startPairing = async () => {
  if (!currentInboxId.value) return;

  isStartingPairing.value = true;
  stopPolling();

  try {
    const response = await inboxesAPI.startEvolutionGoPairing(
      currentInboxId.value
    );
    evolutionState.value = response.data;
    redirectScheduled.value = false;
    useAlert(t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.START_SUCCESS'));
    await startPolling();
  } catch (error) {
    useAlert(
      error?.response?.data?.error ||
        error?.message ||
        t('INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE')
    );
  } finally {
    isStartingPairing.value = false;
  }
};

const cancelPairing = async () => {
  if (!currentInboxId.value) return;

  isCancellingPairing.value = true;
  stopPolling();

  try {
    const response = await inboxesAPI.cancelEvolutionGoPairing(
      currentInboxId.value
    );
    evolutionState.value = response.data;
    redirectScheduled.value = false;
    useAlert(t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.CANCEL_SUCCESS'));
  } catch (error) {
    useAlert(
      error?.response?.data?.error ||
        error?.message ||
        t('INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE')
    );
    await startPolling();
  } finally {
    isCancellingPairing.value = false;
  }
};

const resolveConflict = async strategy => {
  if (!currentInboxId.value || isResolvingConflict.value) return;

  isResolvingConflict.value = true;
  stopPolling();

  try {
    const response = await inboxesAPI.resolveEvolutionGoConflict(
      currentInboxId.value,
      strategy
    );
    const data = response.data || {};

    if (strategy === 'reuse') {
      const redirectInboxId = data.redirect_inbox_id;
      if (redirectInboxId) {
        await router.replace({
          name: 'settings_inbox_show',
          params: { inboxId: redirectInboxId },
        });
        useAlert(
          t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.CONFLICT.REUSE_SUCCESS')
        );
      }
      return;
    }

    evolutionState.value = data;
    useAlert(
      t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.CONFLICT.REPLACE_SUCCESS')
    );
    await startPolling();
  } catch (error) {
    useAlert(
      error?.response?.data?.error ||
        error?.message ||
        t('INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE')
    );
    await startPolling();
  } finally {
    isResolvingConflict.value = false;
  }
};

const createChannel = async () => {
  formTouched.value = true;
  if (!isInboxNameValid.value) {
    return;
  }

  isCreating.value = true;
  try {
    const whatsappChannel = await store.dispatch('inboxes/createChannel', {
      name: inboxName.value.trim(),
      channel: {
        type: 'whatsapp',
        provider: 'evolution_go',
      },
    });

    await router.replace({
      name: route.name,
      params: route.params,
      query: {
        ...route.query,
        provider: 'evolution_go',
        inbox_id: whatsappChannel.id,
      },
    });
  } catch (error) {
    useAlert(error?.message || t('INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE'));
  } finally {
    isCreating.value = false;
  }
};

watch(
  currentInboxId,
  async inboxId => {
    redirectScheduled.value = false;

    if (!inboxId) {
      evolutionState.value = null;
      stopPolling();
      return;
    }

    await startPolling();
  },
  { immediate: true }
);

onBeforeUnmount(() => {
  stopPolling();
});
</script>

<template>
  <div class="flex flex-col gap-6">
    <div v-if="!hasCreatedInbox" class="flex flex-wrap flex-col mx-0">
      <label :class="{ error: showInboxNameError }">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.LABEL') }}
        <input
          v-model="inboxName"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.PLACEHOLDER')"
          @blur="formTouched = true"
        />
        <span v-if="showInboxNameError" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.ERROR') }}
        </span>
      </label>

      <p class="mt-2 text-sm text-n-slate-11">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.HELP_TEXT') }}
      </p>

      <div class="w-full mt-4">
        <NextButton
          :is-loading="isCreating"
          type="button"
          solid
          blue
          :label="$t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.CREATE_BUTTON')"
          @click="createChannel"
        />
      </div>
    </div>

    <div v-else class="flex flex-col gap-5">
      <div class="flex flex-col gap-2">
        <h2 class="text-base font-medium text-n-slate-12">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.SETUP_TITLE') }}
        </h2>
        <p class="text-sm text-n-slate-11">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.SETUP_DESCRIPTION') }}
        </p>
      </div>

      <div class="grid gap-4 md:grid-cols-2">
        <div class="p-4 rounded-2xl border border-n-weak bg-n-alpha-1">
          <p class="text-xs uppercase tracking-wide text-n-slate-10">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.INSTANCE_NAME') }}
          </p>
          <p class="mt-2 text-sm font-medium text-n-slate-12">
            {{ evolutionState?.instance_name || '-' }}
          </p>
        </div>

        <div class="p-4 rounded-2xl border border-n-weak bg-n-alpha-1">
          <p class="text-xs uppercase tracking-wide text-n-slate-10">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.CONNECTION_STATUS') }}
          </p>
          <div class="mt-2">
            <span
              class="inline-flex px-2.5 py-1 text-xs font-medium rounded-full"
              :class="connectionStatusClass"
            >
              {{ connectionStatusLabel }}
            </span>
          </div>
        </div>
      </div>

      <div class="p-4 rounded-2xl border border-n-weak bg-n-alpha-1">
        <p class="text-xs uppercase tracking-wide text-n-slate-10">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.WEBHOOK_URL') }}
        </p>
        <div class="mt-2">
          <woot-code
            :script="evolutionState?.callback_webhook_url || ''"
            lang="html"
          />
        </div>
      </div>

      <div
        v-if="hasPhoneConflict"
        class="flex flex-col gap-4 p-6 rounded-2xl border border-n-amber-6 bg-n-amber-2"
      >
        <div class="flex flex-col gap-1">
          <p class="text-base font-semibold text-n-amber-12">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.CONFLICT.TITLE') }}
          </p>
          <p class="text-sm text-n-amber-11">
            {{
              $t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.CONFLICT.DESCRIPTION', {
                phoneNumber: phoneConflict?.phone_number,
                inboxName: phoneConflict?.conflicting_inbox_name,
              })
            }}
          </p>
        </div>
        <div v-if="!phoneConflict?.same_account" class="text-sm text-n-ruby-11">
          {{
            $t(
              'INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.CONFLICT.DIFFERENT_ACCOUNT'
            )
          }}
        </div>
        <div v-else class="flex flex-wrap gap-3">
          <NextButton
            :is-loading="isResolvingConflict"
            :label="
              $t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.CONFLICT.REUSE_BUTTON')
            "
            solid
            blue
            @click="resolveConflict('reuse')"
          />
          <NextButton
            :is-loading="isResolvingConflict"
            outline
            ruby
            :label="
              $t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.CONFLICT.REPLACE_BUTTON')
            "
            @click="resolveConflict('replace')"
          />
        </div>
      </div>

      <div
        v-else-if="evolutionState?.qr_code"
        class="flex flex-col gap-3 justify-center items-center p-6 rounded-2xl border border-n-weak bg-white"
      >
        <p class="text-sm text-n-slate-11">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.QR_HELP') }}
        </p>
        <img
          :src="evolutionState.qr_code"
          alt="Evolution Go QR code"
          class="rounded-2xl size-64 border border-n-weak"
        />
      </div>

      <div
        v-else-if="!hasPhoneConflict"
        class="flex flex-col gap-2 justify-center items-center p-6 rounded-2xl border border-dashed border-n-weak bg-n-alpha-1"
      >
        <p class="text-sm font-medium text-n-slate-12">
          {{ emptyStateTitle }}
        </p>
        <p class="text-sm text-n-slate-11">
          {{ emptyStateDescription }}
        </p>
      </div>

      <div
        v-if="evolutionState?.phone_number"
        class="p-4 rounded-2xl border border-n-weak bg-n-alpha-1"
      >
        <p class="text-xs uppercase tracking-wide text-n-slate-10">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.CONNECTED_NUMBER') }}
        </p>
        <p class="mt-2 text-sm font-medium text-n-slate-12">
          {{ evolutionState.phone_number }}
        </p>
      </div>

      <div class="flex gap-3 justify-end">
        <NextButton
          v-if="canStartPairing"
          :is-loading="isStartingPairing"
          :label="$t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.START_BUTTON')"
          @click="startPairing"
        />
        <NextButton
          v-if="canCancelPairing"
          :is-loading="isCancellingPairing"
          outline
          ruby
          :label="$t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.CANCEL_BUTTON')"
          @click="cancelPairing"
        />
        <NextButton
          v-if="isConnected"
          :label="$t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_GO.CONTINUE_BUTTON')"
          @click="goToAgents"
        />
      </div>
    </div>
  </div>
</template>
