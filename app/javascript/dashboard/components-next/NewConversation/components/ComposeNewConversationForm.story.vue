<script setup>
import { ref } from 'vue';
import ComposeNewConversationForm from './ComposeNewConversationForm.vue';

const contacts = [
  {
    additionalAttributes: {
      city: 'kerala',
      country: 'India',
      description: 'Curious about the web. ',
      companyName: 'Chatwoot',
      countryCode: '',
      socialProfiles: {
        github: 'abozler',
        twitter: 'ozler',
        facebook: 'abozler',
        linkedin: 'abozler',
        instagram: 'ozler',
      },
    },
    availabilityStatus: 'offline',
    email: 'ozler@chatwoot.com',
    id: 29,
    name: 'Abraham Ozlers',
    phoneNumber: '+246232222222',
    identifier: null,
    thumbnail:
      'https://sivin-tunnel.chatwoot.dev/rails/active_storage/representations/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBc0FCIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--c20b627b384f5981112e949b8414cd4d3e5912ee/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCem9MWm05eWJXRjBTU0lJY0c1bkJqb0dSVlE2RTNKbGMybDZaVjkwYjE5bWFXeHNXd2RwQWZvdyIsImV4cCI6bnVsbCwicHVyIjoidmFyaWF0aW9uIn19--ebe60765d222d11ade39165eae49cc4b2de18d89/Avatar%201.20.41%E2%80%AFAM.png',
    customAttributes: {
      dateContact: '2024-02-01T00:00:00.000Z',
      linkContact: 'https://staging.chatwoot.com/app/accounts/3/contacts-new',
      listContact: 'Not spam',
      numberContact: '12',
    },
    lastActivityAt: 1712127410,
    createdAt: 1712127389,
  },
];

const selectedContact = ref({
  email: 'ozler@chatwoot.com',
  id: 29,
  label: 'Abraham Ozlers (ozler@chatwoot.com)',
  name: 'Abraham Ozlers',
  thumbnail: {
    name: 'Abraham Ozlers',
    src: 'https://sivin-tunnel.chatwoot.dev/rails/active_storage/representations/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBc0FCIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--c20b627b384f5981112e949b8414cd4d3e5912ee/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCem9MWm05eWJXRjBTU0lJY0c1bkJqb0dSVlE2RTNKbGMybDZaVjkwYjE5bWFXeHNXd2RwQWZvdyIsImV4cCI6bnVsbCwicHVyIjoidmFyaWF0aW9uIn19--ebe60765d222d11ade39165eae49cc4b2de18d89/Avatar%201.20.41%E2%80%AFAM.png',
  },
  contactInboxes: [
    {
      id: 7,
      label: 'PaperLayer Email (testba@paperlayer.test)',
      name: 'PaperLayer Email',
      email: 'testba@paperlayer.test',
      channelType: 'Channel::Email',
    },
    {
      id: 8,
      label: 'PaperLayer WhatsApp',
      name: 'PaperLayer WhatsApp',
      sourceId: '123456',
      phoneNumber: '+1223233434',
      channelType: 'Channel::Whatsapp',
      messageTemplates: [
        {
          id: '1',
          name: 'shipment_confirmation',
          status: 'APPROVED',
          category: 'UTILITY',
          language: 'en_US',
          components: [
            {
              text: '{{1}}, great news! Your order {{2}} has shipped.\n\nTracking #: {{3}}\nEstimated delivery: {{4}}\n\nWe will provide updates until delivery.',
              type: 'BODY',
              example: {
                bodyText: [['John', '#12345', 'ZK4539O2311J', 'Jan 1, 2024']],
              },
            },
            {
              type: 'BUTTONS',
              buttons: [
                {
                  url: 'https://www.example.com/',
                  text: 'Track shipment',
                  type: 'URL',
                },
              ],
            },
          ],
          parameterFormat: 'POSITIONAL',
          libraryTemplateName: 'shipment_confirmation_2',
        },
        {
          id: '2',
          name: 'otp_test',
          status: 'APPROVED',
          category: 'AUTHENTICATION',
          language: 'en_US',
          components: [
            {
              text: 'Use code *{{1}}* to authorize your transaction.',
              type: 'BODY',
              example: {
                bodyText: [['123456']],
              },
            },
            {
              type: 'BUTTONS',
              buttons: [
                {
                  url: 'https://www.example.com/otp/code/?otp_type=ZERO_TAP&cta_display_name=Autofill&package_name=com.app&signature_hash=weew&code=otp{{1}}',
                  text: 'Copy code',
                  type: 'URL',
                  example: [
                    'https://www.example.com/otp/code/?otp_type=ZERO_TAP&cta_display_name=Autofill&package_name=com.app&signature_hash=weew&code=otp123456',
                  ],
                },
              ],
            },
          ],
          parameterFormat: 'POSITIONAL',
          libraryTemplateName: 'verify_transaction_1',
          messageSendTtlSeconds: 900,
        },
        {
          id: '3',
          name: 'hello_world',
          status: 'APPROVED',
          category: 'UTILITY',
          language: 'en_US',
          components: [
            {
              text: 'Hello World',
              type: 'HEADER',
              format: 'TEXT',
            },
            {
              text: 'Welcome and congratulations!! This message demonstrates your ability to send a WhatsApp message notification from the Cloud API, hosted by Meta. Thank you for taking the time to test with us.',
              type: 'BODY',
            },
            {
              text: 'WhatsApp Business Platform sample message',
              type: 'FOOTER',
            },
          ],
          parameterFormat: 'POSITIONAL',
        },
      ],
    },
    {
      id: 9,
      label: 'PaperLayer API',
      name: 'PaperLayer API',
      email: '',
      channelType: 'Channel::Api',
    },
  ],
});

const targetInbox = ref({
  id: 7,
  label: 'PaperLayer Email (testba@paperlayer.test)',
  name: 'PaperLayer Email',
  email: 'testba@paperlayer.test',
  channelType: 'Channel::Email',
});

const currentUser = {
  id: 1,
  name: 'John Doe',
  email: 'john@example.com',
};

// Event handlers
const onSearchContacts = query => {
  console.log('Searching contacts:', query);
};

const onUpdateSelectedContact = contact => {
  console.log('Selected contact updated:', contact);
};

const onUpdateTargetInbox = inbox => {
  console.log('Target inbox updated:', inbox);
  targetInbox.value = inbox;
  console.log('Target inbox updated:', inbox);
};

const onClearSelectedContact = () => {
  console.log('Contact cleared');
};

const onCreateConversation = payload => {
  console.log('Creating conversation:', payload);
};

const onDiscard = () => {
  console.log('Form discarded');
};
</script>

<template>
  <Story
    title="Components/Compose/ComposeNewConversationForm"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <Variant title="With all props">
      <div class="h-[600px] w-full relative">
        <ComposeNewConversationForm
          :contacts="contacts"
          contact-id=""
          :is-loading="false"
          :current-user="currentUser"
          :selected-contact="selectedContact"
          :target-inbox="targetInbox"
          :is-creating-contact="false"
          is-fetching-inboxes
          is-direct-uploads-enabled
          :contact-conversations-ui-flags="{ isCreating: false }"
          :contacts-ui-flags="{ isFetching: false }"
          class="!top-0"
          @search-contacts="onSearchContacts"
          @update-selected-contact="onUpdateSelectedContact"
          @update-target-inbox="onUpdateTargetInbox"
          @clear-selected-contact="onClearSelectedContact"
          @create-conversation="onCreateConversation"
          @discard="onDiscard"
        />
      </div>
    </Variant>

    <Variant title="With no target inbox">
      <div class="h-[200px] w-full relative">
        <ComposeNewConversationForm
          :contacts="contacts"
          contact-id=""
          :is-loading="false"
          :current-user="currentUser"
          :selected-contact="{ ...selectedContact, contactInboxes: [] }"
          :target-inbox="null"
          :is-creating-contact="false"
          :is-fetching-inboxes="false"
          is-direct-uploads-enabled
          :contact-conversations-ui-flags="{ isCreating: false }"
          :contacts-ui-flags="{ isFetching: false }"
          class="!top-0"
          @search-contacts="onSearchContacts"
          @update-selected-contact="onUpdateSelectedContact"
          @update-target-inbox="onUpdateTargetInbox"
          @clear-selected-contact="onClearSelectedContact"
          @create-conversation="onCreateConversation"
          @discard="onDiscard"
        />
      </div>
    </Variant>
  </Story>
</template>
