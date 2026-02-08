<script setup>
import { computed } from 'vue';
import ConversationCard from './ConversationCard.vue';

// Base conversation object
const conversationWithoutMeta = {
  meta: {
    sender: {
      additionalAttributes: {},
      availabilityStatus: 'offline',
      email: 'candice@chatwoot.com',
      id: 29,
      name: 'Candice Matherson',
      phone_number: '+918585858585',
      identifier: null,
      thumbnail: '',
      customAttributes: {
        linkContact: 'https://apple.com',
        listContact: 'Not spam',
        textContact: 'hey',
        checkboxContact: true,
      },
      last_activity_at: 1712127410,
      created_at: 1712127389,
    },
    channel: 'Channel::Email',
    assignee: {
      id: 1,
      accountId: 2,
      availabilityStatus: 'online',
      autoOffline: false,
      confirmed: true,
      email: 'sivin@chatwoot.com',
      availableName: 'Sivin',
      name: 'Sivin',
      role: 'administrator',
      thumbnail: '',
      customRoleId: null,
    },
    hmacVerified: false,
  },
  id: 38,
  messages: [
    {
      id: 3597,
      content: 'Sivin set the priority to low',
      accountId: 2,
      inboxId: 7,
      conversationId: 38,
      messageType: 2,
      createdAt: 1730885168,
      updatedAt: '2024-11-06T09:26:08.565Z',
      private: false,
      status: 'sent',
      source_id: null,
      contentType: 'text',
      contentAttributes: {},
      senderType: null,
      senderId: null,
      externalSourceIds: {},
      additionalAttributes: {},
      processedMessageContent: 'Sivin set the priority to low',
      sentiment: {},
      conversation: {
        assigneeId: 1,
        unreadCount: 0,
        lastActivityAt: 1730885168,
        contactInbox: {
          sourceId: 'candice@chatwoot.com',
        },
      },
    },
  ],
  accountId: 2,
  uuid: '21bd8638-a711-4080-b4ac-7fda1bc71837',
  additionalAttributes: {
    mail_subject: 'Test email',
  },
  agentLastSeenAt: 0,
  assigneeLastSeenAt: 0,
  canReply: true,
  contactLastSeenAt: 0,
  customAttributes: {},
  inboxId: 7,
  labels: [],
  status: 'open',
  createdAt: 1730836533,
  timestamp: 1730885168,
  firstReplyCreatedAt: 1730836533,
  unreadCount: 0,
  lastNonActivityMessage: {
    id: 3591,
    content:
      'Hello, I bought some paper but they did not come with the indices as we had assumed. Was there a change in the product line?',
    account_id: 2,
    inbox_id: 7,
    conversation_id: 38,
    message_type: 1,
    created_at: 1730836533,
    updated_at: '2024-11-05T19:55:37.158Z',
    private: false,
    status: 'sent',
    source_id:
      'conversation/21bd8638-a711-4080-b4ac-7fda1bc71837/messages/3591@paperlayer.test',
    content_type: 'text',
    content_attributes: {
      cc_emails: ['test@gmail.com'],
      bcc_emails: [],
      to_emails: [],
    },
    sender_type: 'User',
    sender_id: 1,
    external_source_ids: {},
    additional_attributes: {},
    processed_message_content:
      'Hello, I bought some paper but they did not come with the indices as we had assumed. Was there a change in the product line?',
    sentiment: {},
    conversation: {
      assignee_id: 1,
      unread_count: 0,
      last_activity_at: 1730885168,
      contact_inbox: {
        source_id: 'candice@chatwoot.com',
      },
    },
    sender: {
      id: 1,
      name: 'Sivin',
      available_name: 'Sivin',
      avatar_url: '',
      type: 'user',
      availability_status: 'online',
      thumbnail: '',
    },
  },
  lastActivityAt: 1730885168,
  priority: 'low',
  waitingSince: 0,
  slaPolicyId: null,
  slaEvents: [],
};

const conversationWithMeta = {
  meta: {
    sender: {
      additionalAttributes: {},
      availabilityStatus: 'offline',
      email: 'willy@chatwoot.com',
      id: 29,
      name: 'Willy Castelot',
      phoneNumber: '+918585858585',
      identifier: null,
      thumbnail: '',
      customAttributes: {
        linkContact: 'https://apple.com',
        listContact: 'Not spam',
        textContact: 'hey',
        checkboxContact: true,
      },
      lastActivityAt: 1712127410,
      createdAt: 1712127389,
    },
    channel: 'Channel::Email',
    assignee: {
      id: 1,
      accountId: 2,
      availabilityStatus: 'online',
      autoOffline: false,
      confirmed: true,
      email: 'sivin@chatwoot.com',
      availableName: 'Sivin',
      name: 'Sivin',
      role: 'administrator',
      thumbnail: '',
      customRoleId: null,
    },
    hmacVerified: false,
  },
  id: 37,
  messages: [
    {
      id: 3599,
      content:
        'If you want to buy our premium supplies,we can offer you a 20% discount! They come with indices and lazer beams!',
      accountId: 2,
      inboxId: 7,
      conversationId: 37,
      messageType: 1,
      createdAt: 1730885428,
      updatedAt: '2024-11-06T09:30:30.619Z',
      private: false,
      status: 'sent',
      sourceId:
        'conversation/53df668d-329d-420e-8fe9-980cb0e4d63c/messages/3599@paperlayer.test',
      contentType: 'text',
      contentAttributes: {
        ccEmails: [],
        bccEmails: [],
        toEmails: [],
      },
      sender_type: 'User',
      senderId: 1,
      externalSourceIds: {},
      additionalAttributes: {},
      processedMessageContent:
        'If you want to buy our premium supplies,we can offer you a 20% discount! They come with indices and lazer beams!',
      sentiment: {},
      conversation: {
        assignee_id: 1,
        unread_count: 0,
        last_activity_at: 1730885428,
        contact_inbox: {
          source_id: 'candice@chatwoot.com',
        },
      },
      sender: {
        id: 1,
        name: 'Sivin',
        availableName: 'Sivin',
        avatarUrl: '',
        type: 'user',
        availabilityStatus: 'online',
        thumbnail: '',
      },
    },
  ],
  accountId: 2,
  uuid: '53df668d-329d-420e-8fe9-980cb0e4d63c',
  additionalAttributes: {
    mail_subject: 'we',
  },
  agentLastSeenAt: 1730885428,
  assigneeLastSeenAt: 1730885428,
  canReply: true,
  contactLastSeenAt: 0,
  customAttributes: {},
  inboxId: 7,
  labels: [
    'billing',
    'delivery',
    'lead',
    'premium-customer',
    'software',
    'ops-handover',
  ],
  muted: false,
  snoozedUntil: null,
  status: 'open',
  createdAt: 1722487645,
  timestamp: 1730885428,
  firstReplyCreatedAt: 1722487645,
  unreadCount: 0,
  lastNonActivityMessage: {
    id: 3599,
    content:
      'If you want to buy our premium supplies,we can offer you a 20% discount! They come with indices and lazer beams!',
    account_id: 2,
    inbox_id: 7,
    conversation_id: 37,
    message_type: 1,
    created_at: 1730885428,
    updated_at: '2024-11-06T09:30:30.619Z',
    private: false,
    status: 'sent',
    source_id:
      'conversation/53df668d-329d-420e-8fe9-980cb0e4d63c/messages/3599@paperlayer.test',
    content_type: 'text',
    content_attributes: {
      cc_emails: [],
      bcc_emails: [],
      to_emails: [],
    },
    sender_type: 'User',
    sender_id: 1,
    external_source_ids: {},
    additional_attributes: {},
    processed_message_content:
      'If you want to buy our premium supplies,we can offer you a 20% discount! They come with indices and lazer beams!',
    sentiment: {},
    conversation: {
      assignee_id: 1,
      unread_count: 2,
      last_activity_at: 1730885428,
      contact_inbox: {
        source_id: 'willy@chatwoot.com',
      },
    },
    sender: {
      id: 1,
      name: 'Sivin',
      available_name: 'Sivin',
      avatar_url: '',
      type: 'user',
      availability_status: 'online',
      thumbnail: '',
    },
  },
  lastActivityAt: 1730885428,
  priority: 'urgent',
  waitingSince: 1730885428,
  slaPolicyId: 3,
  appliedSla: {
    id: 4,
    sla_id: 3,
    sla_status: 'active_with_misses',
    created_at: 1712127410,
    updated_at: 1712127545,
    sla_description:
      'Premium Service Level Agreements (SLAs) are contracts that define clear expectations ',
    sla_name: 'Premium SLA',
    sla_first_response_time_threshold: 120,
    sla_next_response_time_threshold: 180,
    sla_only_during_business_hours: false,
    sla_resolution_time_threshold: 360,
  },
  slaEvents: [
    {
      id: 8,
      event_type: 'frt',
      meta: {},
      updated_at: 1712127545,
      created_at: 1712127545,
    },
    {
      id: 9,
      event_type: 'rt',
      meta: {},
      updated_at: 1712127790,
      created_at: 1712127790,
    },
  ],
};

const contactForConversationWithoutMeta = computed(() => ({
  availabilityStatus: null,
  email: 'candice@chatwoot.com',
  id: 29,
  name: 'Candice Matherson',
  phoneNumber: '+918585858585',
  identifier: null,
  thumbnail: 'https://api.dicebear.com/9.x/dylan/svg?seed=George',
  customAttributes: {},
  last_activity_at: 1712127410,
  createdAt: 1712127389,
  contactInboxes: [],
}));

const contactForConversationWithMeta = computed(() => ({
  availabilityStatus: null,
  email: 'willy@chatwoot.com',
  id: 29,
  name: 'Willy Castelot',
  phoneNumber: '+918585858585',
  identifier: null,
  thumbnail: 'https://api.dicebear.com/9.x/dylan/svg?seed=Liam',
  customAttributes: {},
  lastActivityAt: 1712127410,
  createdAt: 1712127389,
  contactInboxes: [],
}));

const webWidgetInbox = computed(() => ({
  phone_number: '+918585858585',
  channel_type: 'Channel::WebWidget',
}));

const accountLabels = computed(() => [
  {
    id: 1,
    title: 'billing',
    description: 'Label is used for tagging billing related conversations',
    color: '#28AD21',
    show_on_sidebar: true,
  },
  {
    id: 3,
    title: 'delivery',
    description: null,
    color: '#A2FDD5',
    show_on_sidebar: true,
  },
  {
    id: 6,
    title: 'lead',
    description: null,
    color: '#F161C8',
    show_on_sidebar: true,
  },
  {
    id: 4,
    title: 'ops-handover',
    description: null,
    color: '#A53326',
    show_on_sidebar: true,
  },
  {
    id: 5,
    title: 'premium-customer',
    description: null,
    color: '#6FD4EF',
    show_on_sidebar: true,
  },
  {
    id: 2,
    title: 'software',
    description: null,
    color: '#8F6EF2',
    show_on_sidebar: true,
  },
]);
</script>

<template>
  <Story
    title="Components/ConversationCard"
    :layout="{ type: 'grid', width: '600px' }"
  >
    <Variant title="Conversation without meta">
      <div class="flex flex-col">
        <ConversationCard
          :key="conversationWithoutMeta.id"
          :conversation="conversationWithoutMeta"
          :contact="contactForConversationWithoutMeta"
          :state-inbox="webWidgetInbox"
          :account-labels="accountLabels"
          class="hover:bg-n-alpha-1"
        />
      </div>
    </Variant>
    <Variant title="Conversation with meta (SLA, Labels)">
      <div class="flex flex-col">
        <ConversationCard
          :key="conversationWithMeta.id"
          :conversation="{
            ...conversationWithMeta,
            priority: 'medium',
          }"
          :contact="contactForConversationWithMeta"
          :state-inbox="webWidgetInbox"
          :account-labels="accountLabels"
          class="hover:bg-n-alpha-1"
        />
      </div>
    </Variant>
    <Variant title="Conversation without meta (Unread count)">
      <div class="flex flex-col">
        <ConversationCard
          :key="conversationWithoutMeta.id"
          :conversation="{
            ...conversationWithoutMeta,
            unreadCount: 2,
            priority: 'high',
          }"
          :contact="contactForConversationWithoutMeta"
          :state-inbox="webWidgetInbox"
          :account-labels="accountLabels"
          class="hover:bg-n-alpha-1"
        />
      </div>
    </Variant>
    <Variant title="Conversation with meta (SLA, Labels, Unread count)">
      <div class="flex flex-col">
        <ConversationCard
          :key="conversationWithMeta.id"
          :conversation="{
            ...conversationWithMeta,
            unreadCount: 2,
          }"
          :contact="contactForConversationWithMeta"
          :state-inbox="webWidgetInbox"
          :account-labels="accountLabels"
          class="hover:bg-n-alpha-1"
        />
      </div>
    </Variant>
  </Story>
</template>
