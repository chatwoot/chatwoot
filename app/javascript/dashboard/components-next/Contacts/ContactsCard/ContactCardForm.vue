<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Flag from 'dashboard/components-next/flag/Flag.vue';
import ContactLabels from 'dashboard/components-next/Conversation/ConversationCard/CardLabels.vue';
import countries from 'shared/constants/countries';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import CardContent from 'dashboard/components-next/Conversation/ConversationCard/CardContent.vue';
import InboxName from 'dashboard/components-next/Conversation/InboxName.vue';
import CardPriorityIcon from 'dashboard/components-next/Conversation/ConversationCard/CardPriorityIcon.vue';
import CardStatusIcon from 'dashboard/components-next/Conversation/ConversationCard/CardStatusIcon.vue';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { getLastMessage } from 'dashboard/helper/conversationHelper';

const props = defineProps({
  contactData: {
    type: Object,
    default: null,
  },
});

const { t } = useI18n();
const router = useRouter();

const contactNotes = useMapGetter('contactNotes/getAllNotesByContactId');
const contactConversations = useMapGetter(
  'contactConversations/getAllConversationsByContactId'
);
const currentAccountId = useMapGetter('getCurrentAccountId');
const currentUser = useMapGetter('getCurrentUser');
const agentsList = useMapGetter('agents/getAgents');
const inboxGetter = useMapGetter('inboxes/getInbox');

const countriesMap = computed(() => {
  return countries.reduce((acc, country) => {
    acc[country.code] = country;
    acc[country.id] = country;
    return acc;
  }, {});
});

const countryDetails = computed(() => {
  const attributes = props.contactData?.additionalAttributes || {};
  const { country, countryCode, city } = attributes;

  if (!country && !countryCode) return null;

  const activeCountry =
    countriesMap.value[country] || countriesMap.value[countryCode];
  if (!activeCountry) return null;

  return {
    countryCode: activeCountry.id,
    city: city ? `${city},` : null,
    name: activeCountry.name,
  };
});

const formattedLocation = computed(() => {
  if (!countryDetails.value) return '';
  return [countryDetails.value.city, countryDetails.value.name]
    .filter(Boolean)
    .join(' ');
});

const companyName = computed(() => {
  const attributes = props.contactData?.additionalAttributes || {};
  return attributes.companyName || '';
});

const contactLabels = computed(() => {
  return props.contactData?.labels || [];
});

const latestNote = computed(() => {
  if (!props.contactData?.id) return null;
  const notes = contactNotes.value(props.contactData.id);
  return notes && notes.length > 0 ? notes[0] : null;
});

const latestConversation = computed(() => {
  if (!props.contactData?.id) return null;
  const conversations = contactConversations.value(props.contactData.id);
  return conversations && conversations.length > 0 ? conversations[0] : null;
});

const lastMessageInConversation = computed(() => {
  if (!latestConversation.value) return null;
  return getLastMessage(latestConversation.value);
});

const inbox = computed(() => {
  const inboxId = latestConversation.value?.inboxId;
  return inboxId ? inboxGetter.value(inboxId) : {};
});

const assignee = computed(() => {
  if (!latestConversation.value?.meta?.assignee?.id) return null;
  return agentsList.value?.find(
    agent => agent.id === latestConversation.value.meta.assignee.id
  );
});

const getWrittenBy = ({ user } = {}) => {
  const currentUserId = currentUser.value?.id;
  return user?.id === currentUserId
    ? t('CONTACTS_LAYOUT.SIDEBAR.NOTES.YOU')
    : user?.name || t('CONVERSATION.BOT');
};

const formatTimestamp = timestamp => {
  if (!timestamp) return '';
  return dynamicTime(timestamp);
};

const getConversationUrl = conversationId => {
  if (!conversationId || !currentAccountId.value) return '#';
  const url = `/app/accounts/${currentAccountId.value}/conversations/${conversationId}`;
  return router.push(url);
};
</script>

<template>
  <div
    class="flex flex-col gap-2 ltr:pl-2 rtl:pr-2 lg:ltr:pl-9 lg:rtl:pr-9 lg:before:content-[''] lg:before:absolute lg:before:ltr:left-[2.688rem] lg:before:rtl:right-[2.688rem] lg:before:top-0 lg:before:w-px lg:before:h-4 lg:before:bg-n-weak"
  >
    <div class="flex items-center gap-2 pb-2">
      <Icon icon="i-woot-overview" class="size-4 text-n-slate-11" />
      <h3 class="text-n-slate-11 text-body-main">
        {{ t('CONTACTS_LAYOUT.CARD.QUICK_OVERVIEW.TITLE') }}
      </h3>
    </div>
    <!-- Section 1: Basic Information -->
    <div
      class="hidden lg:flex rounded-xl bg-n-card w-auto outline outline-1 outline-n-container -outline-offset-1 p-3"
    >
      <div class="flex flex-wrap items-center gap-2 w-full">
        <div class="flex items-center gap-1">
          <Icon icon="i-lucide-circle-user" class="size-4 text-n-slate-11" />
          <span class="text-label-small text-n-slate-11 m-0">
            {{ t('CONTACTS_LAYOUT.CARD.QUICK_OVERVIEW.BASIC_INFO') }}
          </span>
        </div>
        <div
          v-if="contactData?.email"
          class="h-3 w-px bg-n-strong rounded-lg"
        />
        <!-- Email -->
        <div v-if="contactData?.email" class="flex items-center gap-1">
          <Icon
            icon="i-woot-mail"
            class="size-4 text-n-slate-11 flex-shrink-0"
          />
          <span class="text-body-main text-n-slate-12 truncate">
            {{ contactData.email }}
          </span>
        </div>
        <div
          v-if="contactData?.phoneNumber"
          class="h-3 w-px bg-n-strong rounded-lg"
        />
        <!-- Phone Number -->
        <div v-if="contactData?.phoneNumber" class="flex items-center gap-1">
          <Icon
            icon="i-lucide-phone"
            class="size-3.5 text-n-slate-11 flex-shrink-0"
          />
          <span class="text-body-main text-n-slate-12 truncate">
            {{ contactData.phoneNumber }}
          </span>
        </div>
        <div v-if="companyName" class="h-3 w-px bg-n-strong rounded-lg" />
        <!-- Company Name -->
        <div v-if="companyName" class="flex items-center gap-1">
          <Icon
            icon="i-lucide-briefcase-business"
            class="size-4 text-n-slate-11 flex-shrink-0"
          />
          <span class="text-body-main text-n-slate-12 truncate">
            {{ companyName }}
          </span>
        </div>
        <div v-if="countryDetails" class="h-3 w-px bg-n-strong rounded-lg" />
        <!-- Location (Country & City) -->
        <div v-if="countryDetails" class="flex items-center gap-1">
          <Flag
            :country="countryDetails.countryCode"
            class="size-4 flex-shrink-0"
          />
          <span class="text-body-main text-n-slate-12 truncate">
            {{ formattedLocation }}
          </span>
        </div>
        <div
          v-if="contactLabels.length > 0"
          class="h-3 w-px bg-n-strong rounded-lg"
        />
        <!-- Labels -->

        <ContactLabels
          v-if="contactLabels.length > 0"
          :labels="contactLabels"
          disable-toggle
          class="my-0 flex-1"
        />
      </div>
    </div>

    <!-- Section 2: Latest Contact Note -->
    <div
      class="flex flex-col rounded-xl bg-n-card outline outline-1 outline-n-container -outline-offset-1 p-3 gap-1.6 w-full gap-1.5"
    >
      <div class="flex items-center gap-2 py-1">
        <div class="flex items-center gap-1.5">
          <Icon icon="i-lucide-notebook-pen" class="size-3.5 text-n-slate-11" />
          <span class="text-label-small text-n-slate-11 m-0">
            {{ t('CONTACTS_LAYOUT.CARD.QUICK_OVERVIEW.LATEST_NOTE') }}
          </span>
        </div>
        <template v-if="latestNote">
          <div class="h-3 w-px bg-n-strong rounded-lg" />
          <span class="text-label-small text-n-slate-11">
            {{ formatTimestamp(latestNote.createdAt) }}
          </span>
        </template>
      </div>

      <div v-if="latestNote" class="flex items-center gap-1.5">
        <Avatar
          v-tooltip.left="{
            content: getWrittenBy(latestNote),
            delay: { show: 500, hide: 0 },
          }"
          :name="latestNote?.user?.name || 'Bot'"
          :src="
            latestNote?.user?.name
              ? latestNote?.user?.thumbnail
              : '/assets/images/chatwoot_bot.png'
          "
          :size="14"
          rounded-full
        />
        <p class="text-body-main text-n-slate-12 m-0 line-clamp-1">
          {{ latestNote.content }}
        </p>
      </div>
      <p v-else class="text-body-para text-n-slate-10 m-0 italic">
        {{ t('CONTACTS_LAYOUT.CARD.QUICK_OVERVIEW.NO_NOTES') }}
      </p>
    </div>

    <!-- Section 3: Latest Previous Conversation -->
    <div
      v-if="latestConversation"
      class="flex flex-col rounded-xl bg-n-card outline outline-1 outline-n-container -outline-offset-1 p-3 gap-1.6 w-full gap-1.5 cursor-pointer"
      @click="getConversationUrl(latestConversation.id)"
    >
      <div
        class="flex justify-between gap-2 w-full min-w-0"
        :class="
          latestConversation?.labels?.length > 0
            ? 'sm:flex-row flex-col items-start sm:items-center '
            : 'flex-row items-center'
        "
      >
        <div class="flex items-center gap-2 py-1 min-w-0 flex-shrink">
          <div class="flex items-center gap-1.5 min-w-0">
            <Icon
              icon="i-lucide-message-circle"
              class="size-3.5 text-n-slate-11"
            />
            <span class="text-label-small text-n-slate-11 m-0 truncate">
              {{ t('CONTACTS_LAYOUT.CARD.QUICK_OVERVIEW.LATEST_CONVERSATION') }}
            </span>
          </div>
          <div v-if="inbox?.id" class="h-3 w-px bg-n-strong rounded-lg" />
          <div class="flex items-center gap-1 min-w-0">
            <InboxName
              v-if="inbox?.id"
              :inbox="inbox"
              class="gap-1 [&>span]:text-n-slate-11"
            />
            <div
              v-if="latestConversation?.id"
              class="flex items-center gap-1 min-w-0"
            >
              <Icon
                icon="i-woot-hash"
                class="size-3.5 text-n-slate-10 flex-shrink-0"
              />
              <span class="text-label-small truncate text-n-slate-11">
                {{ latestConversation.id }}
              </span>
            </div>
          </div>
          <div
            v-if="latestConversation?.createdAt"
            class="h-3 w-px bg-n-strong rounded-lg"
          />
          <span
            v-if="latestConversation?.updatedAt"
            class="text-label-small text-n-slate-11 truncate min-w-0"
          >
            {{ formatTimestamp(latestConversation.updatedAt) }}
          </span>
        </div>
        <ContactLabels
          v-if="latestConversation?.labels?.length > 0"
          :labels="latestConversation.labels"
          class="flex-1 min-w-0 sm:justify-end w-full sm:w-auto"
          disable-toggle
        >
          <template #before>
            <div data-before-slot class="flex items-center gap-1.5">
              <CardPriorityIcon
                v-if="latestConversation.priority"
                :priority="latestConversation.priority"
                class="flex-shrink-0"
              />
              <Avatar
                v-if="assignee?.name"
                v-tooltip.top="assignee.name"
                :name="assignee.name"
                :src="assignee.thumbnail"
                :size="14"
                :status="assignee.availabilityStatus"
                hide-offline-status
                rounded-full
              />
              <CardStatusIcon
                v-if="latestConversation.status"
                :status="latestConversation.status"
              />
              <div class="h-3 w-px bg-n-weak rounded-lg mx-1" />
            </div>
          </template>
        </ContactLabels>
        <div v-else class="flex items-center justify-end gap-1.5 flex-1">
          <CardPriorityIcon
            v-if="latestConversation.priority"
            :priority="latestConversation.priority"
            class="flex-shrink-0"
          />
          <Avatar
            v-if="assignee?.name"
            v-tooltip.top="assignee.name"
            :name="assignee.name"
            :src="assignee.thumbnail"
            :size="14"
            :status="assignee.availability_status"
            hide-offline-status
            rounded-full
          />
          <CardStatusIcon
            v-if="latestConversation.status"
            :status="latestConversation.status"
          />
        </div>
      </div>
      <CardContent
        v-if="lastMessageInConversation"
        :last-message="lastMessageInConversation"
        :unread-count="lastMessageInConversation?.conversation?.unreadCount"
      />
    </div>
  </div>
</template>
