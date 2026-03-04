<script setup>
import { computed, ref } from 'vue';
import Avatar from 'next/avatar/Avatar.vue';
import ContactInfoRow from './ContactInfoRow.vue';
import GroupMembersModal from './GroupMembersModal.vue';

const props = defineProps({
  conversation: {
    type: Object,
    default: () => ({}),
  },
  contact: {
    type: Object,
    default: () => ({}),
  },
});

const PREVIEW_LIMIT = 3;

const showMembersModal = ref(false);
const searchQuery = ref('');
const showSearch = ref(false);

const groupTitle = computed(
  () => props.conversation.group_title || 'Group Chat'
);
const groupContacts = computed(() => props.conversation.group_contacts || []);
const memberCount = computed(() => {
  // +1 for the primary contact
  return groupContacts.value.length + 1;
});

const isSearching = computed(() => searchQuery.value.trim().length > 0);

const filteredMembers = computed(() => {
  if (!isSearching.value) {
    return groupContacts.value;
  }
  const query = searchQuery.value.toLowerCase().trim();
  return groupContacts.value.filter(gc => {
    const name = gc.contact?.name?.toLowerCase() || '';
    const identifier = gc.contact?.identifier?.toLowerCase() || '';
    return name.includes(query) || identifier.includes(query);
  });
});

const primaryContactMatches = computed(() => {
  if (!isSearching.value) return true;
  const query = searchQuery.value.toLowerCase().trim();
  const name = props.contact.name?.toLowerCase() || '';
  const identifier = props.contact.identifier?.toLowerCase() || '';
  return name.includes(query) || identifier.includes(query);
});

// Total filtered count (for "View all" button text)
const filteredCount = computed(() => {
  const primaryCount = primaryContactMatches.value ? 1 : 0;
  return filteredMembers.value.length + primaryCount;
});

// Always limit to PREVIEW_LIMIT - 1 (since primary takes 1 slot)
const displayMembers = computed(() => {
  const maxToShow = primaryContactMatches.value
    ? PREVIEW_LIMIT - 1
    : PREVIEW_LIMIT;
  return filteredMembers.value.slice(0, maxToShow);
});

// Show "View all" when there are more results than preview limit
const hasMoreMembers = computed(() => {
  if (isSearching.value) {
    return filteredCount.value > PREVIEW_LIMIT;
  }
  return memberCount.value > PREVIEW_LIMIT;
});

const viewAllCount = computed(() => {
  return isSearching.value ? filteredCount.value : memberCount.value;
});

const toggleSearch = () => {
  showSearch.value = !showSearch.value;
  if (!showSearch.value) {
    searchQuery.value = '';
  }
};

const openModal = () => {
  showMembersModal.value = true;
};
</script>

<template>
  <div class="relative items-center w-full p-4">
    <div class="flex flex-col w-full gap-2 text-left rtl:text-right">
      <!-- Group Icon -->
      <div class="flex flex-row justify-between">
        <div
          class="flex items-center justify-center w-12 h-12 rounded-full bg-n-alpha-2"
        >
          <span class="i-lucide-users text-xl text-n-slate-11" />
        </div>
      </div>

      <!-- Group Title -->
      <div class="flex flex-col items-start gap-1.5 min-w-0 w-full">
        <div class="flex items-center w-full min-w-0 gap-3">
          <h3
            class="flex-shrink max-w-full min-w-0 my-0 text-base break-words text-n-slate-12"
          >
            {{ groupTitle }}
          </h3>
        </div>
        <p class="text-sm text-n-slate-11 mb-2">
          {{ $t('CONVERSATION.GROUP.MEMBER_COUNT', memberCount) }}
        </p>
      </div>

      <!-- Group Members Section -->
      <div class="flex flex-col w-full gap-2 mt-2">
        <!-- Header with search toggle -->
        <div class="flex items-center justify-between mb-1">
          <h4 class="text-xs font-semibold uppercase text-n-slate-10">
            {{ $t('CONVERSATION.GROUP.MEMBERS') }}
          </h4>
          <button
            v-tooltip="$t('CONVERSATION.GROUP.SEARCH_MEMBERS')"
            class="p-1 rounded hover:bg-n-alpha-2"
            :class="{ 'bg-n-alpha-2': showSearch }"
            @click="toggleSearch"
          >
            <span class="i-lucide-search text-sm text-n-slate-11 block" />
          </button>
        </div>

        <!-- Inline Search Input -->
        <input
          v-if="showSearch"
          v-model="searchQuery"
          type="text"
          class="w-full px-3 py-1.5 mb-2 text-sm border rounded-lg border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder:text-n-slate-10 focus:outline-none focus:ring-1 focus:ring-n-brand"
          :placeholder="$t('CONVERSATION.GROUP.SEARCH_MEMBERS')"
        />

        <!-- No results message -->
        <div
          v-if="
            isSearching &&
            !primaryContactMatches &&
            filteredMembers.length === 0
          "
          class="py-4 text-center text-sm text-n-slate-10"
        >
          {{ $t('CONVERSATION.GROUP.NO_MEMBERS_FOUND') }}
        </div>

        <!-- Primary Contact (marked with star) -->
        <div
          v-if="!isSearching || primaryContactMatches"
          class="flex items-center gap-3 p-2 rounded-lg bg-n-alpha-1 border border-n-weak"
        >
          <Avatar
            :src="contact.thumbnail"
            :name="contact.name"
            :size="32"
            rounded-full
          />
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-1">
              <span
                class="text-sm font-medium truncate text-n-slate-12 capitalize"
              >
                {{ contact.name }}
              </span>
              <span
                v-tooltip="$t('CONVERSATION.GROUP.PRIMARY_CONTACT')"
                class="i-lucide-star text-n-amber-9 text-xs"
              />
            </div>
            <ContactInfoRow
              v-if="contact.identifier"
              :value="contact.identifier"
              class="!p-0 !gap-1"
              compact
            />
          </div>
        </div>

        <!-- Group Members (filtered or preview, always limited to 3) -->
        <div
          v-for="groupContact in displayMembers"
          :key="groupContact.id"
          class="flex items-center gap-3 p-2 rounded-lg bg-n-alpha-1 border border-n-weak"
        >
          <Avatar
            :src="groupContact.contact?.thumbnail"
            :name="groupContact.contact?.name"
            :size="32"
            rounded-full
          />
          <div class="flex-1 min-w-0">
            <span
              class="text-sm font-medium truncate text-n-slate-12 capitalize block"
            >
              {{ groupContact.contact?.name }}
            </span>
            <span
              v-if="groupContact.contact?.identifier"
              class="text-xs text-n-slate-10"
            >
              {{ groupContact.contact?.identifier }}
            </span>
          </div>
        </div>

        <!-- View All Members Button -->
        <button
          v-if="hasMoreMembers"
          class="w-full py-2 text-sm font-medium text-center rounded-lg text-n-brand hover:bg-n-alpha-2"
          @click="openModal"
        >
          {{
            $t('CONVERSATION.GROUP.VIEW_ALL_MEMBERS', { count: viewAllCount })
          }}
        </button>
      </div>
    </div>

    <!-- Group Members Modal -->
    <GroupMembersModal
      v-model:show="showMembersModal"
      :conversation="conversation"
      :contact="contact"
      :initial-search-query="searchQuery"
    />
  </div>
</template>
