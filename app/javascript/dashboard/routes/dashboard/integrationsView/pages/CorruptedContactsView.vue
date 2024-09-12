<template>
  <div class="flex flex-row w-full">
    <div class="flex-1 overflow-auto">
      <settings-header
        button-route="new"
        :header-title="$t('CORRUPTED_CONTACTS.TITLE')"
        :show-new-button="false"
      />

      <div class="flex flex-row gap-4 p-8">
        <div class="w-full xl:w-3/5">
          <p
            v-if="!uiFlags.isFetching && records.length == 0"
            class="flex flex-col items-center justify-center h-full"
          >
            {{ $t('CORRUPTED_CONTACTS.LIST.404') }}
          </p>
          <woot-loading-state
            v-if="uiFlags.isFetching"
            :message="$t('LABEL_MGMT.LOADING')"
          />
          <table
            v-if="!uiFlags.isFetching && records.length > 0"
            class="woot-table"
          >
            <thead>
              <th
                v-for="thHeader in $t('CORRUPTED_CONTACTS.LIST.TABLE_HEADER')"
                :key="thHeader"
              >
                {{ thHeader }}
              </th>
            </thead>
            <tbody>
              <tr v-for="(contact, index) in records" :key="contact.title">
                <td class="label-title">
                  <woot-button
                    variant="clear"
                    class="pl-0"
                    @click="openContactInfoPanel(contact.id)"
                  >
                    {{ contact.name }}
                  </woot-button>
                </td>
                <td class="flex items-center">
                  {{
                    getCorruptedType(
                        contact.custom_attributes.corrupted_type
                      ),

                  }}
                  <span
                    v-for="contact_id in contact.custom_attributes
                      .contact_corrupted"
                  >
                    <woot-button
                      variant="clear"
                      @click="openContactInfoPanel(contact_id)"
                    >
                      {{ contact_id }}
                    </woot-button>
                  </span>
                </td>

                <td>
                  <div class="flex gap-1">
                    <woot-button
                      class="mr-1"
                      v-tooltip="$t('EDIT_CONTACT.BUTTON_LABEL')"
                      title="$t('EDIT_CONTACT.BUTTON_LABEL')"
                      icon="edit"
                      variant="smooth"
                      size="tiny"
                      @click="toggleEditModal(contact.id)"
                    />
                    <woot-button
                      v-tooltip="$t('CONTACT_PANEL.MERGE_CONTACT')"
                      title="$t('CONTACT_PANEL.MERGE_CONTACT')"
                      icon="merge"
                      variant="smooth"
                      size="tiny"
                      color-scheme="secondary"
                      :disabled="uiFlags.isMerging"
                      @click="toggleMergeModal(contact.id)"
                    />
                    <woot-button
                      v-tooltip.top="$t('LABEL_MGMT.FORM.DELETE')"
                      variant="smooth"
                      color-scheme="alert"
                      size="tiny"
                      icon="dismiss-circle"
                      class-names="grey-btn"
                      :is-loading="loading[contact.id]"
                      @click="openDeletePopup(contact.id)"
                    />
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div v-if="!showInfoPanel" class="hidden w-1/3 xl:block">
          <span v-dompurify-html="$t('CORRUPTED_CONTACTS.LIST.SIDEBAR_TXT')" />
        </div>
      </div>

      <woot-delete-modal
        :show.sync="showDeleteConfirmationPopup"
        :on-close="closeDeletePopup"
        :on-confirm="resolveContact"
        :title="$t('LABEL_MGMT.DELETE.CONFIRM.TITLE')"
        :message="$t('LABEL_MGMT.DELETE.CONFIRM.MESSAGE')"
        :message-value="deleteMessage"
        :confirm-text="deleteConfirmText"
        :reject-text="deleteRejectText"
      />
    </div>
    <contact-info-panel
      v-if="showInfoPanel"
      :contact="selectedContact"
      :on-close="closeContactInfoPanel"
    />
    <edit-contact
      v-if="showEditModal"
      :show="showEditModal"
      :contact="selectedContact"
      @cancel="toggleEditModal"
      @sucess="deleteAtributes"
    />
    <contact-merge-modal
      v-if="showMergeModal"
      :primary-contact="selectedContact"
      :show="showMergeModal"
      @close="toggleMergeModal"
      @sucess="deleteAtributes"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import ContactInfoPanel from '../../contacts/components/ContactInfoPanel.vue';
import EditContact from '../../conversation/contact/EditContact.vue';
import ContactMergeModal from 'dashboard/modules/contact/ContactMergeModal.vue';
import SettingsHeader from '../../settings/SettingsHeader.vue';

export default {
  components: {
    ContactInfoPanel,
    EditContact,
    ContactMergeModal,
    SettingsHeader,
  },
  data() {
    return {
      loading: {},
      showAddPopup: false,
      showEditModal: false,
      showInfoPanel: false,
      showDeleteConfirmationPopup: false,
      showMergeModal: false,
      selectedResponse: {},
      selectedContactId: '',
    };
  },
  computed: {
    ...mapGetters({
      records: 'contacts/getCorruptedContacts',
      uiFlags: 'contacts/getUIFlags',
    }),

    deleteConfirmText() {
      return this.$t('LABEL_MGMT.DELETE.CONFIRM.YES');
    },

    selectedContact() {
      return this.$store.getters['contacts/getContact'](this.selectedContactId);
    },
    deleteRejectText() {
      return this.$t('LABEL_MGMT.DELETE.CONFIRM.NO');
    },
    deleteMessage() {
      return ` ${this.selectedContact?.name}?`;
    },
    backUrl() {
      return `/app/accounts/${this.$route.params.accountId}/integrations-view`;
    },
  },

  watch: {
    selectedContactId() {
      if (this.selectedContactId) {
        // const contact = this.records[this.selectedContactId];
        this.$store.dispatch('contacts/show', {
          id: this.selectedContactId,
        });
      }
    },
  },
  mounted() {
    this.$store.dispatch('contacts/fetchCorruptedContacts');
  },
  methods: {
    getCorruptedType(type) {
      switch (type) {
        case 'identifier':
          return this.$t('CORRUPTED_CONTACTS.LIST.IDENTIFIER');
        case 'phone':
          return this.$t('CORRUPTED_CONTACTS.LIST.PHONE');
        case 'both':
          return this.$t('CORRUPTED_CONTACTS.LIST.BOTH');
        case 'conflict':
          return this.$t('CORRUPTED_CONTACTS.LIST.CONFLICT');
      }
    },

    openAddPopup() {
      this.showAddPopup = true;
    },

    toggleMergeModal(contactId) {
      this.selectedContactId = contactId;
      this.showMergeModal = !this.showMergeModal;
    },

    openContactInfoPanel(contactId) {
      this.showInfoPanel = true;
      this.selectedContactId = contactId;
    },

    closeContactInfoPanel() {
      this.showInfoPanel = false;
      this.selectedContactId = '';
    },

    toggleEditModal(contactId) {
      this.showEditModal = !this.showEditModal;
      this.selectedContactId = contactId;
    },

    handleContact(contact) {
      const dateToTimestamp = date => {
        const timestampDate = new Date(date);
        const timestamp = Math.floor(timestampDate.getTime() / 1000);
        return timestamp;
      };
      const newContact = {
        ...contact,
        created_at: dateToTimestamp(contact.created_at),
        updated_at: dateToTimestamp(contact.updated_at),
      };
      return newContact;
    },

    hideAddPopup() {
      this.showAddPopup = false;
    },

    openEditPopup(response) {
      this.showEditModal = true;
      this.selectedResponse = response;
    },
    hideEditPopup() {
      this.showEditModal = false;
    },

    openDeletePopup(contactId) {
      this.showDeleteConfirmationPopup = true;
      this.selectedContactId = contactId;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },

    confirmDeletion() {
      this.loading[this.selectedResponse.id] = true;
      this.closeDeletePopup();
      this.deleteLabel(this.selectedResponse.id);
    },

    deleteAtributes(contactId) {
      const corrupted_keys = [
        'contact_corrupted',
        'corrupted_type',
        'corrupted_value',
      ];

      this.$store.dispatch('contacts/deleteCustomAttributes', {
        id: contactId,
        customAttributes: corrupted_keys,
      });
    },

    resolveContact() {
      this.$store.dispatch('contacts/deactivateContact', {
        id: this.selectedContactId,
      });
      this.closeDeletePopup();
    },
  },
};
</script>

<style scoped lang="scss">
@import '~dashboard/assets/scss/variables';

.label-color--container {
  @apply flex items-center;
}

.label-color--display {
  @apply rounded h-4 w-4 mr-1 rtl:mr-0 rtl:ml-1 border border-solid border-slate-50 dark:border-slate-700;
}

.label-title {
  span {
    @apply w-60 inline-block;
  }
}
</style>
