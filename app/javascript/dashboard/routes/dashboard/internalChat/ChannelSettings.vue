<script setup>
import { computed, ref, nextTick, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import InternalChatChannelsAPI from 'dashboard/api/internalChatChannels';
import { formatLocalized } from 'shared/helpers/localizedDate';
import { vOnClickOutside } from '@vueuse/components';
import { useBreakpoints, breakpointsTailwind } from '@vueuse/core';

const props = defineProps({
  channel: { type: Object, required: true },
  currentUserId: { type: Number, required: true },
  isAdmin: { type: Boolean, default: false },
});

const emit = defineEmits([
  'close',
  'archive',
  'unarchive',
  'delete',
  'mute',
  'unmute',
  'favorite',
  'unfavorite',
  'close-dm',
  'edit-members',
]);

const store = useStore();
const { t } = useI18n();

const breakpoints = useBreakpoints(breakpointsTailwind);
const isBelowLarge = breakpoints.smaller('lg');

// The panel only overlays the conversation below lg. As a desktop column it has
// to stay put when the user clicks a message next to it.
const closeOnClickOutside = () => {
  if (isBelowLarge.value) emit('close');
};

const isDM = computed(() => props.channel.channel_type === 'dm');
const isPrivate = computed(
  () => props.channel.channel_type === 'private_channel'
);

const showDeleteConfirm = ref(false);
const members = computed(() => props.channel.members || []);
const isLoadingMembers = ref(false);
const isEditingName = ref(false);
const editedName = ref('');
const nameInputRef = ref(null);

async function fetchMembers() {
  if (!props.channel.id) return;

  if (!members.value.length) isLoadingMembers.value = true;
  try {
    const { data } = await InternalChatChannelsAPI.getMembers(props.channel.id);
    store.commit('internalChat/UPDATE_CHANNEL', {
      id: props.channel.id,
      members: data,
    });
  } catch {
    // silently handle
  } finally {
    isLoadingMembers.value = false;
  }
}

onMounted(() => {
  if (!members.value.length) fetchMembers();
});

watch(
  () => props.channel.id,
  () => {
    if (!members.value.length) fetchMembers();
  }
);
// Refetch members when ActionCable broadcasts updated member list
watch(() => props.channel.member_user_ids, fetchMembers);

const isMuted = computed(() => props.channel.muted);
const isFavorited = computed(() => props.channel.favorited);
const isArchived = computed(() => props.channel.status === 'archived');

const channelTypeLabel = computed(() => {
  const type = props.channel.channel_type;
  if (type === 'dm') return t('INTERNAL_CHAT.DM.NEW');
  if (type === 'private_channel') return t('INTERNAL_CHAT.CHANNEL.PRIVATE');
  return t('INTERNAL_CHAT.CHANNEL.PUBLIC');
});

const channelTypeIcon = computed(() => {
  const type = props.channel.channel_type;
  if (type === 'dm') return 'i-lucide-message-circle';
  if (type === 'private_channel') return 'i-lucide-lock';
  return 'i-lucide-hash';
});

const createdAt = computed(() => {
  if (!props.channel.created_at) return '';
  return formatLocalized(new Date(props.channel.created_at), 'M/d/yyyy');
});

function handleMuteToggle() {
  if (isMuted.value) {
    emit('unmute');
  } else {
    emit('mute');
  }
}

function handleFavoriteToggle() {
  if (isFavorited.value) {
    emit('unfavorite');
  } else {
    emit('favorite');
  }
}

function handleArchiveToggle() {
  if (isArchived.value) {
    emit('unarchive');
  } else {
    emit('archive');
  }
}

async function startEditName() {
  editedName.value = props.channel.name || '';
  isEditingName.value = true;
  await nextTick();
  nameInputRef.value?.focus();
}

async function saveName() {
  const trimmed = editedName.value.trim();
  if (!trimmed || trimmed === props.channel.name) {
    isEditingName.value = false;
    return;
  }
  try {
    await store.dispatch('internalChat/update', {
      channelId: props.channel.id,
      channel: { name: trimmed },
    });
  } catch {
    // silently handle
  }
  isEditingName.value = false;
}

function handleDelete() {
  if (!showDeleteConfirm.value) {
    showDeleteConfirm.value = true;
    return;
  }
  emit('delete');
  showDeleteConfirm.value = false;
}

defineExpose({ fetchMembers });
</script>

<template>
  <div
    v-on-click-outside="[
      closeOnClickOutside,
      {
        ignore: ['dialog', '[data-popover-content]', '[data-popover-backdrop]'],
      },
    ]"
    class="fixed inset-y-0 z-40 flex w-full max-w-sm flex-col bg-n-solid-1 shadow-lg border-n-slate-5 ltr:right-0 ltr:border-l rtl:left-0 rtl:border-r lg:static lg:h-full lg:w-80 lg:max-w-none lg:shadow-none"
  >
    <div
      class="flex h-[53px] items-center justify-between border-b border-n-slate-5 px-4"
    >
      <h3 class="text-sm font-semibold text-n-slate-12">
        {{ t('INTERNAL_CHAT.CHANNEL.SETTINGS') }}
      </h3>
      <button
        type="button"
        class="flex items-center justify-center rounded p-1 text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12"
        :aria-label="t('INTERNAL_CHAT.THREAD.CLOSE')"
        @click="emit('close')"
      >
        <Icon icon="i-lucide-x" class="size-4" />
      </button>
    </div>

    <div class="flex-1 overflow-y-auto">
      <!-- Channel Info -->
      <div class="border-b border-n-slate-5 px-4 py-4">
        <h4 class="mb-3 text-xs font-semibold uppercase text-n-slate-10">
          {{ t('INTERNAL_CHAT.CHANNEL.INFO') }}
        </h4>
        <div class="space-y-2">
          <div class="flex items-center gap-2">
            <Icon
              :icon="channelTypeIcon"
              class="size-4 flex-shrink-0 text-n-slate-10"
            />
            <input
              v-if="isEditingName"
              ref="nameInputRef"
              v-model="editedName"
              type="text"
              class="reset-base flex-1 border-b border-n-brand bg-transparent text-sm text-n-slate-12 outline-none"
              @keydown.enter="saveName"
              @keydown.escape="isEditingName = false"
              @blur="saveName"
            />
            <span
              v-else
              class="flex-1 truncate text-sm text-n-slate-12"
              :class="{ 'cursor-pointer hover:text-n-brand': !isDM && isAdmin }"
              @click="!isDM && isAdmin && startEditName()"
            >
              {{ channel.name }}
            </span>
            <button
              v-if="isAdmin && !isDM && !isEditingName"
              type="button"
              class="flex-shrink-0 rounded p-0.5 text-n-slate-9 hover:text-n-slate-12"
              @click="startEditName"
            >
              <Icon icon="i-lucide-pencil" class="size-3.5" />
            </button>
          </div>
          <div v-if="channel.description" class="text-sm text-n-slate-10">
            {{ channel.description }}
          </div>
          <div class="flex items-center gap-2 text-xs text-n-slate-10">
            <span>{{ channelTypeLabel }}</span>
            <span v-if="createdAt">
              &middot; {{ t('INTERNAL_CHAT.CHANNEL.CREATED_AT') }}
              {{ createdAt }}
            </span>
          </div>
        </div>
      </div>

      <!-- Members -->
      <div class="border-b border-n-slate-5 px-4 py-4">
        <h4 class="mb-3 text-xs font-semibold uppercase text-n-slate-10">
          {{ t('INTERNAL_CHAT.CHANNEL.MEMBERS') }}
          <span v-if="members.length" class="ml-1 text-n-slate-9">
            ({{ members.length }})
          </span>
        </h4>
        <div v-if="isLoadingMembers" class="space-y-2">
          <div
            v-for="i in channel.members_count || 4"
            :key="i"
            class="flex animate-pulse items-center gap-2"
          >
            <div class="size-6 flex-shrink-0 rounded-full bg-n-alpha-2" />
            <div class="h-3.5 flex-1 rounded bg-n-alpha-2" />
          </div>
        </div>
        <div v-else class="space-y-2">
          <div
            v-for="member in members"
            :key="member.user_id"
            class="flex items-center gap-2"
          >
            <Avatar
              :src="member.avatar_url"
              :name="member.name || ''"
              :status="member.availability_status"
              :size="24"
              rounded-full
            />
            <span class="flex-1 truncate text-sm text-n-slate-12">
              {{ member.name }}
            </span>
            <span
              v-if="member.role === 'admin'"
              class="rounded bg-n-alpha-2 px-1.5 py-0.5 text-xs text-n-slate-10"
            >
              {{ t('INTERNAL_CHAT.CHANNEL.ADMIN') }}
            </span>
            <span
              v-if="member.user_id === currentUserId"
              class="text-xs text-n-slate-10"
            >
              {{ t('INTERNAL_CHAT.CHANNEL.YOU') }}
            </span>
          </div>
          <div v-if="members.length === 0" class="text-sm text-n-slate-10">
            {{ t('INTERNAL_CHAT.CHANNEL.NO_MEMBERS') }}
          </div>
        </div>
        <button
          v-if="isAdmin && isPrivate && !isArchived"
          type="button"
          class="mt-3 flex w-full items-center justify-center gap-2 rounded-lg border border-n-slate-6 px-3 py-1.5 text-sm text-n-slate-12 hover:bg-n-alpha-2"
          @click="emit('edit-members')"
        >
          <Icon icon="i-lucide-user-plus" class="size-4 text-n-slate-11" />
          {{ t('INTERNAL_CHAT.CHANNEL.EDIT_MEMBERS') }}
        </button>
      </div>

      <!-- Actions -->
      <div class="px-4 py-4">
        <h4 class="mb-3 text-xs font-semibold uppercase text-n-slate-10">
          {{ t('INTERNAL_CHAT.CHANNEL.ACTIONS') }}
        </h4>
        <div class="space-y-1">
          <template v-if="!isArchived">
            <button
              type="button"
              class="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-sm text-n-slate-12 hover:bg-n-alpha-2"
              @click="handleMuteToggle"
            >
              <Icon
                :icon="isMuted ? 'i-lucide-bell' : 'i-lucide-bell-off'"
                class="size-4 text-n-slate-11"
              />
              {{
                isMuted
                  ? t('INTERNAL_CHAT.CHANNEL.UNMUTE')
                  : t('INTERNAL_CHAT.CHANNEL.MUTE')
              }}
            </button>

            <button
              type="button"
              class="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-sm text-n-slate-12 hover:bg-n-alpha-2"
              @click="handleFavoriteToggle"
            >
              <Icon
                :icon="isFavorited ? 'i-lucide-star-off' : 'i-lucide-star'"
                class="size-4 text-n-slate-11"
              />
              {{
                isFavorited
                  ? t('INTERNAL_CHAT.CHANNEL.UNFAVORITE')
                  : t('INTERNAL_CHAT.CHANNEL.FAVORITE')
              }}
            </button>

            <!-- DM: Close conversation button -->
            <button
              v-if="isDM"
              type="button"
              class="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-sm text-n-slate-12 hover:bg-n-alpha-2"
              @click="emit('close-dm')"
            >
              <Icon icon="i-lucide-x-circle" class="size-4 text-n-slate-11" />
              {{ t('INTERNAL_CHAT.CHANNEL.CLOSE_DM') }}
            </button>
          </template>

          <!-- Non-DM: Archive and Delete -->
          <template v-if="!isDM">
            <button
              v-if="isAdmin"
              type="button"
              class="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-sm text-n-slate-12 hover:bg-n-alpha-2"
              @click="handleArchiveToggle"
            >
              <Icon
                :icon="
                  isArchived ? 'i-lucide-archive-restore' : 'i-lucide-archive'
                "
                class="size-4 text-n-slate-11"
              />
              {{
                isArchived
                  ? t('INTERNAL_CHAT.CHANNEL.UNARCHIVE')
                  : t('INTERNAL_CHAT.CHANNEL.ARCHIVE')
              }}
            </button>

            <button
              v-if="isAdmin"
              type="button"
              class="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-sm text-n-ruby-11 hover:bg-n-ruby-3"
              @click="handleDelete"
            >
              <Icon icon="i-lucide-trash-2" class="size-4" />
              {{ t('INTERNAL_CHAT.CHANNEL.DELETE') }}
            </button>

            <div
              v-if="showDeleteConfirm"
              class="mt-2 rounded-lg border border-n-ruby-7 bg-n-ruby-2 p-3"
            >
              <p class="mb-2 text-sm text-n-ruby-11">
                {{ t('INTERNAL_CHAT.CHANNEL.CONFIRM_DELETE') }}
              </p>
              <div class="flex gap-2">
                <button
                  type="button"
                  class="rounded-lg bg-n-ruby-9 px-3 py-1.5 text-sm font-medium text-white hover:bg-n-ruby-10"
                  @click="handleDelete"
                >
                  {{ t('INTERNAL_CHAT.CHANNEL.DELETE') }}
                </button>
                <button
                  type="button"
                  class="rounded-lg px-3 py-1.5 text-sm text-n-slate-11 hover:bg-n-alpha-2"
                  @click="showDeleteConfirm = false"
                >
                  {{ t('INTERNAL_CHAT.POLL.CANCEL') }}
                </button>
              </div>
            </div>
          </template>
        </div>
      </div>
    </div>
  </div>
</template>
