<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import campaignMixin from 'shared/mixins/campaignMixin';
import WootDateTimePicker from 'dashboard/components/ui/DateTimePicker.vue';
import ContactSelector from './ContactSelector.vue';
import TemplatePreview from './TemplatePreview.vue';
import ContactsAPI from 'dashboard/api/contacts';

export default {
  components: {
    WootDateTimePicker,
    ContactSelector,
    TemplatePreview,
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
      total_count: 0,
      sortAttribute: 'name',
      isTemplateValid: true,
      previewPosition: {
        right: 0,
        top: 0,
      },
    };
  },
  validations() {
    const step1Validations = {
      title: { required },
      selectedInbox: { required },
      selectedTemplate: { required },
      isTemplateValid: { required },
    };

    const step2Validations = {
      selectedContacts: {
        required,
        minLength: value => (value || []).length > 0,
      },
    };

    return this.currentStep === 1 ? step1Validations : step2Validations;
  },
  computed: {
    ...mapGetters({
      uiFlags: 'campaigns/getUIFlags',
    }),
    templateList() {
      const templates = this.selectedInbox
        ? this.$store.getters['inboxes/getWhatsAppTemplates'](
            this.selectedInbox
          )
        : [];
      return templates;
    },
    accountId() {
      return this.$route.params.accountId;
    },
    inboxes() {
      const allInboxes = this.$store.getters['inboxes/getInboxes'];

      return allInboxes.filter(inbox => inbox.provider === 'whatsapp_cloud');
    },
    isStep1Valid() {
      return (
        !this.v$.title.$error &&
        !this.v$.selectedInbox.$error &&
        !this.v$.selectedTemplate.$error &&
        this.isTemplateValid
      );
    },
  },
  methods: {
    handleFiltersCleared() {
      this.currentPage = 1;
      this.totalPages = 1;
      this.fetchContacts(1);
    },
    onFilteredContacts(filteredContacts) {
      this.contactList = filteredContacts;
    },
    async fetchAllContactIds(isFiltered = false, filteredContacts = []) {
      try {
        this.isSelectingAll = true;
        const contactIds = [];
        if (isFiltered) {
          this.total_count = filteredContacts.length;
          contactIds.push(...filteredContacts.map(contact => contact.id));
          this.selectedContacts = contactIds;
        } else {
          const { data } = await ContactsAPI.getAllIds();
          this.total_count = data.total_count;
          this.selectedContacts = data.contact_ids;
          contactIds.push(...data.contact_ids);
        }

        if (this.$refs.contactSelector) {
          this.$refs.contactSelector.updateSelectedContacts(contactIds);
        }

        useAlert(this.$t('CAMPAIGN.ADD.SELECT_ALL.SUCCESS'));
      } catch (error) {
        useAlert(this.$t('CAMPAIGN.ADD.SELECT_ALL.ERROR'));
      } finally {
        this.isSelectingAll = false;
      }
    },
    handleTemplateValidation(isValid) {
      this.isTemplateValid = isValid;
    },
    handleInboxSelection() {
      const baseUrl = window.location.origin;

      if (this.selectedInbox === 'create_new') {
        this.selectedInbox = '';

        window.location.href = `${baseUrl}/app/accounts/${this.accountId}/settings/inboxes/new/whatsapp`;
      }
    },

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
          this.contactList = [];
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

      const totalpages = Math.ceil(meta.count / 30);
      this.totalPages = totalpages;
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
        const contactIds =
          this.selectedContacts.length > 0 &&
          typeof this.selectedContacts[0] === 'object'
            ? this.selectedContacts.map(contact => contact.id)
            : this.selectedContacts;

        const campaignDetails = {
          campaign: {
            title: this.title,
            inbox_id: this.selectedInbox,
            template_id: this.selectedTemplate?.id || null,
            scheduled_at: this.scheduledAt,
            contacts: contactIds,

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
    calculatePreviewPosition() {
      const campaignForm = this.$el?.querySelector('.campaign-details-form');
      if (campaignForm) {
        const rect = campaignForm.getBoundingClientRect();
        this.previewPosition = {
          right: window.innerWidth - rect.right - 320,
          top: rect.top - 112,
        };
      }
    },
  },
  mounted() {
    this.calculatePreviewPosition();
    window.addEventListener('resize', this.calculatePreviewPosition);
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.calculatePreviewPosition);
  },
};
</script>

<template>
  <div class="h-auto">
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
            <select v-model="selectedInbox" @change="handleInboxSelection">
              <option value="create_new" class="create-inbox-option">
                {{
                  $t('CAMPAIGN.ADD.FORM.CREATE_INBOX.LABEL', {
                    default: 'Create an Inbox',
                  })
                }}
              </option>
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
            <a
              href="https://developers.facebook.com/docs/whatsapp/business-management-api/message-templates/#create-and-manage-templates"
              target="_blank"
              rel="noopener noreferrer"
              class="text-xs text-[#369EFF] hover:text-[#1b67ae]"
            >
              {{ $t('CAMPAIGN.ADD.FORM.HELP.LABEL', { default: 'Help' }) }}
            </a>
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

      <!-- Template Preview for Step 1 -->
      <TemplatePreview
        v-if="currentStep === 1"
        :selectedTemplate="selectedTemplate"
        :preview-position="previewPosition"
        @template-validation="handleTemplateValidation"
      />
    </div>

    <!-- Step 2: Contact Selection -->
    <div v-else class="contact-selection">
      <ContactSelector
        ref="contactSelector"
        :contacts="contactList"
        :selected-contacts="selectedContacts"
        :is-loading="isLoadingContacts"
        :has-more="currentPage < totalPages"
        @contactsSelected="onContactsSelected"
        @loadMore="loadMoreContacts"
        @selectAllContacts="fetchAllContactIds"
        @filterContacts="onFilteredContacts"
        @filtersCleared="handleFiltersCleared"
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
        <woot-button
          type="button"
          variant="clear"
          class-names="cancel"
          @click.prevent="onClose"
        >
          {{ $t('CAMPAIGN.ADD.CANCEL_BUTTON_TEXT') }}
        </woot-button>
      </div>
    </div>
  </div>
</template>
<style scoped>
.create-inbox-option {
  background-color: #f0f9ff; /* Light blue background */
  color: #369eff; /* Same blue as your original link */
  font-weight: 500;
}

.cancel {
  margin-right: 10px;
}

/* For Firefox which doesn't support styling option elements directly */
select option[value='create_new'] {
  background-color: #f0f9ff;
  color: #369eff;
  font-weight: 500;
}

.flex-1 {
  flex: 1;
}

.pr-4 {
  padding-right: 1rem;
}

/* Add responsive styles for smaller screens */
@media (max-width: 1024px) {
  .flex-row {
    flex-direction: column;
  }

  .pr-4 {
    padding-right: 0;
    padding-bottom: 1rem;
  }
}
</style>
