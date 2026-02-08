<script setup>
import ContactMergeForm from '../ContactMergeForm.vue';
import { contactData, primaryContactList } from './fixtures';

const handleSearch = query => {
  console.log('Searching for:', query);
};

const handleUpdate = value => {
  console.log('Primary contact updated:', value);
};
</script>

<template>
  <Story
    title="Components/Contacts/ContactMergeForm"
    :layout="{ type: 'grid', width: '600px' }"
  >
    <Variant title="Default">
      <div class="p-6 border rounded-lg border-n-strong">
        <ContactMergeForm
          :selected-contact="contactData"
          :primary-contact-list="primaryContactList"
          :primary-contact-id="null"
          :is-searching="false"
          @update:primary-contact-id="handleUpdate"
          @search="handleSearch"
        />
      </div>
    </Variant>

    <Variant title="With Selected Primary Contact">
      <div class="p-6 border rounded-lg border-n-strong">
        <ContactMergeForm
          :selected-contact="contactData"
          :primary-contact-list="primaryContactList"
          :primary-contact-id="1"
          :is-searching="false"
          @update:primary-contact-id="handleUpdate"
          @search="handleSearch"
        />
      </div>
    </Variant>

    <Variant title="Error State">
      <div class="p-6 border rounded-lg border-n-strong">
        <ContactMergeForm
          :selected-contact="contactData"
          :primary-contact-list="primaryContactList"
          :primary-contact-id="null"
          :is-searching="false"
          has-error
          error-message="Please select a primary contact"
          @update:primary-contact-id="handleUpdate"
          @search="handleSearch"
        />
      </div>
    </Variant>

    <Variant title="Empty Primary Contact List">
      <div class="p-6 border rounded-lg border-n-strong">
        <ContactMergeForm
          :selected-contact="contactData"
          :primary-contact-list="[]"
          :primary-contact-id="null"
          :is-searching="false"
          @update:primary-contact-id="handleUpdate"
          @search="handleSearch"
        />
      </div>
    </Variant>
  </Story>
</template>
