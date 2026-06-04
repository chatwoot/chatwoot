<script setup>
import { computed, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import conversationApi from 'dashboard/api/inbox/conversation';
import Avatar from 'next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Modal from 'dashboard/components/Modal.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
  totalCount: {
    type: Number,
    default: 0,
  },
  isSessionAdmin: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['memberRemoved']);

const show = defineModel('show', { type: Boolean, default: false });

const route = useRoute();
const router = useRouter();
const store = useStore();

const members = ref([]);
const searchQuery = ref('');
const currentPage = ref(1);
const membersTotalCount = ref(0);
const isLoading = ref(false);
const hasLoadedOnce = ref(false);

const hasMorePages = computed(
  () => members.value.length < membersTotalCount.value
);
const visibleCount = computed(
  () => membersTotalCount.value || props.totalCount
);

const memberContact = member => member.contact || {};

const memberName = member =>
  memberContact(member).name ||
  member.participant_identifier ||
  member.metadata?.jid ||
  member.metadata?.lid ||
  member.metadata?.wa_id;

const memberSubtitle = member =>
  [
    member.metadata?.role,
    memberContact(member).whatsapp_username,
    memberContact(member).bsuid,
    memberContact(member).phone_number,
    member.participant_identifier,
  ]
    .filter(Boolean)
    .join(' · ');

const matchesSearch = member => {
  const query = searchQuery.value.trim().toLowerCase();
  if (!query) return true;

  return [
    memberName(member),
    memberSubtitle(member),
    memberContact(member).email,
    memberContact(member).identifier,
  ].some(value => value?.toString().toLowerCase().includes(query));
};

const filteredMembers = computed(() => members.value.filter(matchesSearch));

const fetchMembers = async (page = 1) => {
  if (isLoading.value) return;

  isLoading.value = true;
  try {
    const { data } = await conversationApi.fetchGroupContacts(
      props.conversationId,
      page
    );
    const payload = data.payload || [];
    members.value = page === 1 ? payload : [...members.value, ...payload];
    membersTotalCount.value = data.meta?.count || payload.length;
    currentPage.value = page;
    hasLoadedOnce.value = true;
  } finally {
    isLoading.value = false;
  }
};

const loadMore = () => {
  if (!hasMorePages.value || isLoading.value) return;

  fetchMembers(currentPage.value + 1);
};

const ensureContact = member => {
  const contactId = memberContact(member).id;
  if (contactId) store.dispatch('contacts/show', { id: contactId });
};

const openContactPage = member => {
  const contactId = memberContact(member).id;
  if (!contactId) return;

  show.value = false;
  router.push({
    name: 'contacts_edit',
    params: {
      accountId: route.params.accountId,
      contactId,
    },
  });
};

const removeMember = async member => {
  if (!member.participant_identifier) return;

  await conversationApi.removeGroupContacts({
    conversationId: props.conversationId,
    participants: [member.participant_identifier],
  });
  members.value = members.value.filter(item => item.id !== member.id);
  membersTotalCount.value = Math.max(membersTotalCount.value - 1, 0);
  emit('memberRemoved');
};

watch(
  () => show.value,
  value => {
    if (!value) return;

    searchQuery.value = '';
    fetchMembers(1);
  }
);
</script>

<template>
  <Modal v-model:show="show" size="medium">
    <div class="flex max-h-[40rem] flex-col">
      <div class="border-b border-n-weak px-6 py-5">
        <h3 class="m-0 text-lg font-medium text-n-slate-12">
          {{ $t('CONVERSATION.GROUP.MEMBERS_TITLE') }}
        </h3>
        <p class="m-0 text-sm text-n-slate-10">
          {{ visibleCount }} {{ $t('CONVERSATION.GROUP.MEMBERS') }}
        </p>
      </div>

      <div class="flex flex-1 flex-col gap-3 overflow-hidden px-6 py-4">
        <input
          v-model.trim="searchQuery"
          type="text"
          class="w-full rounded-md border border-n-weak bg-n-background px-3 py-2 text-sm text-n-slate-12"
          :placeholder="$t('CONVERSATION.GROUP.SEARCH_MEMBERS')"
        />

        <div class="flex-1 overflow-y-auto">
          <div
            v-if="isLoading && !hasLoadedOnce"
            class="flex items-center justify-center py-10"
          >
            <Spinner />
          </div>
          <div
            v-else-if="!filteredMembers.length"
            class="py-10 text-center text-sm text-n-slate-10"
          >
            {{ $t('CONVERSATION.GROUP.NO_MEMBERS_FOUND') }}
          </div>
          <div v-else class="flex flex-col gap-2">
            <div
              v-for="member in filteredMembers"
              :key="member.id"
              class="flex items-center gap-3 rounded-md border border-n-weak bg-n-alpha-1 p-2"
            >
              <button
                type="button"
                class="flex min-w-0 flex-1 items-center gap-3 text-left"
                @click="openContactPage(member)"
              >
                <Avatar
                  :name="memberName(member)"
                  :src="memberContact(member).thumbnail"
                  :size="36"
                  hide-offline-status
                />
                <span class="min-w-0 flex-1">
                  <span
                    class="block truncate text-sm font-medium text-n-slate-12"
                  >
                    {{ memberName(member) }}
                  </span>
                  <span
                    v-if="memberSubtitle(member)"
                    class="block truncate text-xs text-n-slate-10"
                  >
                    {{ memberSubtitle(member) }}
                  </span>
                </span>
              </button>

              <ComposeConversation
                v-if="memberContact(member).id"
                :contact-id="String(memberContact(member).id)"
                align="end"
              >
                <template #trigger>
                  <Button
                    v-tooltip.top="$t('CONVERSATION.GROUP.MESSAGE_MEMBER')"
                    icon="i-lucide-message-circle"
                    size="xs"
                    ghost
                    slate
                    :aria-label="$t('CONVERSATION.GROUP.MESSAGE_MEMBER')"
                    @click="ensureContact(member)"
                  />
                </template>
              </ComposeConversation>

              <Button
                v-if="memberContact(member).id"
                v-tooltip.top="$t('CONVERSATION.GROUP.VIEW_CONTACT')"
                icon="i-lucide-user-round"
                size="xs"
                ghost
                slate
                :aria-label="$t('CONVERSATION.GROUP.VIEW_CONTACT')"
                @click="openContactPage(member)"
              />

              <Button
                v-if="isSessionAdmin"
                v-tooltip.top="$t('CONVERSATION.GROUP.REMOVE_MEMBER')"
                icon="i-lucide-trash-2"
                size="xs"
                ghost
                ruby
                :aria-label="$t('CONVERSATION.GROUP.REMOVE_MEMBER')"
                @click="removeMember(member)"
              />
            </div>
          </div>
        </div>

        <div v-if="hasMorePages && !searchQuery" class="flex justify-center">
          <Button
            :label="$t('CONVERSATION.GROUP.LOAD_MORE')"
            size="sm"
            faded
            slate
            :is-loading="isLoading"
            @click="loadMore"
          />
        </div>
      </div>
    </div>
  </Modal>
</template>
