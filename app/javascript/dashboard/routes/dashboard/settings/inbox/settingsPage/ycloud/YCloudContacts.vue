<script>
import YCloudAPI from 'dashboard/api/ycloud';
import { useAlert } from 'dashboard/composables';
import SettingsSection from '../../../../../../components/SettingsSection.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: { SettingsSection, NextButton },
  props: {
    inbox: { type: Object, default: () => ({}) },
  },
  data() {
    return {
      contacts: [],
      isLoading: false,
      showCreateModal: false,
      newContact: { nickname: '', phoneNumber: '', email: '', countryCode: '', tags: [] },
      newTag: '',
    };
  },
  mounted() {
    this.fetchContacts();
  },
  methods: {
    async fetchContacts() {
      this.isLoading = true;
      try {
        const res = await YCloudAPI.listYCloudContacts(this.inbox.id);
        this.contacts = res.data.items || res.data || [];
      } catch {
        useAlert(this.$t('YCLOUD.CONTACTS.FETCH_ERROR'));
      }
      this.isLoading = false;
    },
    async createContact() {
      try {
        await YCloudAPI.createYCloudContact(this.inbox.id, this.newContact);
        useAlert(this.$t('YCLOUD.CONTACTS.CREATE_SUCCESS'));
        this.showCreateModal = false;
        this.resetForm();
        this.fetchContacts();
      } catch {
        useAlert(this.$t('YCLOUD.CONTACTS.CREATE_ERROR'));
      }
    },
    async deleteContact(contact) {
      if (!window.confirm(this.$t('YCLOUD.CONTACTS.DELETE_CONFIRM'))) return;
      try {
        await YCloudAPI.deleteYCloudContact(this.inbox.id, contact.id);
        useAlert(this.$t('YCLOUD.CONTACTS.DELETE_SUCCESS'));
        this.fetchContacts();
      } catch {
        useAlert(this.$t('YCLOUD.CONTACTS.DELETE_ERROR'));
      }
    },
    addTag() {
      if (this.newTag && !this.newContact.tags.includes(this.newTag)) {
        this.newContact.tags.push(this.newTag);
        this.newTag = '';
      }
    },
    removeTag(index) {
      this.newContact.tags.splice(index, 1);
    },
    resetForm() {
      this.newContact = { nickname: '', phoneNumber: '', email: '', countryCode: '', tags: [] };
      this.newTag = '';
    },
  },
};
</script>

<template>
  <div class="py-4">
    <SettingsSection :title="$t('YCLOUD.CONTACTS.TITLE')" :sub-title="$t('YCLOUD.CONTACTS.DESC')" :show-border="false">
      <div class="flex justify-end mb-4">
        <NextButton :label="$t('YCLOUD.CONTACTS.CREATE')" icon="i-lucide-plus" @click="showCreateModal = true" />
      </div>

      <div v-if="isLoading" class="text-center py-8"><span class="spinner" /></div>
      <div v-else-if="contacts.length === 0" class="text-center py-8 text-n-slate-11">{{ $t('YCLOUD.CONTACTS.EMPTY') }}</div>

      <table v-else class="min-w-full">
        <thead>
          <tr class="border-b border-n-weak">
            <th class="text-left py-2 px-3 text-sm font-medium">{{ $t('YCLOUD.CONTACTS.NICKNAME') }}</th>
            <th class="text-left py-2 px-3 text-sm font-medium">{{ $t('YCLOUD.CONTACTS.PHONE') }}</th>
            <th class="text-left py-2 px-3 text-sm font-medium">{{ $t('YCLOUD.CONTACTS.EMAIL_FIELD') }}</th>
            <th class="text-left py-2 px-3 text-sm font-medium">{{ $t('YCLOUD.CONTACTS.TAGS') }}</th>
            <th class="text-right py-2 px-3 text-sm font-medium">{{ $t('YCLOUD.TEMPLATES.ACTIONS') }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="c in contacts" :key="c.id" class="border-b border-n-weak/50 hover:bg-n-slate-1">
            <td class="py-2 px-3 text-sm">{{ c.nickname }}</td>
            <td class="py-2 px-3 text-sm">{{ c.phoneNumber }}</td>
            <td class="py-2 px-3 text-sm">{{ c.email }}</td>
            <td class="py-2 px-3 text-sm">{{ (c.tags || []).join(', ') }}</td>
            <td class="py-2 px-3 text-right">
              <button class="text-red-600 text-sm hover:underline" @click="deleteContact(c)">{{ $t('YCLOUD.COMMON.DELETE') }}</button>
            </td>
          </tr>
        </tbody>
      </table>
    </SettingsSection>

    <!-- Create Contact Modal -->
    <div v-if="showCreateModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div class="bg-white rounded-xl p-6 w-full max-w-lg shadow-xl">
        <h3 class="text-lg font-semibold mb-4">{{ $t('YCLOUD.CONTACTS.CREATE') }}</h3>
        <label class="block mb-3">{{ $t('YCLOUD.CONTACTS.NICKNAME') }}<input v-model="newContact.nickname" type="text" class="mt-1" /></label>
        <label class="block mb-3">{{ $t('YCLOUD.CONTACTS.PHONE') }}<input v-model="newContact.phoneNumber" type="tel" class="mt-1" placeholder="+1234567890" /></label>
        <label class="block mb-3">{{ $t('YCLOUD.CONTACTS.EMAIL_FIELD') }}<input v-model="newContact.email" type="email" class="mt-1" /></label>
        <label class="block mb-3">{{ $t('YCLOUD.CONTACTS.COUNTRY_CODE') }}<input v-model="newContact.countryCode" type="text" class="mt-1" placeholder="US" maxlength="2" /></label>
        <div class="mb-3">
          <p class="font-medium text-sm mb-1">{{ $t('YCLOUD.CONTACTS.TAGS') }}</p>
          <div class="flex flex-wrap gap-1 mb-2">
            <span v-for="(tag, i) in newContact.tags" :key="i" class="bg-n-blue-1 text-n-blue-text px-2 py-0.5 rounded text-xs flex items-center gap-1">
              {{ tag }} <button @click="removeTag(i)">&times;</button>
            </span>
          </div>
          <div class="flex gap-2">
            <input v-model="newTag" type="text" class="flex-1" @keyup.enter="addTag" />
            <NextButton :label="$t('YCLOUD.COMMON.ADD')" size="sm" @click="addTag" />
          </div>
        </div>
        <div class="flex justify-end gap-2 mt-4">
          <NextButton :label="$t('YCLOUD.COMMON.CANCEL')" variant="ghost" @click="showCreateModal = false; resetForm()" />
          <NextButton :label="$t('YCLOUD.COMMON.SAVE')" @click="createContact" />
        </div>
      </div>
    </div>
  </div>
</template>
