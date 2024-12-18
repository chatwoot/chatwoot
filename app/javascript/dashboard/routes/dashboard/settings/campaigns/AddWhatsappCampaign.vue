<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import campaignMixin from 'shared/mixins/campaignMixin';
import WootDateTimePicker from 'dashboard/components/ui/DateTimePicker.vue';
import ContactSelector from './ContactSelector.vue';
import ContactsAPI from 'dashboard/api/contacts';

export default {
  components: {
    WootDateTimePicker,
    ContactSelector,
  },
  mixins: [campaignMixin],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      currentStep: 1, // Track the current step
      title: '',
      selectedInbox: null,
      selectedTemplate: null,
      scheduledAt: null,
      selectedContacts: [], // Array to store selected contacts
      searchQuery: '', // For contact search
      contactList: [], // List of available contacts
      isLoadingContacts: false,
      currentPage: 1,
      totalPages: 1,
      sortAttribute: 'name',
    };
  },
  validations() {
    const step1Validations = {
      title: { required },
      selectedInbox: { required },
      selectedTemplate: { required },
    };

    const step2Validations = {
      selectedContacts: {
        required,
        minLength: value => value.length > 0,
      },
    };

    return this.currentStep === 1 ? step1Validations : step2Validations;
  },
  computed: {
    ...mapGetters({
      uiFlags: 'campaigns/getUIFlags',
      // contactsList: 'contacts/getContacts', // Add a new getter for contacts
    }),
    templateList() {
      return this.selectedInbox
        ? this.$store.getters['inboxes/getWhatsAppTemplates'](
            this.selectedInbox
          )
        : [];
    },
    inboxes() {
      const allInboxes = this.$store.getters['inboxes/getInboxes'];
      return allInboxes.filter(inbox => inbox.provider === 'whatsapp_cloud');
    },
    isStep1Valid() {
      return (
        !this.v$.title.$error &&
        !this.v$.selectedInbox.$error &&
        !this.v$.selectedTemplate.$error
      );
    },
  },
  methods: {
    onClose() {
      this.$emit('onClose');
    },
    onChange(value) {
      this.scheduledAt = value;
    },
    async fetchContacts(page = 1, search = '') {
      try {
        this.isLoadingContacts = true;

        if (search) {
          // Use search API if there's a search query
          const { data } = await ContactsAPI.search(
            search,
            page,
            this.sortAttribute
          );
          this.handleContactsResponse(data);
        } else {
          // Use regular fetch if no search
          const { data } = await ContactsAPI.get(page, this.sortAttribute);
          this.handleContactsResponse(data);
        }
      } catch (error) {
        useAlert(this.$t('CAMPAIGN.ADD.API.CONTACTS_ERROR'));
      } finally {
        this.isLoadingContacts = false;
      }
    },

    handleContactsResponse(data) {
      // Assuming the API returns an object with contacts and meta information
      const { payload = [], meta = {} } = data;
      const filteredContacts = payload.filter(contact => contact.phone_number);

      // If it's the first page, replace the list
      if (this.currentPage === 1) {
        this.contactList = filteredContacts;
      } else {
        // Otherwise append to the existing list
        this.contactList = [...this.contactList, ...filteredContacts];
      }

      // Update pagination info
      this.totalPages = meta.total_pages || 1;
    },
    async loadMoreContacts() {
      if (this.currentPage < this.totalPages && !this.isLoadingContacts) {
        this.currentPage += 1;
        await this.fetchContacts(this.currentPage, this.searchQuery);
      }
    },
    async goToNext() {
      this.v$.$touch();
      if (this.isStep1Valid) {
        this.currentStep = 2;
        this.contactList = [];
        this.currentPage = 1;
        this.searchQuery = '';
        await this.fetchContacts();
      }
    },
    goBack() {
      this.currentStep = 1;
    },
    onContactsSelected(contacts) {
      this.selectedContacts = contacts;
    },
    async createCampaign() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      try {
        // Construct the campaign details as per the backend's expected format
        const campaignDetails = {
          campaign: {
            // Wrap the data in a 'campaign' object to match strong parameters
            title: this.title,
            inbox_id: this.selectedInbox,
            template_id: this.selectedTemplate?.id || null,
            scheduled_at: this.scheduledAt,
            contacts: this.selectedContacts.map(contact => contact.id),
            // Add optional fields with default values if needed
            enabled: true, // Enable campaign by default
            trigger_only_during_business_hours: false, // Default value
            description: this.description || '', // Optional description
          },
        };
        await this.$store.dispatch('campaigns/create', campaignDetails);

        useAlert(this.$t('CAMPAIGN.ADD.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        // Enhanced error handling
        let errorMessage = this.$t('CAMPAIGN.ADD.API.ERROR_MESSAGE');

        if (error.response) {
          // If we have a specific error message from the backend, use it
          errorMessage =
            error.response.data?.error ||
            error.response.data?.message ||
            errorMessage;
        }

        useAlert(errorMessage);
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header
      :header-title="$t('CAMPAIGN.ADD.TITLE')"
      :header-content="$t('CAMPAIGN.ADD.DESC')"
    />

    <!-- Step 1: Campaign Details -->
    <div v-if="currentStep === 1" class="campaign-details-form">
      <form class="flex flex-col w-full">
        <div class="w-full">
          <woot-input
            v-model="title"
            :label="$t('CAMPAIGN.ADD.FORM.TITLE.LABEL')"
            type="text"
            :class="{ error: v$.title.$error }"
            :error="v$.title.$error ? $t('CAMPAIGN.ADD.FORM.TITLE.ERROR') : ''"
            :placeholder="$t('CAMPAIGN.ADD.FORM.TITLE.PLACEHOLDER')"
            @blur="v$.title.$touch"
          />

          <label :class="{ error: v$.selectedInbox.$error }">
            {{ $t('CAMPAIGN.ADD.FORM.INBOX.LABEL') }}
            <select v-model="selectedInbox">
              <option v-for="item in inboxes" :key="item.name" :value="item.id">
                {{ item.name }}
              </option>
            </select>
            <span v-if="v$.selectedInbox.$error" class="message">
              {{ $t('CAMPAIGN.ADD.FORM.INBOX.ERROR') }}
            </span>
          </label>

          <label :class="{ error: v$.selectedTemplate.$error }">
            {{ $t('CAMPAIGN.ADD.FORM.SELECT_TEMPLATE.LABEL') }}
            <select v-model="selectedTemplate">
              <option
                v-for="template in templateList"
                :key="template.id"
                :value="template"
              >
                {{ template.name }}
              </option>
            </select>
            <span v-if="v$.selectedTemplate.$error" class="message">
              {{ $t('CAMPAIGN.ADD.FORM.SELECT_TEMPLATE.ERROR') }}
            </span>
          </label>

          <label>
            {{ $t('CAMPAIGN.ADD.FORM.SCHEDULED_AT.LABEL') }}
            <WootDateTimePicker
              :value="scheduledAt"
              :confirm-text="$t('CAMPAIGN.ADD.FORM.SCHEDULED_AT.CONFIRM')"
              :placeholder="$t('CAMPAIGN.ADD.FORM.SCHEDULED_AT.PLACEHOLDER')"
              @change="onChange"
            />
          </label>
        </div>

        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
          <woot-button
            type="button"
            :disabled="!isStep1Valid"
            @click="goToNext"
          >
            {{ $t('CAMPAIGN.ADD.NEXT_BUTTON_TEXT') }}
          </woot-button>
          <woot-button type="button" variant="clear" @click.prevent="onClose">
            {{ $t('CAMPAIGN.ADD.CANCEL_BUTTON_TEXT') }}
          </woot-button>
        </div>
      </form>
    </div>

    <!-- Step 2: Contact Selection -->
    <div v-else class="contact-selection">
      <ContactSelector
        :contacts="contactList"
        :selected-contacts="selectedContacts"
        @contactsSelected="onContactsSelected"
      />

      <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
        <woot-button
          :is-loading="uiFlags.isCreating"
          :disabled="selectedContacts.length === 0"
          @click="createCampaign"
        >
          {{ $t('CAMPAIGN.ADD.CREATE_BUTTON_TEXT') }}
        </woot-button>
        <woot-button type="button" @click="goBack">
          {{ $t('CAMPAIGN.ADD.BACK_BUTTON_TEXT') }}
        </woot-button>
        <woot-button type="button" variant="clear" @click.prevent="onClose">
          {{ $t('CAMPAIGN.ADD.CANCEL_BUTTON_TEXT') }}
        </woot-button>
      </div>
    </div>
  </div>
</template>
