<script setup>
import {
  computed,
  nextTick,
  onBeforeUnmount,
  onMounted,
  ref,
  watch,
} from 'vue';
import { useRoute } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert, usePendingAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useEventListener } from '@vueuse/core';
import { debounce } from '@chatwoot/utils';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { useExpandableContent } from 'shared/composables/useExpandableContent';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import ContactsAPI from 'dashboard/api/contacts';
import GroupMembersAPI from 'dashboard/api/groupMembers';
import { phonesMatch } from 'dashboard/helper/phoneHelper';
import Avatar from 'next/avatar/Avatar.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Accordion from 'dashboard/components-next/Accordion/Accordion.vue';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';
import BaileysGroupOptions from './BaileysGroupOptions.vue';

const props = defineProps({
  contact: {
    type: Object,
    default: () => ({}),
  },
});

const store = useStore();
const route = useRoute();
const { t } = useI18n();

const currentChat = useMapGetter('getSelectedChat');
const inboxGetter = useMapGetter('inboxes/getInboxById');
const inbox = computed(
  () => inboxGetter.value(currentChat.value?.inbox_id) || {}
);

const contactProfileLink = computed(
  () => `/app/accounts/${route.params.accountId}/contacts/${props.contact.id}`
);
const uiFlags = useMapGetter('groupMembers/getUIFlags');
const getGroupMembers = useMapGetter('groupMembers/getGroupMembers');
const getGroupMembersMeta = useMapGetter('groupMembers/getGroupMembersMeta');

const members = computed(() => {
  const allMembers = getGroupMembers.value(props.contact.id) || [];
  return allMembers.filter(m => m.is_active);
});

const membersMeta = computed(
  () => getGroupMembersMeta.value(props.contact.id) || {}
);

// Prefer inbox_phone_number from the group members meta (always available on
// the first fetch response) and fall back to the inbox store lookup.
const inboxPhone = computed(
  () => membersMeta.value.inbox_phone_number || inbox.value?.phone_number
);

const memberCount = computed(
  () => membersMeta.value.total_count ?? members.value.length
);
const hasMoreMembers = computed(() => {
  const meta = membersMeta.value;
  if (!meta.total_count || !meta.page || !meta.per_page) return false;
  return meta.page * meta.per_page < meta.total_count;
});

const isInboxAdmin = computed(() => {
  if (membersMeta.value.is_inbox_admin != null)
    return membersMeta.value.is_inbox_admin;
  if (!inboxPhone.value) return false;
  return members.value.some(
    m =>
      phonesMatch(inboxPhone.value, m.contact?.phone_number) &&
      m.role === 'admin'
  );
});

const isOwnMember = member => {
  if (!inboxPhone.value) return false;
  return phonesMatch(inboxPhone.value, member.contact?.phone_number);
};

const isFetching = computed(() => uiFlags.value.isFetching);
const isFetchingMore = computed(() => uiFlags.value.isFetchingMore);
const sentinelRef = ref(null);
const membersScrollRef = ref(null);
let observer = null;

const loadMoreMembers = async () => {
  if (isFetchingMore.value || !hasMoreMembers.value) return;
  const nextPage = (membersMeta.value.page || 1) + 1;
  await store.dispatch('groupMembers/fetch', {
    contactId: props.contact.id,
    page: nextPage,
  });
};

const setupObserver = () => {
  if (observer) observer.disconnect();
  if (!sentinelRef.value) return;
  observer = new IntersectionObserver(
    entries => {
      if (entries[0]?.isIntersecting) loadMoreMembers();
    },
    { root: membersScrollRef.value, rootMargin: '100px' }
  );
  observer.observe(sentinelRef.value);
};

watch(sentinelRef, setupObserver);
watch(membersScrollRef, setupObserver);

onBeforeUnmount(() => {
  if (observer) observer.disconnect();
});

// Inline edit state
const isEditingName = ref(false);
const editNameValue = ref('');
const isSavingName = ref(false);
const isEditingDescription = ref(false);
const editDescriptionValue = ref('');
const isSavingDescription = ref(false);
const isSavingAvatar = ref(false);
const avatarFileInput = ref(null);

const contactDescription = computed(
  () => props.contact.additional_attributes?.description || ''
);

const {
  contentElement: descriptionContentRef,
  showReadMore: showDescReadMore,
  showReadLess: showDescReadLess,
  toggleExpanded: toggleDescExpanded,
  checkOverflow: checkDescOverflow,
} = useExpandableContent({ maxLines: 3, useResizeObserverForCheck: true });

const isGroupLeft = computed(
  () => props.contact.additional_attributes?.group_left === true
);

const canEditGroup = computed(() => isInboxAdmin.value && !isGroupLeft.value);

const startEditName = () => {
  if (isGroupLeft.value) return;
  editNameValue.value = props.contact.name || '';
  isEditingName.value = true;
};

const saveName = async () => {
  const newName = editNameValue.value.trim();
  if (!newName || newName === props.contact.name) {
    isEditingName.value = false;
    return;
  }
  isSavingName.value = true;
  try {
    await store.dispatch('groupMembers/updateGroupMetadata', {
      contactId: props.contact.id,
      params: { subject: newName },
    });
    useAlert(t('GROUP.METADATA.SAVE_SUCCESS'));
  } catch {
    useAlert(t('GROUP.METADATA.SAVE_ERROR'));
  } finally {
    isSavingName.value = false;
    isEditingName.value = false;
  }
};

const onNameKeydown = event => {
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault();
    saveName();
  }
  if (event.key === 'Escape') {
    isEditingName.value = false;
  }
};

const startEditDescription = () => {
  if (isGroupLeft.value) return;
  editDescriptionValue.value = contactDescription.value;
  isEditingDescription.value = true;
};

const saveDescription = async () => {
  const newDesc = editDescriptionValue.value.trim();
  if (newDesc === contactDescription.value) {
    isEditingDescription.value = false;
    return;
  }
  isSavingDescription.value = true;
  try {
    await store.dispatch('groupMembers/updateGroupMetadata', {
      contactId: props.contact.id,
      params: { description: newDesc },
    });
    useAlert(t('GROUP.METADATA.SAVE_SUCCESS'));
  } catch {
    useAlert(t('GROUP.METADATA.SAVE_ERROR'));
  } finally {
    isSavingDescription.value = false;
    isEditingDescription.value = false;
    toggleDescExpanded(false);
    nextTick(checkDescOverflow);
  }
};

const onDescriptionKeydown = event => {
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault();
    saveDescription();
  }
  if (event.key === 'Escape') {
    isEditingDescription.value = false;
  }
};

const onAvatarClick = () => {
  avatarFileInput.value?.click();
};

const onAvatarSelected = async event => {
  const file = event.target.files[0];
  if (!file) return;
  isSavingAvatar.value = true;
  try {
    const formData = new FormData();
    formData.append('avatar', file);
    await store.dispatch('groupMembers/updateGroupMetadata', {
      contactId: props.contact.id,
      params: formData,
    });
    useAlert(t('GROUP.METADATA.SAVE_SUCCESS'));
  } catch {
    useAlert(t('GROUP.METADATA.SAVE_ERROR'));
  } finally {
    isSavingAvatar.value = false;
    if (avatarFileInput.value) avatarFileInput.value.value = '';
  }
};

// Add member state
const showAddMember = ref(false);
const addMemberInput = ref('');
const searchResults = ref([]);
const isSearching = ref(false);
const showSearchDropdown = ref(false);

// Action menu state (per member)
const activeMenuMemberId = ref(null);
const loadingMemberId = ref(null);
const menuPosition = ref({ top: 0, left: 0 });

// Invite link state
const storedInviteCode = computed(
  () => props.contact.additional_attributes?.invite_code
);
const inviteUrl = ref(
  storedInviteCode.value
    ? `https://chat.whatsapp.com/${storedInviteCode.value}`
    : ''
);
const isFetchingInvite = ref(false);
const hasInviteLink = computed(() => !!inviteUrl.value);

// Keep invite URL in sync with store updates (e.g. via ActionCable)
watch(storedInviteCode, newCode => {
  if (newCode) {
    inviteUrl.value = `https://chat.whatsapp.com/${newCode}`;
  }
});

// Join requests state
const pendingRequests = computed(
  () => props.contact.additional_attributes?.pending_join_requests || []
);
const REQUESTS_PAGE_SIZE = 2;
const visibleRequestCount = ref(REQUESTS_PAGE_SIZE);
const visibleRequests = computed(() =>
  pendingRequests.value.slice(0, visibleRequestCount.value)
);
const hasMoreRequests = computed(
  () => pendingRequests.value.length > visibleRequestCount.value
);
const loadingRequestJid = ref(null);
const requestsSentinelRef = ref(null);
const requestContacts = ref({});
let requestsObserver = null;

const fetchRequestContacts = async requests => {
  const ids = requests
    .map(r => r.contact_id)
    .filter(id => id && !requestContacts.value[id]);
  if (!ids.length) return;

  const results = {};
  await Promise.all(
    ids.map(async id => {
      try {
        const { data } = await ContactsAPI.show(id);
        results[id] = data.payload || data;
      } catch {
        // contact might have been deleted — ignore
      }
    })
  );
  requestContacts.value = { ...requestContacts.value, ...results };
};

const getRequestContact = request =>
  requestContacts.value[request.contact_id] || null;

watch(pendingRequests, fetchRequestContacts, { immediate: true });

const loadMoreRequests = () => {
  if (!hasMoreRequests.value) return;
  visibleRequestCount.value += REQUESTS_PAGE_SIZE;
};

const setupRequestsObserver = () => {
  if (requestsObserver) requestsObserver.disconnect();
  if (!requestsSentinelRef.value) return;
  requestsObserver = new IntersectionObserver(entries => {
    if (entries[0]?.isIntersecting) loadMoreRequests();
  });
  requestsObserver.observe(requestsSentinelRef.value);
};

watch(requestsSentinelRef, setupRequestsObserver);

onBeforeUnmount(() => {
  if (requestsObserver) requestsObserver.disconnect();
});

const isLeavingGroup = ref(false);
const showLeaveConfirm = ref(false);

// Add member search
const searchContacts = debounce(
  async query => {
    if (!query || query.length < 2) {
      searchResults.value = [];
      showSearchDropdown.value = false;
      return;
    }
    isSearching.value = true;
    try {
      const { data } = await ContactsAPI.search(query);
      const existingPhones = members.value
        .map(m => m.contact?.phone_number)
        .filter(Boolean);
      searchResults.value = (data.payload || []).filter(
        c => c.phone_number && !existingPhones.includes(c.phone_number)
      );
      showSearchDropdown.value = searchResults.value.length > 0;
    } catch {
      searchResults.value = [];
    } finally {
      isSearching.value = false;
    }
  },
  300,
  false
);

const onAddMemberInput = event => {
  addMemberInput.value = event.target.value;
  searchContacts(addMemberInput.value);
};

const addMember = async contact => {
  showSearchDropdown.value = false;
  addMemberInput.value = '';
  searchResults.value = [];
  const dismiss = usePendingAlert(t('GROUP.MEMBERS.ADDING'));
  try {
    await store.dispatch('groupMembers/addMembers', {
      contactId: props.contact.id,
      participants: [contact.phone_number],
    });
    dismiss();
    useAlert(t('GROUP.MEMBERS.ADD_SUCCESS'));
    showAddMember.value = false;
  } catch {
    dismiss();
    useAlert(t('GROUP.MEMBERS.ADD_ERROR'));
  }
};

const toggleAddMember = () => {
  showAddMember.value = !showAddMember.value;
  if (!showAddMember.value) {
    addMemberInput.value = '';
    searchResults.value = [];
    showSearchDropdown.value = false;
  }
};

// Member actions
const getMemberMenuItems = member => {
  const items = [];
  if (member.role === 'member') {
    items.push({
      label: t('GROUP.MEMBERS.PROMOTE_BUTTON'),
      action: 'promote',
      value: 'promote',
      icon: 'i-lucide-shield',
    });
  } else {
    items.push({
      label: t('GROUP.MEMBERS.DEMOTE_BUTTON'),
      action: 'demote',
      value: 'demote',
      icon: 'i-lucide-shield-off',
    });
  }
  items.push({
    label: t('GROUP.MEMBERS.REMOVE_BUTTON'),
    action: 'remove',
    value: 'remove',
    icon: 'i-lucide-user-minus',
  });
  return items;
};

const computeMenuPosition = triggerEl => {
  if (!triggerEl) return;
  const rect = triggerEl.getBoundingClientRect();
  const MENU_WIDTH = 240;
  const MENU_HEIGHT_ESTIMATE = 96;
  const PADDING = 8;
  let top = rect.bottom + 4;
  let left = rect.right - MENU_WIDTH;
  if (top + MENU_HEIGHT_ESTIMATE > window.innerHeight - PADDING) {
    top = rect.top - MENU_HEIGHT_ESTIMATE - 4;
  }
  if (left < PADDING) left = PADDING;
  if (left + MENU_WIDTH > window.innerWidth - PADDING) {
    left = window.innerWidth - MENU_WIDTH - PADDING;
  }
  menuPosition.value = { top, left };
};

const toggleMemberMenu = (memberId, event) => {
  if (activeMenuMemberId.value === memberId) {
    activeMenuMemberId.value = null;
    return;
  }
  activeMenuMemberId.value = memberId;
  nextTick(() => {
    const triggerEl = event?.currentTarget || event?.target;
    computeMenuPosition(triggerEl);
  });
};

const closeMemberMenu = () => {
  activeMenuMemberId.value = null;
};

const activeMember = computed(() =>
  members.value.find(m => m.id === activeMenuMemberId.value)
);

const handleMemberAction = async (member, { action }) => {
  activeMenuMemberId.value = null;
  loadingMemberId.value = member.id;
  const pendingKeyMap = {
    remove: 'GROUP.MEMBERS.REMOVING',
    promote: 'GROUP.MEMBERS.PROMOTING',
    demote: 'GROUP.MEMBERS.DEMOTING',
  };
  // eslint-disable-next-line @intlify/vue-i18n/no-dynamic-keys
  const dismiss = usePendingAlert(t(pendingKeyMap[action]));
  try {
    if (action === 'remove') {
      await store.dispatch('groupMembers/removeMembers', {
        contactId: props.contact.id,
        memberId: member.id,
      });
      dismiss();
      useAlert(t('GROUP.MEMBERS.REMOVE_SUCCESS'));
    } else if (action === 'promote') {
      await store.dispatch('groupMembers/updateMemberRole', {
        contactId: props.contact.id,
        memberId: member.id,
        role: 'admin',
      });
      dismiss();
      useAlert(t('GROUP.MEMBERS.PROMOTE_SUCCESS'));
    } else if (action === 'demote') {
      await store.dispatch('groupMembers/updateMemberRole', {
        contactId: props.contact.id,
        memberId: member.id,
        role: 'member',
      });
      dismiss();
      useAlert(t('GROUP.MEMBERS.DEMOTE_SUCCESS'));
    }
  } catch (error) {
    dismiss();
    const serverError = error?.response?.data?.error;
    if (serverError === 'group_creator_not_modifiable') {
      useAlert(t('GROUP.MEMBERS.GROUP_CREATOR_NOT_MODIFIABLE'));
    } else {
      const errorKeyMap = {
        remove: 'GROUP.MEMBERS.REMOVE_ERROR',
        promote: 'GROUP.MEMBERS.PROMOTE_ERROR',
        demote: 'GROUP.MEMBERS.DEMOTE_ERROR',
      };
      useAlert(t(errorKeyMap[action]));
    }
  } finally {
    loadingMemberId.value = null;
  }
};

// Invite link methods
const fetchInviteLink = async () => {
  isFetchingInvite.value = true;
  try {
    const { data } = await GroupMembersAPI.getInviteLink(props.contact.id);
    inviteUrl.value = data.invite_url || '';
  } catch {
    inviteUrl.value = '';
  } finally {
    isFetchingInvite.value = false;
  }
};

const copyInviteLink = async () => {
  try {
    if (inviteUrl.value) {
      await copyTextToClipboard(inviteUrl.value);
      useAlert(t('GROUP.INVITE.COPY_SUCCESS'));
      showAddMember.value = false;
      addMemberInput.value = '';
      searchResults.value = [];
      showSearchDropdown.value = false;
    }
  } catch {
    useAlert(t('GROUP.INVITE.FETCH_ERROR'));
  }
};

// Join request methods
const handleJoinRequest = async (request, action) => {
  loadingRequestJid.value = request.jid;
  const dismiss = usePendingAlert(t('GROUP.JOIN_REQUESTS.PROCESSING'));
  try {
    await GroupMembersAPI.handleJoinRequest(props.contact.id, {
      participants: [request.jid],
      request_action: action,
    });
    // Optimistic local update — remove handled request from additional_attributes
    const updated = pendingRequests.value.filter(r => r.jid !== request.jid);
    await store.dispatch('contacts/update', {
      id: props.contact.id,
      additional_attributes: {
        ...props.contact.additional_attributes,
        pending_join_requests: updated,
      },
    });
    const msgKey =
      action === 'approve'
        ? 'GROUP.JOIN_REQUESTS.APPROVE_SUCCESS'
        : 'GROUP.JOIN_REQUESTS.REJECT_SUCCESS';
    dismiss();
    useAlert(t(msgKey));
  } catch {
    dismiss();
    useAlert(t('GROUP.JOIN_REQUESTS.ACTION_ERROR'));
  } finally {
    loadingRequestJid.value = null;
  }
};

const leaveGroup = async () => {
  isLeavingGroup.value = true;
  const dismiss = usePendingAlert(t('GROUP.SETTINGS.LEAVING'));
  try {
    await GroupMembersAPI.leaveGroup(props.contact.id);
    showLeaveConfirm.value = false;
    dismiss();
    useAlert(t('GROUP.SETTINGS.LEAVE_SUCCESS'));
  } catch {
    dismiss();
    useAlert(t('GROUP.SETTINGS.LEAVE_ERROR'));
  } finally {
    isLeavingGroup.value = false;
  }
};

const fetchGroupData = contactId => {
  if (!contactId) return;
  store.dispatch('groupMembers/fetch', { contactId });
  // Only fetch from API if we don't already have a stored invite code
  if (!storedInviteCode.value) {
    fetchInviteLink();
  }
};

watch(
  () => props.contact.id,
  (newId, oldId) => {
    if (newId && newId !== oldId) {
      visibleRequestCount.value = REQUESTS_PAGE_SIZE;
      fetchGroupData(newId);
    }
  }
);

onMounted(() => {
  fetchGroupData(props.contact.id);
});

// Close member menu when sidebar panel scrolls
const findScrollableAncestor = el => {
  let node = el?.parentElement;
  while (node) {
    const { overflow, overflowY } = getComputedStyle(node);
    if (/(auto|scroll)/.test(overflow + overflowY)) return node;
    node = node.parentElement;
  }
  return null;
};

const sidebarScrollRef = ref(null);
watch(membersScrollRef, el => {
  if (el) sidebarScrollRef.value = findScrollableAncestor(el);
});
useEventListener(sidebarScrollRef, 'scroll', closeMemberMenu);
</script>

<template>
  <div class="relative items-center w-full p-4">
    <div class="flex flex-col w-full gap-2 text-left rtl:text-right">
      <!-- Group header: avatar, name, member count, description -->
      <div class="flex flex-row items-start gap-3">
        <!-- Avatar (clickable for upload only when admin) -->
        <div
          class="relative shrink-0"
          :class="{ 'cursor-pointer group/avatar': canEditGroup }"
          @click="canEditGroup ? onAvatarClick() : undefined"
        >
          <Avatar
            :src="contact.thumbnail"
            :name="contact.name"
            :size="48"
            rounded-full
          />
          <div
            v-if="canEditGroup"
            class="absolute inset-0 flex items-center justify-center transition-opacity rounded-full opacity-0 bg-n-alpha-black2 group-hover/avatar:opacity-100"
          >
            <span
              v-if="isSavingAvatar"
              class="i-lucide-loader-2 animate-spin size-4 text-n-alpha-white1"
            />
            <span v-else class="i-lucide-camera size-4 text-n-alpha-white1" />
          </div>
          <input
            ref="avatarFileInput"
            type="file"
            accept="image/*"
            class="hidden"
            @change="onAvatarSelected"
          />
        </div>
        <div class="flex flex-col min-w-0 flex-1">
          <!-- Inline-editable name (only when admin) -->
          <div v-if="isEditingName" class="flex items-center gap-1">
            <input
              v-model="editNameValue"
              type="text"
              class="w-full px-2 py-1 text-base font-medium border rounded bg-n-alpha-black2 border-n-weak text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
              :placeholder="t('GROUP.METADATA.EDIT_NAME_PLACEHOLDER')"
              @keydown="onNameKeydown"
              @blur="saveName"
            />
            <span
              v-if="isSavingName"
              class="i-lucide-loader-2 animate-spin size-4 text-n-slate-10 shrink-0"
            />
          </div>
          <div v-else class="flex items-center gap-2 min-w-0">
            <h3
              class="my-0 text-base font-medium capitalize break-words text-n-slate-12"
              :class="{ 'cursor-pointer hover:text-n-brand': !isGroupLeft }"
              @click="startEditName"
            >
              {{ contact.name }}
            </h3>
            <div class="flex flex-row items-center gap-2 shrink-0">
              <span
                v-if="contact.created_at"
                v-tooltip.left="
                  `${t('CONTACT_PANEL.CREATED_AT_LABEL')} ${dynamicTime(
                    contact.created_at
                  )}`
                "
                class="i-lucide-info text-sm text-n-slate-10"
              />
              <a
                :href="contactProfileLink"
                target="_blank"
                rel="noopener nofollow noreferrer"
                class="leading-3"
              >
                <span class="i-lucide-external-link text-sm text-n-slate-10" />
              </a>
            </div>
          </div>
          <span class="text-sm text-n-slate-11">
            {{ t('GROUP.INFO.MEMBER_COUNT', { count: memberCount }) }}
          </span>
        </div>
      </div>

      <!-- Inline-editable description (only when admin) -->
      <div class="mt-2">
        <label class="text-xs font-semibold text-n-slate-11">
          {{ t('GROUP.METADATA.EDIT_DESCRIPTION_LABEL') }}
        </label>
        <div v-if="isEditingDescription" class="relative mt-1">
          <textarea
            v-model="editDescriptionValue"
            rows="2"
            class="w-full px-2 py-1 text-sm border rounded bg-n-alpha-black2 border-n-weak text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand resize-y max-h-40"
            :placeholder="t('GROUP.METADATA.EDIT_DESCRIPTION_PLACEHOLDER')"
            @keydown="onDescriptionKeydown"
            @blur="saveDescription"
          />
          <span
            v-if="isSavingDescription"
            class="absolute i-lucide-loader-2 animate-spin size-4 text-n-slate-10 right-2 top-2"
          />
        </div>
        <div v-else class="mt-1">
          <p
            ref="descriptionContentRef"
            class="text-sm break-words whitespace-pre-wrap text-n-slate-12"
            :class="[
              { 'cursor-pointer hover:text-n-brand': !isGroupLeft },
              showDescReadMore ? 'line-clamp-3' : '',
            ]"
            @click="startEditDescription"
          >
            {{
              contactDescription ||
              t('GROUP.METADATA.EDIT_DESCRIPTION_PLACEHOLDER')
            }}
          </p>
          <button
            v-if="showDescReadMore"
            class="mt-1 text-xs font-medium underline cursor-pointer bg-transparent border-0 p-0 text-n-slate-11 hover:text-n-slate-12"
            @click.stop="toggleDescExpanded(true)"
          >
            {{ t('SEARCH.READ_MORE') }}
          </button>
          <button
            v-if="showDescReadLess"
            class="mt-1 text-xs font-medium underline cursor-pointer bg-transparent border-0 p-0 text-n-slate-11 hover:text-n-slate-12"
            @click.stop="toggleDescExpanded(false)"
          >
            {{ t('SEARCH.READ_LESS') }}
          </button>
        </div>
      </div>

      <!-- Group left banner -->
      <div
        v-if="isGroupLeft"
        class="flex items-center gap-2 p-3 mt-3 text-sm font-medium border rounded-lg border-n-ruby-7 bg-n-ruby-3 text-n-ruby-11"
      >
        <span class="i-lucide-log-out size-4 shrink-0" />
        {{ t('GROUP.SETTINGS.GROUP_LEFT_BANNER') }}
      </div>

      <!-- Members section -->
      <div class="mt-3">
        <div class="flex items-center justify-between mb-2">
          <h4 class="text-sm font-semibold text-n-slate-11">
            {{ t('GROUP.INFO.MEMBER_LIST_TITLE') }}
          </h4>
          <div class="flex items-center gap-1">
            <NextButton
              v-if="isInboxAdmin && !isGroupLeft"
              :label="t('GROUP.MEMBERS.ADD_BUTTON')"
              icon="i-lucide-user-plus"
              variant="ghost"
              size="xs"
              @click="toggleAddMember"
            />
          </div>
        </div>

        <!-- Add member search input -->
        <div v-if="showAddMember && !isGroupLeft" class="relative mb-3">
          <input
            :value="addMemberInput"
            type="text"
            class="w-full px-3 py-2 text-sm border rounded-lg bg-n-alpha-black2 border-n-weak text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
            :placeholder="t('GROUP.CREATE.PARTICIPANTS_PLACEHOLDER')"
            @input="onAddMemberInput"
            @focus="showSearchDropdown = searchResults.length > 0"
          />
          <span
            v-if="isSearching"
            class="absolute i-lucide-loader-2 animate-spin size-4 text-n-slate-10 right-3 top-2.5"
          />
          <NextButton
            v-if="hasInviteLink"
            :label="t('GROUP.INVITE.COPY_INVITE_LINK')"
            icon="i-lucide-link"
            variant="ghost"
            size="xs"
            class="mt-1"
            @click="copyInviteLink"
          />
          <ul
            v-if="showSearchDropdown"
            class="absolute z-10 w-full mt-1 overflow-y-auto border rounded-lg shadow-lg bg-n-alpha-3 backdrop-blur-[100px] border-n-weak max-h-48"
          >
            <li
              v-for="result in searchResults"
              :key="result.id"
              class="flex items-center gap-2 px-3 py-2 text-sm cursor-pointer text-n-slate-12 hover:bg-n-alpha-2"
              @click="addMember(result)"
            >
              <Avatar
                :src="result.thumbnail"
                :name="result.name"
                :size="24"
                rounded-full
              />
              <span class="truncate">{{ result.name }}</span>
              <span class="text-xs text-n-slate-10">
                {{ result.phone_number }}
              </span>
            </li>
          </ul>
        </div>

        <!-- Skeleton loading -->
        <div v-if="isFetching" class="flex flex-col gap-3">
          <div v-for="i in 4" :key="i" class="flex items-center gap-3">
            <div class="rounded-full size-8 bg-n-slate-3 animate-pulse" />
            <div class="flex flex-col flex-1 gap-1">
              <div class="w-2/5 h-4 rounded bg-n-slate-3 animate-pulse" />
            </div>
          </div>
        </div>

        <!-- Empty state -->
        <p v-else-if="members.length === 0" class="text-sm text-n-slate-11">
          {{ t('GROUP.INFO.EMPTY_STATE') }}
        </p>

        <!-- Member list -->
        <div
          v-else
          ref="membersScrollRef"
          class="flex flex-col gap-2 max-h-[240px] overflow-y-auto"
          @scroll="closeMemberMenu"
        >
          <div
            v-for="member in members"
            :key="member.id"
            class="flex items-center gap-3 py-1 group"
          >
            <a
              :href="`/app/accounts/${route.params.accountId}/contacts/${member.contact.id}`"
              target="_blank"
              rel="noopener nofollow noreferrer"
              class="shrink-0"
            >
              <Avatar
                :src="member.contact.thumbnail"
                :name="member.contact.name"
                :size="32"
                rounded-full
              />
            </a>
            <div class="flex items-center flex-1 min-w-0 gap-2">
              <a
                :href="`/app/accounts/${route.params.accountId}/contacts/${member.contact.id}`"
                target="_blank"
                rel="noopener nofollow noreferrer"
                class="text-sm truncate text-n-slate-12 hover:text-n-brand"
              >
                {{ member.contact.name }}
              </a>
              <span
                v-if="member.role === 'admin'"
                class="px-1.5 py-0.5 text-xs font-medium rounded bg-n-amber-3 text-n-amber-11"
              >
                {{ t('GROUP.INFO.ADMIN_BADGE') }}
              </span>
              <span
                v-if="isOwnMember(member)"
                class="px-1.5 py-0.5 text-xs font-medium rounded bg-n-blue-3 text-n-blue-11"
              >
                {{ t('GROUP.INFO.YOU_BADGE') }}
              </span>
            </div>
            <!-- Loading spinner for this member -->
            <span
              v-if="
                isInboxAdmin && !isGroupLeft && loadingMemberId === member.id
              "
              class="i-lucide-loader-2 animate-spin size-4 text-n-slate-10"
            />
            <!-- Action menu toggle (admin only, not for self) -->
            <div
              v-else-if="isInboxAdmin && !isGroupLeft && !isOwnMember(member)"
              class="relative"
              :class="{
                'opacity-0 group-hover:opacity-100':
                  activeMenuMemberId !== member.id,
              }"
            >
              <NextButton
                icon="i-lucide-ellipsis-vertical"
                color="slate"
                variant="ghost"
                size="xs"
                @click="toggleMemberMenu(member.id, $event)"
              />
            </div>
          </div>
          <!-- Sentinel for IntersectionObserver-based infinite scroll -->
          <div v-if="hasMoreMembers" ref="sentinelRef" class="h-px" />
          <!-- Loading more skeleton -->
          <div v-if="isFetchingMore" class="flex flex-col gap-3 pt-1">
            <div
              v-for="i in 3"
              :key="`more-${i}`"
              class="flex items-center gap-3"
            >
              <div class="rounded-full size-8 bg-n-slate-3 animate-pulse" />
              <div class="flex flex-col flex-1 gap-1">
                <div class="w-2/5 h-4 rounded bg-n-slate-3 animate-pulse" />
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Pending Join Requests section (admin only) -->
      <div
        v-if="!isGroupLeft && isInboxAdmin && pendingRequests.length > 0"
        class="mt-4"
      >
        <h4 class="mb-2 text-sm font-semibold text-n-slate-11">
          {{ t('GROUP.JOIN_REQUESTS.SECTION_TITLE') }}
          <span class="ml-1 text-xs font-normal text-n-slate-10">
            {{
              t('GROUP.JOIN_REQUESTS.PENDING_COUNT', {
                count: pendingRequests.length,
              })
            }}
          </span>
        </h4>
        <div class="flex flex-col gap-2 overflow-y-auto max-h-28">
          <div
            v-for="request in visibleRequests"
            :key="request.jid"
            class="flex items-center gap-3 py-1"
          >
            <a
              v-if="getRequestContact(request)"
              :href="`/app/accounts/${route.params.accountId}/contacts/${request.contact_id}`"
              target="_blank"
              rel="noopener nofollow noreferrer"
              class="shrink-0"
            >
              <Avatar
                :src="getRequestContact(request)?.thumbnail"
                :name="getRequestContact(request)?.name || request.jid"
                :size="32"
                rounded-full
              />
            </a>
            <Avatar v-else :name="request.jid" :size="32" rounded-full />
            <div class="flex flex-col flex-1 min-w-0">
              <a
                v-if="getRequestContact(request)"
                :href="`/app/accounts/${route.params.accountId}/contacts/${request.contact_id}`"
                target="_blank"
                rel="noopener nofollow noreferrer"
                class="text-sm truncate text-n-slate-12 hover:text-n-brand"
              >
                {{ getRequestContact(request)?.name || request.jid }}
              </a>
              <span v-else class="text-sm truncate text-n-slate-12">
                {{ request.jid }}
              </span>
              <span
                v-if="getRequestContact(request)?.phone_number"
                class="text-xs text-n-slate-10"
              >
                {{ getRequestContact(request).phone_number }}
              </span>
            </div>
            <span
              v-if="loadingRequestJid === request.jid"
              class="i-lucide-loader-2 animate-spin size-4 text-n-slate-10"
            />
            <div v-else class="flex items-center gap-1">
              <NextButton
                icon="i-lucide-check"
                variant="ghost"
                color="teal"
                size="xs"
                @click="handleJoinRequest(request, 'approve')"
              />
              <NextButton
                icon="i-lucide-x"
                variant="ghost"
                color="ruby"
                size="xs"
                @click="handleJoinRequest(request, 'reject')"
              />
            </div>
          </div>
          <div v-if="hasMoreRequests" ref="requestsSentinelRef" class="h-px" />
          <div v-if="hasMoreRequests" class="flex flex-col gap-3 pt-1">
            <div
              v-for="i in REQUESTS_PAGE_SIZE"
              :key="`req-skel-${i}`"
              class="flex items-center gap-3"
            >
              <div class="rounded-full size-8 bg-n-slate-3 animate-pulse" />
              <div class="flex flex-col flex-1 gap-1">
                <div class="w-2/5 h-4 rounded bg-n-slate-3 animate-pulse" />
              </div>
            </div>
          </div>
        </div>
      </div>

      <Accordion
        v-if="!isGroupLeft"
        :title="t('GROUP.SETTINGS.ADVANCED_OPTIONS')"
        class="mt-4"
      >
        <BaileysGroupOptions :contact="contact" :is-admin="isInboxAdmin" />

        <!-- Leave Group section -->
        <div class="mt-3">
          <div v-if="!showLeaveConfirm">
            <NextButton
              :label="t('GROUP.SETTINGS.LEAVE_GROUP')"
              icon="i-lucide-log-out"
              variant="ghost"
              color="ruby"
              size="xs"
              class="w-full"
              @click="showLeaveConfirm = true"
            />
          </div>
          <div
            v-else
            class="flex flex-col gap-2 p-3 border rounded-lg border-n-weak"
          >
            <p class="text-sm text-n-slate-12">
              {{ t('GROUP.SETTINGS.LEAVE_CONFIRM') }}
            </p>
            <div class="flex items-center gap-2">
              <NextButton
                :label="t('GROUP.SETTINGS.LEAVE_CONFIRM_YES')"
                color="ruby"
                size="xs"
                :is-loading="isLeavingGroup"
                :disabled="isLeavingGroup"
                @click="leaveGroup"
              />
              <NextButton
                :label="t('GROUP.SETTINGS.LEAVE_CONFIRM_NO')"
                variant="ghost"
                size="xs"
                :disabled="isLeavingGroup"
                @click="showLeaveConfirm = false"
              />
            </div>
          </div>
        </div>
      </Accordion>
    </div>
  </div>

  <!-- Teleported member action dropdown -->
  <TeleportWithDirection to="body">
    <div
      v-if="activeMenuMemberId && activeMember"
      class="fixed inset-0 z-[9998]"
      @click="closeMemberMenu"
    />
    <div
      v-if="activeMenuMemberId && activeMember"
      class="fixed z-[9999]"
      :style="{
        top: `${menuPosition.top}px`,
        left: `${menuPosition.left}px`,
      }"
    >
      <DropdownMenu
        :menu-items="getMemberMenuItems(activeMember)"
        class="w-60"
        @action="handleMemberAction(activeMember, $event)"
      />
    </div>
  </TeleportWithDirection>
</template>
