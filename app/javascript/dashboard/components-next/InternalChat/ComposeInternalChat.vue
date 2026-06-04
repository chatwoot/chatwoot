<script setup>
import { computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
import { useAlert } from 'dashboard/composables';
import InternalConversationsAPI from 'dashboard/api/internalConversations';
import Avatar from 'next/avatar/Avatar.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import MultiselectDropdownItems from 'shared/components/ui/MultiselectDropdownItems.vue';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';
import FileUpload from 'vue-upload-component';
import { DirectUpload } from 'activestorage';
import {
  ALLOWED_FILE_TYPES,
  MAXIMUM_FILE_UPLOAD_SIZE,
} from 'shared/constants/messages';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';

const props = defineProps({
  alignPosition: {
    type: String,
    default: 'left',
  },
});

const emit = defineEmits(['close']);

const { t } = useI18n();
const router = useRouter();
const store = useStore();
const { accountId } = useAccount();
const globalConfig = useMapGetter('globalConfig/get');

const agents = useMapGetter('agents/getVerifiedAgents');
const currentUser = useMapGetter('getCurrentUser');
const inboxes = useMapGetter('inboxes/getInboxes');

const showCompose = ref(false);
const showParticipantsDropdown = ref(false);
const selectedInboxId = ref(null);
const selectedParticipants = ref([]);
const title = ref('');
const message = ref('');
const isSubmitting = ref(false);
const isUploadingAttachment = ref(false);
const attachments = ref([]);

const internalInboxes = computed(() =>
  inboxes.value.filter(inbox => inbox.channel_type === 'Channel::Internal')
);

const selectedInbox = computed(() =>
  internalInboxes.value.find(
    inbox => inbox.id === Number(selectedInboxId.value)
  )
);

const canSubmit = computed(
  () =>
    selectedInbox.value &&
    selectedParticipants.value.length > 0 &&
    (message.value.trim().length > 0 || attachments.value.length > 0) &&
    !isSubmitting.value &&
    !isUploadingAttachment.value
);

// Sempre usar o modo modal para que o backdrop e o conteúdo fiquem centralizados
// e não presos à largura da sidebar.
const viewInModal = computed(() => true);

const composePopoverClass = computed(() => {
  if (viewInModal.value) return '';
  return props.alignPosition === 'right'
    ? 'absolute ltr:left-0 ltr:right-[unset] rtl:right-0 rtl:left-[unset]'
    : 'absolute rtl:left-0 rtl:right-[unset] ltr:right-0 ltr:left-[unset]';
});

const toggle = () => {
  showCompose.value = !showCompose.value;
  if (!showCompose.value) emit('close');
};

const resetForm = () => {
  selectedInboxId.value = null;
  selectedParticipants.value = [];
  title.value = '';
  message.value = '';
  attachments.value = [];
};

const handleClickOutside = () => {
  if (!showCompose.value) return;
  showCompose.value = false;
  showParticipantsDropdown.value = false;
  resetForm();
  emit('close');
};

const onSelectParticipant = user => {
  const exists = selectedParticipants.value.some(
    participant => participant.id === user.id
  );
  if (exists) {
    selectedParticipants.value = selectedParticipants.value.filter(
      participant => participant.id !== user.id
    );
  } else {
    selectedParticipants.value = [...selectedParticipants.value, user];
  }
};

const onSelfAdd = user => {
  if (!user?.id) return;
  if (!selectedParticipants.value.some(p => p.id === user.id)) {
    selectedParticipants.value = [...selectedParticipants.value, user];
  }
};

const maxUploadSize = computed(
  () =>
    Number(globalConfig.value?.maxFileUploadSizeInMb) ||
    MAXIMUM_FILE_UPLOAD_SIZE
);

const onFileUpload = file => {
  if (!file?.file) return;

  if (!checkFileSizeLimit(file, maxUploadSize.value)) {
    useAlert(
      t('CONVERSATION.FILE_SIZE_LIMIT', {
        MAXIMUM_SUPPORTED_FILE_UPLOAD_SIZE: maxUploadSize.value,
      })
    );
    return;
  }

  isUploadingAttachment.value = true;
  const upload = new DirectUpload(
    file.file,
    '/rails/active_storage/direct_uploads',
    {
      directUploadWillCreateBlobWithXHR: xhr => {
        if (currentUser.value?.access_token) {
          xhr.setRequestHeader(
            'api_access_token',
            currentUser.value.access_token
          );
        }
      },
    }
  );

  upload.create((error, blob) => {
    isUploadingAttachment.value = false;
    if (error) {
      useAlert(error);
      return;
    }

    attachments.value = [
      ...attachments.value,
      {
        signedId: blob.signed_id,
        filename: blob.filename,
        byteSize: blob.byte_size,
        contentType: blob.content_type,
      },
    ];
  });
};

const removeAttachment = signedId => {
  attachments.value = attachments.value.filter(
    file => file.signedId !== signedId
  );
};

const buildMessagePayload = () => {
  const trimmedContent = message.value.trim();
  const payload = {
    content: trimmedContent,
    attachments: attachments.value.map(file => file.signedId),
  };

  return payload;
};

const createInternalConversation = async () => {
  if (!canSubmit.value) return;
  isSubmitting.value = true;
  try {
    const payload = {
      inbox_id: selectedInbox.value.id,
      title: title.value,
      participant_ids: selectedParticipants.value.map(user => user.id),
      message: buildMessagePayload(),
    };
    const { data } = await InternalConversationsAPI.create(payload);
    const conversationLink = frontendURL(
      conversationUrl({
        accountId: accountId.value,
        id: data.id,
      })
    );

    useAlert(t('CONVERSATION.INTERNAL_CHAT.SUCCESS'), {
      type: 'link',
      to: conversationLink,
      message: t('CONVERSATION.INTERNAL_CHAT.GO_TO_CONVERSATION'),
    });

    router.push(conversationLink);
    resetForm();
    showCompose.value = false;
  } catch (error) {
    const errorMessage =
      error?.response?.data?.error || t('CONVERSATION.INTERNAL_CHAT.ERROR');
    useAlert(errorMessage);
  } finally {
    isSubmitting.value = false;
  }
};

onMounted(() => {
  store.dispatch('agents/get');
  store.dispatch('inboxes/get');
});
</script>

<template>
  <div class="relative">
    <slot name="trigger" :is-open="showCompose" :toggle="toggle" />

    <TeleportWithDirection to="body">
      <div
        v-if="showCompose"
        class="fixed z-50 bg-n-alpha-black1 backdrop-blur-[4px] flex items-start pt-[clamp(3rem,15vh,12rem)] justify-center inset-0"
        @click.self="handleClickOutside"
      >
        <div
          :class="[{ 'mt-2': !viewInModal }, composePopoverClass]"
          class="w-[42rem] max-w-full min-w-0 max-h-[min(92vh,48rem)] bg-n-alpha-3 border border-n-strong shadow-sm backdrop-blur-[100px] rounded-xl divide-y divide-n-strong overflow-hidden transition-all duration-300 ease-in-out flex flex-col"
        >
          <div class="p-4 md:p-6 flex items-start justify-between gap-3">
            <div>
              <p class="m-0 text-base font-semibold text-n-slate-12">
                {{ $t('CONVERSATION.INTERNAL_CHAT.TITLE') }}
              </p>
              <p class="m-0 text-sm text-n-slate-10">
                {{ $t('CONVERSATION.INTERNAL_CHAT.DESCRIPTION') }}
              </p>
            </div>
            <NextButton
              icon="i-lucide-x"
              slate
              ghost
              sm
              class="self-start"
              @click="handleClickOutside"
            />
          </div>

          <div class="p-4 md:p-6 overflow-y-auto min-h-0">
            <div
              v-if="!internalInboxes.length"
              class="p-3 bg-n-alpha-2 rounded-lg"
            >
              <p class="m-0 text-sm text-n-slate-11">
                {{ $t('CONVERSATION.INTERNAL_CHAT.NO_INBOX') }}
              </p>
            </div>

            <div v-else class="grid gap-4">
              <div class="grid gap-1">
                <label class="text-sm font-medium text-n-slate-12">
                  {{ $t('CONVERSATION.INTERNAL_CHAT.INBOX_LABEL') }}
                </label>
                <select
                  v-model.number="selectedInboxId"
                  class="w-full px-3 py-2 rounded-lg border border-n-strong bg-n-solid-1 text-sm text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-woot-500"
                >
                  <option :value="null" disabled>
                    {{ $t('CONVERSATION.INTERNAL_CHAT.INBOX_PLACEHOLDER') }}
                  </option>
                  <option
                    v-for="inbox in internalInboxes"
                    :key="inbox.id"
                    :value="inbox.id"
                  >
                    {{ inbox.name }}
                  </option>
                </select>
              </div>

              <div class="grid gap-1">
                <label class="text-sm font-medium text-n-slate-12">
                  {{ $t('CONVERSATION.INTERNAL_CHAT.TITLE_LABEL') }}
                  <span class="text-n-slate-9">
                    {{ `(${$t('CONVERSATION.INTERNAL_CHAT.OPTIONAL')})` }}
                  </span>
                </label>
                <input
                  v-model="title"
                  type="text"
                  class="w-full px-3 py-2 rounded-lg border border-n-strong bg-n-solid-1 text-sm text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-woot-500"
                  :placeholder="
                    $t('CONVERSATION.INTERNAL_CHAT.TITLE_PLACEHOLDER')
                  "
                />
              </div>

              <div class="grid gap-2">
                <div class="flex items-center justify-between">
                  <label class="text-sm font-medium text-n-slate-12">
                    {{ $t('CONVERSATION.INTERNAL_CHAT.PARTICIPANTS_LABEL') }}
                  </label>
                  <NextButton
                    v-if="!showParticipantsDropdown"
                    ghost
                    slate
                    xs
                    icon="i-lucide-plus"
                    @click="showParticipantsDropdown = true"
                  />
                  <NextButton
                    v-else
                    ghost
                    slate
                    xs
                    icon="i-lucide-x"
                    @click="showParticipantsDropdown = false"
                  />
                </div>
                <div class="flex flex-wrap gap-2">
                  <div
                    v-for="participant in selectedParticipants"
                    :key="participant.id"
                    class="inline-flex items-center gap-2 px-2 py-1 rounded-full bg-n-alpha-2 text-sm text-n-slate-12"
                  >
                    <Avatar
                      :src="participant.avatar_url"
                      :name="participant.name"
                      :size="22"
                      hide-offline-status
                      rounded-full
                    />
                    <span class="max-w-[10rem] truncate">
                      {{ participant.name }}
                    </span>
                    <NextButton
                      ghost
                      slate
                      xs
                      icon="i-lucide-x"
                      @click="onSelectParticipant(participant)"
                    />
                  </div>
                  <p
                    v-if="!selectedParticipants.length"
                    class="m-0 text-sm text-n-slate-10"
                  >
                    {{
                      $t('CONVERSATION.INTERNAL_CHAT.NO_PARTICIPANT_SELECTED')
                    }}
                  </p>
                </div>
                <div
                  v-if="showParticipantsDropdown"
                  class="relative border border-n-strong rounded-lg"
                >
                  <div class="p-2 flex justify-between items-center">
                    <p class="m-0 text-sm font-medium text-n-slate-12">
                      {{ $t('CONVERSATION.INTERNAL_CHAT.ADD_PARTICIPANTS') }}
                    </p>
                    <NextButton
                      ghost
                      xs
                      icon="i-lucide-user-plus"
                      @click="onSelfAdd(currentUser)"
                    >
                      {{ $t('CONVERSATION.INTERNAL_CHAT.ADD_ME') }}
                    </NextButton>
                  </div>
                  <MultiselectDropdownItems
                    :options="agents"
                    :selected-items="selectedParticipants"
                    :input-placeholder="
                      $t('CONVERSATION.INTERNAL_CHAT.SEARCH_PARTICIPANTS')
                    "
                    @select="onSelectParticipant"
                  />
                </div>
              </div>

              <div class="grid gap-1">
                <label class="text-sm font-medium text-n-slate-12">
                  {{ $t('CONVERSATION.INTERNAL_CHAT.MESSAGE_LABEL') }}
                </label>
                <textarea
                  v-model="message"
                  rows="3"
                  class="w-full px-3 py-2 rounded-lg border border-n-strong bg-n-solid-1 text-sm text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-woot-500 resize-none"
                  :placeholder="
                    $t('CONVERSATION.INTERNAL_CHAT.MESSAGE_PLACEHOLDER')
                  "
                />
              </div>

              <div class="grid gap-2">
                <div class="flex items-center justify-between">
                  <p class="m-0 text-sm font-medium text-n-slate-12">
                    {{ $t('CONVERSATION.REPLYBOX.TIP_ATTACH_ICON') }}
                  </p>
                  <p
                    v-if="isUploadingAttachment"
                    class="m-0 text-xs text-n-slate-10"
                  >
                    {{ $t('CONVERSATION.UPLOADING_ATTACHMENTS') }}
                  </p>
                </div>

                <div class="flex flex-wrap gap-2">
                  <div
                    v-for="file in attachments"
                    :key="file.signedId"
                    class="inline-flex items-center gap-2 px-2 py-1 rounded-full bg-n-alpha-2 text-xs text-n-slate-12"
                  >
                    <span class="truncate max-w-[14rem]">
                      {{ file.filename }}
                    </span>
                    <NextButton
                      ghost
                      slate
                      xs
                      icon="i-lucide-x"
                      @click="removeAttachment(file.signedId)"
                    />
                  </div>
                </div>

                <FileUpload
                  input-id="composeInternalAttachment"
                  :accept="ALLOWED_FILE_TYPES"
                  multiple
                  :drop-directory="false"
                  :data="{
                    direct_upload_url: '/rails/active_storage/direct_uploads',
                    direct_upload: true,
                  }"
                  class="p-px"
                  @input-file="onFileUpload"
                >
                  <NextButton
                    icon="i-lucide-paperclip"
                    slate
                    ghost
                    sm
                    class="!w-10"
                    :aria-label="$t('CONVERSATION.REPLYBOX.TIP_ATTACH_ICON')"
                  />
                </FileUpload>
              </div>

              <div class="flex justify-end gap-2">
                <NextButton slate ghost sm @click="handleClickOutside">
                  {{ $t('CONVERSATION.INTERNAL_CHAT.CANCEL') }}
                </NextButton>
                <NextButton
                  blue
                  solid
                  sm
                  :is-loading="isSubmitting"
                  :disabled="!canSubmit"
                  @click="createInternalConversation"
                >
                  {{ $t('CONVERSATION.INTERNAL_CHAT.SUBMIT') }}
                </NextButton>
              </div>
            </div>
          </div>
        </div>
      </div>
    </TeleportWithDirection>
  </div>
</template>
