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
  props: {
    selectedCampaign: {
      type: Object,
      default: () => ({}),
    },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      currentStep: 1,
      title: '',
      selectedInbox: null,
      selectedTemplate: null,
      scheduledAt: null,
      selectedContacts: [],
      searchQuery: '',
      contactList: [],
      isLoadingContacts: false,
      currentPage: 1,
      totalPages: 1,
      sortAttribute: 'name',
      initialContactIds: [], // To track originally selected contacts
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
      //   contactsList: 'contacts/getContacts',
    }),
    templateList() {
      return this.selectedInbox
        ? this.$store.getters['inboxes/getWhatsAppTemplates'](
            this.selectedInbox
          )
        : [];
    },
    inboxes() {
      return this.$store.getters['inboxes/getInboxes'];
    },
    isStep1Valid() {
      return (
        !this.v$.title.$error &&
        !this.v$.selectedInbox.$error &&
        !this.v$.selectedTemplate.$error
      );
    },
    hasContactChanges() {
      // Check if selected contacts are different from initial contacts
      const currentContactIds = this.selectedContacts.map(c => c.id);
      return (
        currentContactIds.length !== this.initialContactIds.length ||
        !currentContactIds.every(id => this.initialContactIds.includes(id))
      );
    },
  },
  mounted() {
    this.setInitialValues();
  },
  methods: {
    setInitialValues() {
      const campaign = this.selectedCampaign;
      this.title = campaign.title || '';
      this.selectedInbox = campaign.inbox_id || null;
      this.selectedTemplate = campaign.template
        ? { id: campaign.template.id, name: campaign.template.name }
        : null;
      this.scheduledAt = campaign.scheduled_at
        ? new Date(campaign.scheduled_at)
        : null;

      // Set initial contacts
      this.initialContactIds = campaign.contacts?.map(c => c.id) || [];
      this.selectedContacts = campaign.contacts || [];
    },
    onClose() {
      this.$emit('onClose');
    },
    onChange(value) {
      this.scheduledAt = value instanceof Date ? value : new Date(value);
    },
    async fetchContacts(page = 1, search = '') {
      try {
        this.isLoadingContacts = true;

        if (search) {
          const { data } = await ContactsAPI.search(
            search,
            page,
            this.sortAttribute
          );
          this.handleContactsResponse(data);
        } else {
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
      const { payload = [], meta = {} } = data;
      const filteredContacts = payload.filter(contact => contact.phone_number);

      if (this.currentPage === 1) {
        this.contactList = filteredContacts;
      } else {
        this.contactList = [...this.contactList, ...filteredContacts];
      }

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
    async updateCampaign() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      try {
        const updatePayload = {
          id: this.selectedCampaign.id,
          title: this.title,
          inbox_id: this.selectedInbox,
          template_id: this.selectedTemplate?.id || null,
          scheduled_at: this.scheduledAt
            ? this.scheduledAt.toISOString()
            : null,
          contacts: this.selectedContacts.map(contact => contact.id),
          enabled: this.selectedCampaign.enabled ?? true,
        };

        // Await the update and capture the response
        await this.$store.dispatch('campaigns/update', updatePayload);

        useAlert(this.$t('CAMPAIGN.EDIT.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        let errorMessage = this.$t('CAMPAIGN.EDIT.API.ERROR_MESSAGE');

        // More detailed error logging

        if (error.response) {
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
      :header-title="$t('CAMPAIGN.EDIT.TITLE')"
      :header-content="$t('CAMPAIGN.EDIT.DESC')"
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
          :is-loading="uiFlags.isUpdating"
          :disabled="!hasContactChanges"
          @click="updateCampaign"
        >
          {{ $t('CAMPAIGN.EDIT.UPDATE_BUTTON_TEXT') }}
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
