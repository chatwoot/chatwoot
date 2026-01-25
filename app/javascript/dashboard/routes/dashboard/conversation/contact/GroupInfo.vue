<script setup>
import { computed } from 'vue';
import Avatar from 'next/avatar/Avatar.vue';
import ContactInfoRow from './ContactInfoRow.vue';

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

const groupTitle = computed(
  () => props.conversation.group_title || 'Group Chat'
);
const groupContacts = computed(() => props.conversation.group_contacts || []);
const memberCount = computed(() => {
  // +1 for the primary contact
  return groupContacts.value.length + 1;
});
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
          {{ $tc('CONVERSATION.GROUP.MEMBER_COUNT', memberCount) }}
        </p>
      </div>

      <!-- Group Members Section -->
      <div class="flex flex-col w-full gap-2 mt-2">
        <h4 class="text-xs font-semibold uppercase text-n-slate-10 mb-1">
          {{ $t('CONVERSATION.GROUP.MEMBERS') }}
        </h4>

        <!-- Primary Contact (marked with star) -->
        <div
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

        <!-- Other Group Members -->
        <div
          v-for="groupContact in groupContacts"
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
      </div>
    </div>
  </div>
</template>
