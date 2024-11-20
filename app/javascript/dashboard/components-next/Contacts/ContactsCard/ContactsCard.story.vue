<script setup>
import { ref } from 'vue';

import ContactsCard from './ContactsCard.vue';

const contacts = [
  {
    additionalAttributes: {
      socialProfiles: {},
    },
    availabilityStatus: null,
    email: 'johndoe@chatwoot.com',
    id: 370,
    name: 'John Doe',
    phoneNumber: '+918634322418',
    identifier: null,
    thumbnail: 'https://api.dicebear.com/9.x/thumbs/svg?seed=Felix',
    customAttributes: {},
    lastActivityAt: 1731608270,
    createdAt: 1731586271,
  },
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
    availabilityStatus: null,
    email: 'ozler@chatwoot.com',
    id: 29,
    name: 'Abraham Ozlers',
    phoneNumber: '+246232222222',
    identifier: null,
    thumbnail: 'https://api.dicebear.com/9.x/thumbs/svg?seed=Upload',
    customAttributes: {
      dateContact: '2024-02-01T00:00:00.000Z',
      linkContact: 'https://staging.chatwoot.com/app/accounts/3/contacts-new',
      listContact: 'Not spam',
      numberContact: '12',
    },
    lastActivityAt: 1712127410,
    createdAt: 1712127389,
  },
  {
    additionalAttributes: {
      city: 'Kerala',
      country: 'India',
      description:
        "I'm Candice developer focusing on building things for the web 🌍. Currently, I’m working as a Product Developer here at @chatwootapp ⚡️🔥",
      companyName: 'Chatwoot',
      countryCode: 'IN',
      socialProfiles: {
        github: 'cmathersonj',
        twitter: 'cmather',
        facebook: 'cmathersonj',
        linkedin: 'cmathersonj',
        instagram: 'cmathersonjs',
      },
    },
    availabilityStatus: null,
    email: 'cmathersonj@va.test',
    id: 22,
    name: 'Candice Matherson',
    phoneNumber: '+917474774742',
    identifier: null,
    thumbnail: 'https://api.dicebear.com/9.x/thumbs/svg?seed=Emery',
    customAttributes: {
      dateContact: '2024-11-12T03:23:06.963Z',
      linkContact: 'https://sd.sd',
      textContact: 'hey',
      numberContact: '12',
      checkboxContact: true,
    },
    lastActivityAt: 1712123233,
    createdAt: 1712123233,
  },
  {
    additionalAttributes: {
      city: '',
      country: '',
      description: '',
      companyName: '',
      countryCode: '',
      socialProfiles: {
        github: '',
        twitter: '',
        facebook: '',
        linkedin: '',
        instagram: '',
      },
    },
    availabilityStatus: null,
    email: 'ofolkardi@taobao.test',
    id: 21,
    name: 'Ophelia Folkard',
    phoneNumber: '',
    identifier: null,
    thumbnail:
      'https://sivin-tunnel.chatwoot.dev/rails/active_storage/representations/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBPZz09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--08dcac8eb72ef12b2cad92d58dddd04cd8a5f513/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCem9MWm05eWJXRjBTU0lJYW5CbkJqb0dSVlE2RTNKbGMybDZaVjkwYjE5bWFXeHNXd2RwQWZvdyIsImV4cCI6bnVsbCwicHVyIjoidmFyaWF0aW9uIn19--df796c2af3c0153e55236c2f3cf3a199ac2cb6f7/32.jpg',
    customAttributes: {},
    lastActivityAt: 1712123233,
    createdAt: 1712123233,
  },
  {
    additionalAttributes: {
      socialProfiles: {},
    },
    availabilityStatus: null,
    email: 'wcasteloth@exblog.jp',
    id: 20,
    name: 'Willy Castelot',
    phoneNumber: '+919384',
    identifier: null,
    thumbnail: 'https://api.dicebear.com/9.x/thumbs/svg?seed=Jade',
    customAttributes: {},
    lastActivityAt: 1712123233,
    createdAt: 1712123233,
  },
  {
    additionalAttributes: {
      city: '',
      country: '',
      description: '',
      companyName: '',
      countryCode: '',
      socialProfiles: {
        github: '',
        twitter: '',
        facebook: '',
        linkedin: '',
        instagram: '',
      },
    },
    availabilityStatus: null,
    email: 'ederingtong@printfriendly.test',
    id: 19,
    name: 'Elisabeth Derington',
    phoneNumber: '',
    identifier: null,
    thumbnail: 'https://api.dicebear.com/9.x/avataaars/svg?seed=Jade',
    customAttributes: {},
    lastActivityAt: 1712123232,
    createdAt: 1712123232,
  },
];

const expandedCardId = ref(null);

const toggleExpanded = id => {
  expandedCardId.value = expandedCardId.value === id ? null : id;
};
</script>

<template>
  <Story
    title="Components/Contacts/ContactsCard"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <Variant title="Default with expandable function">
      <div class="flex flex-col p-4">
        <ContactsCard
          v-bind="contacts[0]"
          :is-expanded="expandedCardId === contacts[0].id"
          @toggle="toggleExpanded(contacts[0].id)"
          @update-contact="() => {}"
          @show-contact="() => {}"
        />
      </div>
    </Variant>

    <Variant title="With Company Name and without phone number">
      <div class="flex flex-col p-4">
        <ContactsCard
          v-bind="{ ...contacts[1], phoneNumber: '' }"
          :is-expanded="false"
          @toggle="() => {}"
          @update-contact="() => {}"
          @show-contact="() => {}"
        />
      </div>
    </Variant>

    <Variant title="Expanded State">
      <div class="flex flex-col p-4">
        <ContactsCard
          v-bind="contacts[2]"
          is-expanded
          @toggle="() => {}"
          @update-contact="() => {}"
          @show-contact="() => {}"
        />
      </div>
    </Variant>

    <Variant title="Without Email and Phone">
      <div class="flex flex-col p-4">
        <ContactsCard
          v-bind="{ ...contacts[3], email: '', phoneNumber: '' }"
          :is-expanded="false"
          @toggle="() => {}"
          @update-contact="() => {}"
          @show-contact="() => {}"
        />
      </div>
    </Variant>
  </Story>
</template>
