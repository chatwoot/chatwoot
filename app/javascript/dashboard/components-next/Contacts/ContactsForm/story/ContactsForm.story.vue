<script setup>
import ContactsForm from '../ContactsForm.vue';
import { contactData } from './fixtures';

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
