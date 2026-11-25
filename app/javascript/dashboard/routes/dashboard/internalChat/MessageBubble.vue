<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import MessageFormatter from 'shared/helpers/MessageFormatter';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
import { useAlert } from 'dashboard/composables';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Popover from 'dashboard/components-next/popover/Popover.vue';
import ReactionDisplay from './ReactionDisplay.vue';
import EmojiReactionPicker from './EmojiReactionPicker.vue';
import { QUICK_EMOJIS, findOwnReaction } from './reactions';
import PollDisplay from './PollDisplay.vue';
import ConversationPreviewCard from './ConversationPreviewCard.vue';

const props = defineProps({
  message: {
    type: Object,
    required: true,
  },
  currentUserId: {
    type: Number,
    required: true,
  },
  isAdmin: {
    type: Boolean,
    default: false,
  },
  inThread: {
    type: Boolean,
    default: false,
  },
  groupWithPrevious: {
    type: Boolean,
    default: false,
  },
  groupWithNext: {
    type: Boolean,
    default: false,
  },
  hasThreadDraft: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'edit',
  'delete',
  'reply',
  'openThread',
  'addReaction',
  'removeReaction',
  'pin',
  'unpin',
  'vote',
  'unvote',
]);

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const accountId = useMapGetter('getCurrentAccountId');

const senderName = computed(() => {
  return props.message.sender?.name || t('INTERNAL_CHAT.MESSAGE.DELETED_USER');
});

const senderAvatar = computed(() => {
  return props.message.sender?.avatar_url || '';
});

const senderAvailability = computed(() => {
  const senderId = props.message.sender?.id;
  if (!senderId) return null;
  const agent = store.getters['agents/getAgentById'](senderId);
  return agent?.availability_status || null;
});

const timestamp = computed(() => {
  const createdAt = props.message.created_at;
  if (!createdAt) return '';
  const unixTime =
    typeof createdAt === 'number'
      ? createdAt
      : Math.floor(new Date(createdAt).getTime() / 1000);
  return messageTimestamp(unixTime, 'h:mm a');
});

const isOwnMessage = computed(() => {
  return props.message.sender?.id === props.currentUserId;
});

const isEdited = computed(() => {
  return !!props.message.content_attributes?.edited_at;
});

const isDeleted = computed(() => {
  return !!props.message.content_attributes?.deleted;
});

const isPoll = computed(() => {
  return props.message.content_type === 'poll';
});

const isPinned = computed(() => {
  return !!props.message.content_attributes?.pinned;
});

const threadReplyCount = computed(() => {
  return props.message.replies_count || 0;
});

const canEdit = computed(() => {
  return isOwnMessage.value && !isDeleted.value && !isPoll.value;
});

const canDelete = computed(() => {
  return (isOwnMessage.value || props.isAdmin) && !isDeleted.value;
});

const canPin = computed(() => {
  return !isDeleted.value;
});

const messageContent = computed(() => {
  if (isDeleted.value) {
    return t('INTERNAL_CHAT.MESSAGE.DELETED');
  }
  return props.message.content || '';
});

const renderedContent = computed(() => {
  if (isDeleted.value) return '';
  const formatter = new MessageFormatter(props.message.content || '');
  return formatter.formattedMessage;
});

const reactions = computed(() => {
  return props.message.reactions || [];
});

const conversationRefs = computed(() => {
  if (isDeleted.value || !props.message.content) return [];
  const matches = props.message.content.matchAll(
    /mention:\/\/conversation\/(\d+)\//g
  );
  return [...new Set([...matches].map(m => m[1]))];
});

function handleContentClick(event) {
  const mention = event.target.closest('.prosemirror-mention-conversation');
  if (!mention) return;
  const displayId = mention.dataset.conversationId;
  if (!displayId) return;
  const url = frontendURL(
    conversationUrl({ accountId: accountId.value, id: displayId })
  );
  if (event.ctrlKey || event.metaKey) {
    window.open(url, '_blank');
  } else {
    router.push(url);
  }
}

function attachmentFileName(attachment) {
  if (attachment.file_url) {
    const url = attachment.file_url.split('?')[0];
    const name = decodeURIComponent(url.split('/').pop());
    if (name && name !== 'null') return name;
  }
  const ext = attachment.extension ? `.${attachment.extension}` : '';
  return `${attachment.file_type || 'file'}${ext}`;
}

const attachments = computed(() => {
  if (isDeleted.value) return [];
  return props.message.attachments || [];
});

const deleteDialogRef = ref(null);

function handleEdit() {
  emit('edit', props.message);
}

function handleDelete() {
  deleteDialogRef.value?.open();
}

function confirmDelete() {
  emit('delete', props.message);
  deleteDialogRef.value?.close();
}

function handleReply() {
  emit('reply', props.message);
}

function handleOpenThread() {
  emit('openThread', props.message);
}

function handlePin() {
  if (isPinned.value) {
    emit('unpin', props.message);
  } else {
    emit('pin', props.message);
  }
}

function handleCopyLink() {
  const baseUrl = window.chatwootConfig?.hostURL || window.location.origin;
  const path = window.location.pathname;
  const params = [`messageId=${props.message.id}`];
  if (props.message.parent_id) {
    params.push(`parentId=${props.message.parent_id}`);
  }
  const url = `${baseUrl}${path}?${params.join('&')}`;
  copyTextToClipboard(url);
  useAlert(t('INTERNAL_CHAT.MESSAGE.LINK_COPIED'));
}

function handleAddReaction(emoji) {
  emit('addReaction', { messageId: props.message.id, emoji });
}

function handleRemoveReaction(reactionId) {
  emit('removeReaction', {
    messageId: props.message.id,
    reactionId,
  });
}

// Used by the touch action menu, where the emoji row reacts inline instead of
// nesting EmojiReactionPicker inside the popover.
function toggleReaction(emoji) {
  const own = findOwnReaction(reactions.value, emoji, props.currentUserId);
  if (own) {
    handleRemoveReaction(own.id);
  } else {
    handleAddReaction(emoji);
  }
}

function handleVote(payload) {
  emit('vote', payload);
}

function handleUnvote(payload) {
  emit('unvote', payload);
}
</script>

<template>
  <div
    class="group relative flex items-start gap-3 px-4 hover:bg-n-alpha-1 transition-colors"
    :class="groupWithPrevious ? 'py-0.5' : 'py-1.5'"
  >
    <div v-if="!groupWithPrevious" class="flex-shrink-0 pt-0.5">
      <Avatar
        :name="senderName"
        :src="senderAvatar"
        :size="32"
        :status="senderAvailability"
        hide-offline-status
      />
    </div>
    <div v-else class="w-8 flex-shrink-0" />
    <div class="flex-1 min-w-0">
      <div v-if="!groupWithPrevious" class="flex items-baseline gap-2">
        <span class="text-sm font-medium text-n-slate-12">
          {{ senderName }}
        </span>
        <time class="text-xs text-n-slate-10">{{ timestamp }}</time>
        <span v-if="isEdited" class="text-xs text-n-slate-10">
          {{ t('INTERNAL_CHAT.MESSAGE.EDITED') }}
        </span>
        <span
          v-if="isPinned"
          class="flex items-center gap-1 text-xs text-n-amber-11"
          :title="t('INTERNAL_CHAT.PIN.PINNED_MESSAGE')"
        >
          <Icon icon="i-lucide-pin" class="size-3" />
        </span>
      </div>

      <!-- Poll content -->
      <div v-if="isPoll && !isDeleted" class="mt-1">
        <PollDisplay
          :message="message"
          :current-user-id="currentUserId"
          :is-admin="isAdmin"
          @vote="handleVote"
          @unvote="handleUnvote"
        />
      </div>

      <!-- Regular message content -->
      <div
        v-else
        class="text-sm text-n-slate-12 break-words"
        :class="groupWithPrevious ? '' : 'mt-0.5'"
      >
        <div
          v-if="isDeleted"
          class="flex items-center gap-1.5 rounded-lg bg-n-alpha-1 px-3 py-2 text-n-slate-10"
        >
          <Icon icon="i-lucide-trash-2" class="size-3.5 flex-shrink-0" />
          <span class="italic">{{ messageContent }}</span>
        </div>
        <div
          v-else
          class="inline [&_.prosemirror-mention-node]:font-semibold [&_.prosemirror-mention-node]:text-n-brand [&_.prosemirror-mention-conversation]:cursor-pointer [&_.prosemirror-mention-conversation]:underline"
          @click="handleContentClick"
        >
          <div
            v-dompurify-html="renderedContent"
            class="prose prose-bubble inline"
          />
          <span
            v-if="groupWithPrevious && isEdited"
            class="ml-1 text-xs text-n-slate-10"
          >
            {{ t('INTERNAL_CHAT.MESSAGE.EDITED') }}
          </span>
        </div>
        <!-- Conversation mention preview cards -->
        <ConversationPreviewCard
          v-for="displayId in conversationRefs"
          :key="`conv-${displayId}`"
          :display-id="displayId"
          :account-id="accountId"
        />
      </div>

      <!-- Attachments -->
      <div v-if="attachments.length" class="mt-1.5 flex flex-wrap gap-2">
        <template v-for="attachment in attachments" :key="attachment.id">
          <a
            v-if="attachment.file_type === 'image'"
            :href="attachment.file_url || attachment.external_url"
            target="_blank"
            rel="noopener noreferrer"
            class="block overflow-hidden rounded-lg border border-n-slate-6"
          >
            <img
              :src="attachment.file_url || attachment.external_url"
              class="max-h-60 max-w-xs object-cover"
              loading="lazy"
            />
          </a>
          <a
            v-else
            :href="attachment.file_url || attachment.external_url"
            target="_blank"
            rel="noopener noreferrer"
            class="flex items-center gap-1.5 rounded-lg border border-n-slate-6 bg-n-alpha-1 px-2.5 py-1.5 text-xs text-n-slate-12 hover:bg-n-alpha-2"
          >
            <Icon icon="i-lucide-paperclip" class="size-3.5 text-n-slate-10" />
            <span class="max-w-48 truncate">
              {{ attachmentFileName(attachment) }}
            </span>
          </a>
        </template>
      </div>

      <ReactionDisplay
        :reactions="reactions"
        :current-user-id="currentUserId"
        @remove="handleRemoveReaction"
      />

      <!-- Thread link / reply count -->
      <div
        v-if="
          !inThread &&
          ((message.parent_id && !groupWithNext) ||
            threadReplyCount > 0 ||
            hasThreadDraft)
        "
        class="mt-1 flex items-center gap-2"
      >
        <button
          v-if="message.parent_id && !groupWithNext"
          class="flex items-center gap-1 text-xs font-medium text-n-brand hover:underline"
          @click="handleOpenThread"
        >
          <Icon icon="i-lucide-message-square" class="size-3" />
          {{ t('INTERNAL_CHAT.THREAD.TITLE') }}
        </button>
        <button
          v-else-if="threadReplyCount > 0"
          class="flex items-center gap-1 text-xs font-medium text-n-brand hover:underline"
          @click="handleOpenThread"
        >
          <Icon icon="i-lucide-message-square" class="size-3" />
          {{ t('INTERNAL_CHAT.THREAD.REPLIES', { count: threadReplyCount }) }}
        </button>
        <button
          v-if="hasThreadDraft"
          class="flex items-center gap-1 text-xs font-medium text-n-amber-11 hover:underline"
          @click="handleOpenThread"
        >
          <Icon icon="i-lucide-file-edit" class="size-3" />
          {{ t('INTERNAL_CHAT.DRAFT.LABEL') }}
        </button>
      </div>
    </div>
    <div
      v-if="!isDeleted"
      class="absolute right-2 top-0 hidden items-center gap-0.5 rounded-md bg-n-solid-2 border border-n-slate-5 shadow-sm px-0.5 py-0.5 opacity-0 group-hover:opacity-100 group-focus-within:opacity-100 transition-opacity z-10 md:flex"
    >
      <EmojiReactionPicker
        :reactions="reactions"
        :current-user-id="currentUserId"
        @select="handleAddReaction"
        @remove="handleRemoveReaction"
      />
      <button
        v-if="!inThread"
        class="flex items-center justify-center rounded p-1 text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12"
        :title="t('INTERNAL_CHAT.MESSAGE.REPLY')"
        @click="handleReply"
      >
        <Icon icon="i-lucide-reply" class="size-4" />
      </button>
      <button
        class="flex items-center justify-center rounded p-1 text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12"
        :title="t('INTERNAL_CHAT.MESSAGE.COPY_LINK')"
        @click="handleCopyLink"
      >
        <Icon icon="i-lucide-link" class="size-4" />
      </button>
      <button
        v-if="canPin && !inThread"
        class="flex items-center justify-center rounded p-1 text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12"
        :title="
          isPinned ? t('INTERNAL_CHAT.PIN.UNPIN') : t('INTERNAL_CHAT.PIN.PIN')
        "
        @click="handlePin"
      >
        <Icon
          :icon="isPinned ? 'i-lucide-pin-off' : 'i-lucide-pin'"
          class="size-4"
        />
      </button>
      <button
        v-if="canEdit"
        class="flex items-center justify-center rounded p-1 text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12"
        :title="t('INTERNAL_CHAT.MESSAGE.EDIT')"
        @click="handleEdit"
      >
        <Icon icon="i-lucide-pencil" class="size-4" />
      </button>
      <button
        v-if="canDelete"
        class="flex items-center justify-center rounded p-1 text-n-slate-11 hover:bg-n-ruby-3 hover:text-n-ruby-11"
        :title="t('INTERNAL_CHAT.MESSAGE.DELETE')"
        @click="handleDelete"
      >
        <Icon icon="i-lucide-trash-2" class="size-4" />
      </button>
    </div>

    <!-- Touch: the hover toolbar above is unreachable, so the same actions live
    in a popover, which the design system renders as a modal below md. -->
    <div v-if="!isDeleted" class="absolute right-2 top-0 z-10 md:hidden">
      <Popover>
        <template #default>
          <button
            type="button"
            class="flex items-center justify-center rounded-md border border-n-slate-5 bg-n-solid-2 p-1.5 text-n-slate-11 shadow-sm"
            :title="t('INTERNAL_CHAT.MESSAGE.MORE_ACTIONS')"
            :aria-label="t('INTERNAL_CHAT.MESSAGE.MORE_ACTIONS')"
          >
            <Icon icon="i-lucide-ellipsis" class="size-4" />
          </button>
        </template>
        <template #content="{ hide }">
          <div class="flex min-w-56 flex-col p-1.5">
            <div class="grid grid-cols-8 gap-0.5 border-b border-n-weak pb-1.5">
              <button
                v-for="item in QUICK_EMOJIS"
                :key="item.labelKey"
                type="button"
                class="flex min-w-0 items-center justify-center rounded p-1 text-base hover:bg-n-alpha-2"
                :title="t(`INTERNAL_CHAT.REACTIONS.${item.labelKey}`)"
                :aria-label="t(`INTERNAL_CHAT.REACTIONS.${item.labelKey}`)"
                @click="
                  hide();
                  toggleReaction(item.emoji);
                "
              >
                {{ item.emoji }}
              </button>
            </div>
            <button
              v-if="!inThread"
              type="button"
              class="flex items-center gap-2 rounded-lg px-2 py-2 text-sm text-n-slate-12 hover:bg-n-alpha-2"
              @click="
                hide();
                handleReply();
              "
            >
              <Icon icon="i-lucide-reply" class="size-4 text-n-slate-11" />
              {{ t('INTERNAL_CHAT.MESSAGE.REPLY') }}
            </button>
            <button
              type="button"
              class="flex items-center gap-2 rounded-lg px-2 py-2 text-sm text-n-slate-12 hover:bg-n-alpha-2"
              @click="
                hide();
                handleCopyLink();
              "
            >
              <Icon icon="i-lucide-link" class="size-4 text-n-slate-11" />
              {{ t('INTERNAL_CHAT.MESSAGE.COPY_LINK') }}
            </button>
            <button
              v-if="canPin && !inThread"
              type="button"
              class="flex items-center gap-2 rounded-lg px-2 py-2 text-sm text-n-slate-12 hover:bg-n-alpha-2"
              @click="
                hide();
                handlePin();
              "
            >
              <Icon
                :icon="isPinned ? 'i-lucide-pin-off' : 'i-lucide-pin'"
                class="size-4 text-n-slate-11"
              />
              {{
                isPinned
                  ? t('INTERNAL_CHAT.PIN.UNPIN')
                  : t('INTERNAL_CHAT.PIN.PIN')
              }}
            </button>
            <button
              v-if="canEdit"
              type="button"
              class="flex items-center gap-2 rounded-lg px-2 py-2 text-sm text-n-slate-12 hover:bg-n-alpha-2"
              @click="
                hide();
                handleEdit();
              "
            >
              <Icon icon="i-lucide-pencil" class="size-4 text-n-slate-11" />
              {{ t('INTERNAL_CHAT.MESSAGE.EDIT') }}
            </button>
            <button
              v-if="canDelete"
              type="button"
              class="flex items-center gap-2 rounded-lg px-2 py-2 text-sm text-n-ruby-11 hover:bg-n-ruby-3"
              @click="
                hide();
                handleDelete();
              "
            >
              <Icon icon="i-lucide-trash-2" class="size-4" />
              {{ t('INTERNAL_CHAT.MESSAGE.DELETE') }}
            </button>
          </div>
        </template>
      </Popover>
    </div>

    <Dialog
      ref="deleteDialogRef"
      type="alert"
      :title="t('INTERNAL_CHAT.MESSAGE.DELETE')"
      :description="t('INTERNAL_CHAT.MESSAGE.CONFIRM_DELETE')"
      :confirm-button-label="t('INTERNAL_CHAT.MESSAGE.DELETE')"
      @confirm="confirmDelete"
    />
  </div>
</template>
