<script setup>
import ContactsForm from './ContactsForm.vue';

// Sample contact data based on the structure from ContactsCard.vue
const contactData = {
  id: 370,
  name: 'John Doe',
  email: 'johndoe@chatwoot.com',
  phoneNumber: '+918634322418',
  additionalAttributes: {
    city: 'Kerala',
    country: 'India',
    description: 'Curious about the web.',
    companyName: 'Chatwoot',
    countryCode: 'IN',
    socialProfiles: {
      github: 'johndoe',
      twitter: 'johndoe',
      facebook: 'johndoe',
      linkedin: 'johndoe',
      instagram: 'johndoe',
    },
  },
};

const handleUpdate = updatedData => {
  console.log('Form updated:', updatedData);
};
</script>

<template>
  <Story
    title="Components/Contacts/ContactsForm"
    :layout="{ type: 'grid', width: '600px' }"
  >
    <Variant title="Default without border">
      <div class="p-6 border rounded-lg border-n-strong">
        <ContactsForm :contact-data="contactData" @update="handleUpdate" />
      </div>
    </Variant>

    <Variant title="Details View with border">
      <div class="p-6 border rounded-lg border-n-strong">
        <ContactsForm
          :contact-data="contactData"
          is-details-view
          @update="handleUpdate"
        />
      </div>
    </Variant>

    <Variant title="Minimal Data">
      <div class="p-6 border rounded-lg border-n-strong">
        <ContactsForm
          :contact-data="{
            id: 21,
            name: 'Ophelia Folkard',
            email: 'ofolkardi@taobao.test',
            phoneNumber: '',
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
          }"
          @update="handleUpdate"
        />
      </div>
    </Variant>

    <Variant title="With All Social Profiles">
      <div class="p-6 border rounded-lg border-n-strong">
        <ContactsForm
          :contact-data="{
            ...contactData,
            additionalAttributes: {
              ...contactData.additionalAttributes,
              socialProfiles: {
                github: 'cmathersonj',
                twitter: 'cmather',
                facebook: 'cmathersonj',
                linkedin: 'cmathersonj',
                instagram: 'cmathersonjs',
              },
            },
          }"
          @update="handleUpdate"
        />
      </div>
    </Variant>
  </Story>
</template>
