<script setup>
import { ref, computed, reactive, watch, onMounted } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { required, helpers, url } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { useToggle } from '@vueuse/core';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import AccessToken from 'dashboard/routes/dashboard/settings/profile/AccessToken.vue';

// CUSTOMIZAÇÃO_SYNAPSEOS: 7 papéis canônicos do Esquadrão Synapse.
// Obrigatório na criação — habilita métricas automáticas por papel.
const SQUADRON_ROLES = [
  'alice',
  'iza',
  'luis',
  'otto',
  'fernanda',
  'angela',
  'vitor',
];

const props = defineProps({
  type: {
    type: String,
    default: 'create',
    validator: value => ['create', 'edit'].includes(value),
  },
  selectedBot: {
    type: Object,
    default: () => ({}),
  },
});

const MODAL_TYPES = {
  CREATE: 'create',
  EDIT: 'edit',
};

const store = useStore();
const { t } = useI18n();
const dialogRef = ref(null);
const uiFlags = useMapGetter('agentBots/getUIFlags');
const allInboxes = useMapGetter('inboxes/getInboxes');

const formState = reactive({
  botName: '',
  botDescription: '',
  botUrl: '',
  botAvatar: null,
  botAvatarUrl: '',
  // CUSTOMIZAÇÃO_SYNAPSEOS
  squadronRole: '',
  inboxIds: [],
});

const [showAccessToken, toggleAccessToken] = useToggle();
const accessToken = ref('');
const botSecret = ref('');

const v$ = useVuelidate(
  {
    botName: {
      required: helpers.withMessage(
        () => t('AGENT_BOTS.FORM.ERRORS.NAME'),
        required
      ),
    },
    botUrl: {
      required: helpers.withMessage(
        () => t('AGENT_BOTS.FORM.ERRORS.URL'),
        required
      ),
      url: helpers.withMessage(
        () => t('AGENT_BOTS.FORM.ERRORS.VALID_URL'),
        url
      ),
    },
    squadronRole: {
      required: helpers.withMessage(
        () => t('AGENT_BOTS.FORM.ERRORS.SQUADRON_ROLE'),
        required
      ),
    },
  },
  formState
);

const squadronRoleOptions = computed(() =>
  SQUADRON_ROLES.map(role => ({
    value: role,
    label: t(`AGENT_BOTS.FORM.SQUADRON_ROLE.ROLES.${role.toUpperCase()}`),
  }))
);

const inboxOptions = computed(() =>
  (allInboxes.value || []).map(inbox => ({
    id: inbox.id,
    name: inbox.name,
    channelType: inbox.channel_type,
  }))
);

const toggleInbox = inboxId => {
  const idx = formState.inboxIds.indexOf(inboxId);
  if (idx === -1) formState.inboxIds.push(inboxId);
  else formState.inboxIds.splice(idx, 1);
};

const isInboxSelected = inboxId => formState.inboxIds.includes(inboxId);

const isLoading = computed(() =>
  props.type === MODAL_TYPES.CREATE
    ? uiFlags.value.isCreating
    : uiFlags.value.isUpdating
);

const dialogTitle = computed(() => {
  if (showAccessToken.value) {
    return t('AGENT_BOTS.ACCESS_TOKEN.TITLE');
  }

  return props.type === MODAL_TYPES.CREATE
    ? t('AGENT_BOTS.ADD.TITLE')
    : t('AGENT_BOTS.EDIT.TITLE');
});

const dialogDescription = computed(() => {
  if (showAccessToken.value) {
    return t('AGENT_BOTS.ACCESS_TOKEN.DESCRIPTION');
  }
  return '';
});

const confirmButtonLabel = computed(() =>
  props.type === MODAL_TYPES.CREATE
    ? t('AGENT_BOTS.FORM.CREATE')
    : t('AGENT_BOTS.FORM.UPDATE')
);

const botNameError = computed(() =>
  v$.value.botName.$error ? v$.value.botName.$errors[0]?.$message : ''
);

const botUrlError = computed(() =>
  v$.value.botUrl.$error ? v$.value.botUrl.$errors[0]?.$message : ''
);

const squadronRoleError = computed(() =>
  v$.value.squadronRole.$error
    ? v$.value.squadronRole.$errors[0]?.$message
    : ''
);

const showAccessTokenInput = computed(
  () =>
    showAccessToken.value ||
    props.type === MODAL_TYPES.EDIT ||
    accessToken.value
);

const resetForm = () => {
  Object.assign(formState, {
    botName: '',
    botDescription: '',
    botUrl: '',
    botAvatar: null,
    botAvatarUrl: '',
    squadronRole: '',
    inboxIds: [],
  });
  v$.value.$reset();
};

const handleImageUpload = ({ file, url: avatarUrl }) => {
  formState.botAvatar = file;
  formState.botAvatarUrl = avatarUrl;
};

const handleAvatarDelete = async () => {
  if (props.selectedBot?.id) {
    try {
      await store.dispatch(
        'agentBots/deleteAgentBotAvatar',
        props.selectedBot.id
      );
      formState.botAvatar = null;
      formState.botAvatarUrl = '';
      useAlert(t('AGENT_BOTS.AVATAR.SUCCESS_DELETE'));
    } catch (error) {
      useAlert(t('AGENT_BOTS.AVATAR.ERROR_DELETE'));
    }
  } else {
    formState.botAvatar = null;
    formState.botAvatarUrl = '';
  }
};

const handleSubmit = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;
  if (showAccessToken.value) return;

  const botData = {
    name: formState.botName,
    description: formState.botDescription,
    outgoing_url: formState.botUrl,
    bot_type: 'webhook',
    avatar: formState.botAvatar,
    // CUSTOMIZAÇÃO_SYNAPSEOS
    squadron_role: formState.squadronRole,
  };

  const isCreate = props.type === MODAL_TYPES.CREATE;

  try {
    const actionPayload = isCreate
      ? botData
      : { id: props.selectedBot.id, data: botData };

    const response = await store.dispatch(
      `agentBots/${isCreate ? 'create' : 'update'}`,
      actionPayload
    );

    const alertKey = isCreate
      ? t('AGENT_BOTS.ADD.API.SUCCESS_MESSAGE')
      : t('AGENT_BOTS.EDIT.API.SUCCESS_MESSAGE');
    useAlert(alertKey);

    // Show access token and secret after creation
    if (isCreate) {
      const {
        access_token: responseAccessToken,
        secret: responseSecret,
        id,
      } = response || {};

      // CUSTOMIZAÇÃO_SYNAPSEOS: associar bot às inboxes escolhidas no wizard.
      if (id && formState.inboxIds.length > 0) {
        await Promise.all(
          formState.inboxIds.map(inboxId =>
            store.dispatch('agentBots/setAgentBotInbox', { inboxId, botId: id })
          )
        );
      }

      if (id && responseAccessToken) {
        accessToken.value = responseAccessToken;
        botSecret.value = responseSecret || '';
        toggleAccessToken(true);
      } else {
        accessToken.value = '';
        botSecret.value = '';
        dialogRef.value.close();
      }
    } else {
      dialogRef.value.close();
    }

    resetForm();
  } catch (error) {
    const errorKey = isCreate
      ? t('AGENT_BOTS.ADD.API.ERROR_MESSAGE')
      : t('AGENT_BOTS.EDIT.API.ERROR_MESSAGE');
    useAlert(errorKey);
  }
};

const initializeForm = () => {
  if (props.selectedBot && Object.keys(props.selectedBot).length) {
    const {
      name,
      description,
      outgoing_url: botUrl,
      thumbnail,
      bot_config: botConfig,
      squadron_role: squadronRole,
      access_token: botAccessToken,
      secret: botSecretValue,
    } = props.selectedBot;
    formState.botName = name || '';
    formState.botDescription = description || '';
    formState.botUrl = botUrl || botConfig?.webhook_url || '';
    formState.botAvatarUrl = thumbnail || '';
    formState.squadronRole = squadronRole || '';

    if (props.type === MODAL_TYPES.EDIT) {
      if (botAccessToken) accessToken.value = botAccessToken;
      if (botSecretValue) botSecret.value = botSecretValue;
    }
  } else {
    resetForm();
  }
};

onMounted(() => {
  // CUSTOMIZAÇÃO_SYNAPSEOS: lista de inboxes alimenta o multi-select do wizard.
  if (!allInboxes.value || allInboxes.value.length === 0) {
    store.dispatch('inboxes/get');
  }
});

const onCopyToken = async value => {
  await copyTextToClipboard(value);
  useAlert(t('AGENT_BOTS.ACCESS_TOKEN.COPY_SUCCESSFUL'));
};

const onCopySecret = async value => {
  await copyTextToClipboard(value || botSecret.value);
  useAlert(t('AGENT_BOTS.SECRET.COPY_SUCCESS'));
};

const onResetSecret = async () => {
  const response = await store.dispatch(
    'agentBots/resetSecret',
    props.selectedBot.id
  );
  if (response) {
    botSecret.value = response.secret;
    useAlert(t('AGENT_BOTS.SECRET.RESET_SUCCESS'));
  } else {
    useAlert(t('AGENT_BOTS.SECRET.RESET_ERROR'));
  }
};

const onResetToken = async () => {
  const response = await store.dispatch(
    'agentBots/resetAccessToken',
    props.selectedBot.id
  );
  if (response) {
    accessToken.value = response.access_token;
    useAlert(t('AGENT_BOTS.ACCESS_TOKEN.RESET_SUCCESS'));
  } else {
    useAlert(t('AGENT_BOTS.ACCESS_TOKEN.RESET_ERROR'));
  }
};

const closeModal = () => {
  if (!showAccessToken.value) v$.value?.$reset();
  accessToken.value = '';
  botSecret.value = '';
  toggleAccessToken(false);
};

const onClickClose = () => {
  closeModal();
  dialogRef.value.close();
};

watch(() => props.selectedBot, initializeForm, { immediate: true, deep: true });

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    :title="dialogTitle"
    :description="dialogDescription"
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="closeModal"
  >
    <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
      <div
        v-if="!showAccessToken || type === MODAL_TYPES.EDIT"
        class="flex flex-col gap-4"
      >
        <div class="mb-2 flex flex-col items-start">
          <span class="mb-2 text-sm font-medium text-s-primary">
            {{ $t('AGENT_BOTS.FORM.AVATAR.LABEL') }}
          </span>
          <Avatar
            :src="formState.botAvatarUrl"
            :name="formState.botName"
            :size="68"
            allow-upload
            icon-name="i-lucide-bot-message-square"
            @upload="handleImageUpload"
            @delete="handleAvatarDelete"
          />
        </div>

        <Input
          id="bot-name"
          v-model="formState.botName"
          :label="$t('AGENT_BOTS.FORM.NAME.LABEL')"
          :placeholder="$t('AGENT_BOTS.FORM.NAME.PLACEHOLDER')"
          :message="botNameError"
          :message-type="botNameError ? 'error' : 'info'"
          @blur="v$.botName.$touch()"
        />

        <TextArea
          id="bot-description"
          v-model="formState.botDescription"
          :label="$t('AGENT_BOTS.FORM.DESCRIPTION.LABEL')"
          :placeholder="$t('AGENT_BOTS.FORM.DESCRIPTION.PLACEHOLDER')"
        />

        <Input
          id="bot-url"
          v-model="formState.botUrl"
          :label="$t('AGENT_BOTS.FORM.WEBHOOK_URL.LABEL')"
          :placeholder="$t('AGENT_BOTS.FORM.WEBHOOK_URL.PLACEHOLDER')"
          :message="botUrlError"
          :message-type="botUrlError ? 'error' : 'info'"
          @blur="v$.botUrl.$touch()"
        />

        <!-- CUSTOMIZAÇÃO_SYNAPSEOS: papel do Esquadrão — obrigatório -->
        <div class="flex flex-col gap-1">
          <label class="mb-0.5 text-sm font-medium text-s-primary">
            {{ $t('AGENT_BOTS.FORM.SQUADRON_ROLE.LABEL') }}
          </label>
          <Select
            v-model="formState.squadronRole"
            class="!w-full"
            :options="squadronRoleOptions"
            :placeholder="$t('AGENT_BOTS.FORM.SQUADRON_ROLE.PLACEHOLDER')"
            :error="squadronRoleError"
            @blur="v$.squadronRole.$touch()"
          />
          <p v-if="!squadronRoleError" class="text-xs text-s-muted">
            {{ $t('AGENT_BOTS.FORM.SQUADRON_ROLE.HINT') }}
          </p>
        </div>

        <!-- CUSTOMIZAÇÃO_SYNAPSEOS: inboxes a conectar (opcional, só no create) -->
        <div v-if="type === MODAL_TYPES.CREATE" class="flex flex-col gap-1">
          <label class="mb-0.5 text-sm font-medium text-s-primary">
            {{ $t('AGENT_BOTS.FORM.INBOXES.LABEL') }}
          </label>
          <div
            v-if="inboxOptions.length > 0"
            class="flex flex-col gap-2 p-3 rounded-lg border border-s-border bg-s-surface max-h-48 overflow-y-auto"
          >
            <label
              v-for="inbox in inboxOptions"
              :key="inbox.id"
              class="flex items-center gap-2 cursor-pointer text-sm text-s-primary"
            >
              <input
                type="checkbox"
                :checked="isInboxSelected(inbox.id)"
                class="rounded border-s-border text-s-brand focus:ring-s-brand"
                @change="toggleInbox(inbox.id)"
              >
              <span>{{ inbox.name }}</span>
              <span class="text-xs text-s-muted">{{ inbox.channelType }}</span>
            </label>
          </div>
          <p v-else class="text-xs text-s-muted">
            {{ $t('AGENT_BOTS.FORM.INBOXES.NONE') }}
          </p>
          <p class="text-xs text-s-muted">
            {{ $t('AGENT_BOTS.FORM.INBOXES.HINT') }}
          </p>
        </div>
      </div>

      <div
        v-if="botSecret && type === MODAL_TYPES.EDIT"
        class="flex flex-col gap-1"
      >
        <label class="mb-0.5 text-sm font-medium text-s-primary">
          {{ $t('AGENT_BOTS.SECRET.LABEL') }}
        </label>
        <AccessToken
          :value="botSecret"
          @on-copy="onCopySecret"
          @on-reset="onResetSecret"
        />
      </div>

      <div v-if="showAccessTokenInput" class="flex flex-col gap-1">
        <label
          v-if="type === MODAL_TYPES.EDIT"
          class="mb-0.5 text-sm font-medium text-s-primary"
        >
          {{ $t('AGENT_BOTS.ACCESS_TOKEN.TITLE') }}
        </label>
        <AccessToken
          v-if="type === MODAL_TYPES.EDIT"
          :value="accessToken"
          @on-copy="onCopyToken"
          @on-reset="onResetToken"
        />
        <AccessToken
          v-else
          :value="accessToken"
          :show-reset-button="false"
          @on-copy="onCopyToken"
        />
      </div>

      <div
        v-if="botSecret && showAccessToken && type === MODAL_TYPES.CREATE"
        class="flex flex-col gap-1"
      >
        <p class="text-sm text-s-muted">
          {{ $t('AGENT_BOTS.SECRET.CREATED_DESC') }}
        </p>
        <label class="mb-0.5 text-sm font-medium text-s-primary">
          {{ $t('AGENT_BOTS.SECRET.LABEL') }}
        </label>
        <AccessToken
          :value="botSecret"
          :show-reset-button="false"
          @on-copy="onCopySecret"
        />
      </div>

      <div class="flex items-center justify-end w-full gap-2 px-0 py-2">
        <NextButton
          faded
          slate
          type="reset"
          :label="$t('AGENT_BOTS.FORM.CANCEL')"
          @click="onClickClose()"
        />
        <NextButton
          v-if="!showAccessToken"
          type="submit"
          data-testid="label-submit"
          :label="confirmButtonLabel"
          :is-loading="isLoading"
          :disabled="v$.$invalid"
        />
      </div>
    </form>
  </Dialog>
</template>
