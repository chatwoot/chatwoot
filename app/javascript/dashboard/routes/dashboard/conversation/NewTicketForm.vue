<template>
  <div>
    {{ newTicket.phoneNumber }}
    {{ newTicket.phoneCode }}
    <div class="flex flex-row">
      <div class="w-full">
        <label>
          {{ $t('NEW_CONVERSATION.FORM.INBOX.LABEL') }}
        </label>
        <multiselect
            v-model="newTicket.inbox"
            track-by="id"
            label="name"
            :placeholder="$t('NEW_CONVERSATION.FORM.INBOX.PLACEHOLDER')"
            :max-height="135"
            :close-on-select="true"
            :options="[...emailInboxes]"
          >
          <template slot="singleLabel" slot-scope="{ option }">
            <inbox-dropdown-item
              v-if="option.name"
              :name="option.name"
              :inbox-identifier="computedInboxSource(option)"
              :channel-type="option.channel_type"
            />
            <span v-else>
              {{ $t('NEW_CONVERSATION.FORM.INBOX.PLACEHOLDER') }}
            </span>
          </template>
          <template slot="option" slot-scope="{ option }">
            <inbox-dropdown-item
              :name="option.name"
              :inbox-identifier="computedInboxSource(option)"
              :channel-type="option.channel_type"
            />
          </template>
        </multiselect>
        <span v-if="$v.newTicket.inbox.$error" class="text-xs message text-red-400">
          Inbox is required
        </span>
      </div>

      <div class="w-full">
        <label class="mb-2 ml-2 email-label">
          Email Address
          <input type="email" v-model="newTicket.email" @input="$v.newTicket.email.$touch"/>
          <ul v-if="contactSuggestions.length" class="suggestions-list">
            <li 
              v-for="(suggestion, index) in contactSuggestions" 
              :key="index" 
              @click="selectSuggestion(suggestion)"
            >
              {{ suggestion.email }}
              <div><small>{{ suggestion.name }}</small></div>
              <div><small>{{ suggestion.phone_number }}</small></div>
            </li>
          </ul>
          <span v-if="$v.newTicket.email.$error" class="text-xs message text-red-400">
            {{ $t('CONTACT_FORM.FORM.EMAIL_ADDRESS.ERROR') }}
          </span>
        </label>
      </div>
    </div>
    
    <div class="flex flex-row">
      <div class="w-full">
        <label class="mb-2">
          Contact Name
          <input type="text" v-model="newTicket.name" @input="$v.newTicket.name.$touch"/>
          <span v-if="$v.newTicket.name.$error" class="text-xs message text-red-400">
            Name is required
          </span>
        </label>
      </div>

      <div class="w-full multiselect-wrap--small ml-2">
        <label>{{ $t('CONVERSATION_SIDEBAR.TEAM_LABEL') }}</label>
        <multiselect-dropdown
          class="team-multiselect"
          :options="teamsList"
          :selected-item="assignedTeam"
          :multiselector-title="$t('AGENT_MGMT.MULTI_SELECTOR.TITLE.TEAM')"
          :multiselector-placeholder="$t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')"
          :no-search-result="
            $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.NO_RESULTS.TEAM')
          "
          :input-placeholder="
            $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.INPUT')
          "
          @click="onClickAssignTeam"
        />
      </div>
    </div>
    
    <div class="w-full">
      <label
        :class="{
          error: isPhoneNumberNotValid,
        }"
      >
        {{ $t('CONTACT_FORM.FORM.PHONE_NUMBER.LABEL') }}
        <woot-phone-input
          v-model="newTicket.phoneNumber"
          :value="newTicket.phoneNumber"
          :error="isPhoneNumberNotValid"
          :placeholder="$t('CONTACT_FORM.FORM.PHONE_NUMBER.PLACEHOLDER')"
          @input="onPhoneNumberInputChange"
          @blur="$v.newTicket.phoneNumber.$touch"
          @setCode="setPhoneCode"
        />
        <span v-if="isPhoneNumberNotValid" class="message">
          {{ phoneNumberError }}
        </span>
      </label>
    </div>

    <div class="w-full">
      <label>
        Conversation Labels
        <label-selector
          :all-labels="allLabels"
          :saved-labels="assignedLabels"
          @add="addLabel"
          @remove="removeLabel"
        />
      </label>
    </div>

    <div class="flex flex-row">
      <div class="w-full">
        <label class="mb-2">
          Stakeholder type
          <select v-model="newTicket.contact_kind">
            <option v-for="contactKind in contactKinds" :key="contactKind.id" :value="contactKind.id">{{ contactKind.name }}</option>
          </select>
        </label>
      </div>
      
      <div class="w-full">
        <label class="mb-2 ml-2">
          Issue type
          <select v-model="newTicket.issue_type">
            <option value="Feedback">Feedback</option>
            <option value="Question">Question</option>
            <option value="2nd Line Support">2nd Line Support</option>
          </select>
        </label>
      </div>
    </div>

    <div class="w-full">
      <label class="mb-2">
        Subject
        <input type="text" v-model="newTicket.subject" @input="$v.newTicket.subject.$touch"/>
        <span v-if="$v.newTicket.subject.$error" class="text-xs message text-red-400">
          Subject is required
        </span>
      </label>
    </div>

    <div class="newticket-box" :class="{ 'is-private': privateNote }">
      <div class="newticket-box__top bg-white dark:bg-slate-800">
        <div class="button-group">
          <woot-button
            color-scheme="secondary"
            variant="clear"
            class="button--reply"
            :class="messageButtonClass"
            @click="handleMessageClick"
          >
          Message
          </woot-button>

          <woot-button
            class="button--note"
            variant="clear"
            color-scheme="warning"
            :class="noteButtonClass"
            @click="handleNoteClick"
          >
            {{ $t('CONVERSATION.REPLYBOX.PRIVATE_NOTE') }}
          </woot-button>
        </div>
      </div>
      
      <div class="w-full pb-2">
        <reply-email-head
          class="px-2"
          v-if="!privateNote"
          :cc-emails.sync="ccEmails"
          :bcc-emails.sync="bccEmails"
        />
        <div class="p-2 mt-2">
          <woot-message-editor
            v-model="newTicket.note"
            class="message-editor [&>div]:px-1"
            :is-private="privateNote"
            :enable-variables="true"  
            :enable-canned-responses="false"
            :placeholder="messagePlaceHolder"
            @blur="$v.newTicket.note.$touch"
            ref="messageEditor"
          />
        </div>

        <span v-if="$v.newTicket.note.$error" class="text-xs text-red-400 message p-2">
          {{ privateNote ? 'Note' : 'Message'}} is required
        </span>
      </div>
    </div>

    <div class="left-wrap">
      <!-- file upload here -->
    </div>
    <div class="float-right mt-5">
      <woot-button
        size="small"
        @click="createWithResponse"
      >
        Create with Response
      </woot-button>
      <woot-button
        size="small"
        color-scheme="success"
        @click="createAndSolve"
      >
        Create and Solve
      </woot-button>
    </div>
  </div>
</template>

<script>
  import FileUpload from 'vue-upload-component';
  import * as ActiveStorage from 'activestorage';
  import { mapGetters } from 'vuex';
  import LabelSelector from 'dashboard/components/widgets/LabelSelector.vue';
  import { getInboxSource } from 'dashboard/helper/inbox';
  import InboxDropdownItem from 'dashboard/components/widgets/InboxDropdownItem.vue';
  import { isPhoneNumberValid } from 'shared/helpers/Validators';
  import parsePhoneNumber from 'libphonenumber-js';
  import { required, email } from 'vuelidate/lib/validators';
  import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
  import alertMixin from 'shared/mixins/alertMixin';
  import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
  import ReplyEmailHead from 'dashboard/components/widgets/conversation/ReplyEmailHead.vue';
  import {
    ALLOWED_FILE_TYPES,
  } from 'shared/constants/messages';

  export default {
    mixins: [alertMixin],
    components: {
      LabelSelector,
      InboxDropdownItem,
      WootMessageEditor,
      MultiselectDropdown,
      ReplyEmailHead,
      FileUpload,
    },
    props: {
      headerTitle: {
        type: String,
        default: 'New Ticket'
      }
    },
    data() {
      return {
        assignedLabels: [],
        assignedTeam: null,
        privateNote: true,
        bccEmails: '',
        ccEmails: '',
        debounceTimeout: null,
        contactSuggestions: [],
        contactKinds: [
        {
          id: 0,
          name: "None",
        },
        {
          id: 1,
          name: "Tolk",
        },
        {
          id: 2,
          name: "Kund",
        },
        {
          id: 3,
          name: "Översättare",
        },
        {
          id: 4,
          name: "Anställd",
        },
        {
          id: 5,
          name: "Övrigt",
        },
        ]
      };
    },
    computed: {
      ...mapGetters({
        newTicket: 'getNewTicket',
        allLabels: 'labels/getLabels',
        inboxes: 'inboxes/getInboxes',
        teamsList: 'teams/getTeams',
        currentAccountId: 'getCurrentAccountId'
      }),

      emailInboxes() {
        return this.inboxes.filter(inbox => inbox.channel_type === 'Channel::Email');
      },
      parsePhoneNumber() {
        return parsePhoneNumber(this.newTicket.phoneNumber);
      },
      isPhoneNumberNotValid() {
        if (!!this.newTicket.phoneNumber) {
          return (
            !isPhoneNumberValid(this.newTicket.phoneNumber, this.newTicket.phoneCode) ||
            (this.newTicket.phoneNumber !== '' ? this.newTicket.phoneCode === '' : false)
          );
        }
        return false;
      },
      phoneNumberError() {
        if (this.newTicket.phoneCode === '') {
          return this.$t('CONTACT_FORM.FORM.PHONE_NUMBER.DIAL_CODE_ERROR');
        }
        if (!isPhoneNumberValid(this.newTicket.phoneNumber, this.newTicket.phoneCode)) {
          return this.$t('CONTACT_FORM.FORM.PHONE_NUMBER.ERROR');
        }
        return '';
      },
      phoneNumberWithCode() {
        return this.newTicket.phoneNumber ? `${this.newTicket.phoneCode} ${this.newTicket.phoneNumber}` : '';
      },
      contactType(){
        return this.contactKinds.find(kind => kind.id === this.newTicket.contact_kind)?.name;
      },

      issueType(){
        return this.newTicket.issue_type;
      },

      customAttributes(){
        return {
          issue_type: this.newTicket.issue_type,
          contact_type: this.contactType,
          response_needed: this.newTicket.response_needed,
        }
      },
      noteButtonClass() {
        return {
          'is-active': this.privateNote,
        };
      },
      messageButtonClass() {
        return {
          'is-active': !this.privateNote,
        };
      },

      messagePlaceHolder() {
        if (this.privateNote) {
          return 'Add a note';
        } else {
          return 'Add a message';
        }
      },

      allowedFileTypes() {
        return ALLOWED_FILE_TYPES;
      },

      newTicketData(){
        return {
          'contact_kind': this.newTicket.contact_kind,
          'email': this.newTicket.email, 
          'inbox_id': this.newTicket.inbox?.id,
          'team_id': this.newTicket.team_id,
          'issue_type': this.newTicket.issue_type,
          'name': this.newTicket.name,
          'note': this.newTicket.note,
          'phone': this.newTicket.phoneNumber,
          'phoneCode': this.newTicket.phoneCode,
          'response_needed': this.newTicket.response_needed,
          'labels': this.newTicket.labels,
          'custom_attributes': this.customAttributes,
          'subject': this.newTicket.subject,
          'bcc_emails': this.bccEmails,
          'cc_emails': this.ccEmails,
          'private': this.privateNote,
          'status': this.newTicket.status,
        }
      }
    },
    mounted(){
      ActiveStorage.start();
    },
    methods: {
      onConversationLoad() {
        this.fetchConversationIfUnavailable();
      },

      addLabel(value) {
        this.assignedLabels.push(value);
      },

      removeLabel(value) {
        this.assignedLabels = this.assignedLabels.filter(label => label.title !== value);
      },

      computedInboxSource(inbox) {
        if (!inbox.channel_type) return '';
        const classByType = getInboxSource(
          inbox.channel_type,
          inbox.phone_number,
          inbox
        );
        return classByType;
      },

      onPhoneNumberInputChange(value, code) {
        this.newTicket.phoneCode = code;
        this.phoneNumber = value;
      },

      setPhoneCode(code) {
        if (this.newTicket && !!this.newTicket.phoneNumber && this.parsePhoneNumber) {
          const dialCode = this.parsePhoneNumber.countryCallingCode;
          if (dialCode === code) {
            return;
          }
          this.newTicket.phoneCode = `+${dialCode}`;
          const newPhoneNumber = this.newTicket.phoneNumber.replace(
            `+${dialCode}`,
            `${code}`
          );
          this.newTicket.phoneNumber = newPhoneNumber;
        } else {
          this.newTicket.phoneCode = code;
        }
      },
      onClickAssignTeam(selectedItemTeam) {
        if (this.assignedTeam && this.assignedTeam.id === selectedItemTeam.id) {
          this.assignedTeam = null;
        } else {
          this.assignedTeam = selectedItemTeam;
        }
      },

      createWithResponse(){
        this.newTicket.status = 'open';
        this.newTicket.response_needed = true;
        this.submitForm();
      },

      createAndSolve(){
        this.newTicket.status = 'resolved'
        this.submitForm();
      },

      submitForm(){
        this.$v.$touch();

        if (this.$v.$invalid) {
          this.$emit('enable-submit')
          this.showAlert('There are validation errors')
        } else {
          this.$emit('disable-submit')
          this.$store.dispatch('saveTicket', this.newTicketData).then((result) => {
            this.showAlert('Ticket created!')
            this.clearTicket()
            this.navigateToTicket(result.data.id)
            this.$emit('enable-submit')
          }).catch((e) => {
            const error_message = e.response?.data?.error
            this.showAlert(error_message, 'error')
            this.$emit('enable-submit')
          })
        }
      },

      getValidationErrors() {
        const errors = {};
        return errors;
      },
      
      checkEmailDebounced(newEmail){
        clearTimeout(this.debounceTimeout);

        if (newEmail === '') {
          this.contactSuggestions = [];
          this.newTicket.name = '';
          this.newTicket.phoneNumber = '';
          this.newTicket.phoneCode = '';
          return;
        }

        this.debounceTimeout = setTimeout(() => {
          this.checkEmailInBackend(newEmail);
        }, 300);
      },

      selectSuggestion(suggestion){
        this.newTicket.email = suggestion.email;
        this.newTicket.name = suggestion.name;
        this.newTicket.phoneNumber = suggestion.phone_number || "";

        if (!!this.newTicket.phoneNumber && !!this.parsePhoneNumber) {
          const dialCode = this.parsePhoneNumber.countryCallingCode;
          this.newTicket.phoneCode = `+${dialCode}`;
        }

        this.contactSuggestions = [];
      },

      async checkEmailInBackend(newEmail){
        try {
          const response = await this.$store.dispatch('contacts/suggest', newEmail)
          this.contactSuggestions = response;
        } catch (error) {
          this.contactSuggestions = [];
        }
      },

      clearTicket(){
        this.$store.dispatch('clearTicket')
        this.$emit('close-panel')
      },
      navigateToTicket(id){
        this.$router.push({
          name: 'inbox_conversation',
          params: { conversation_id: id },
        });
      },
      clearContactTypeLabels(){
        this.assignedLabels = this.assignedLabels.filter((label) => !label.title.includes('_contact'))
      },

      clearIssueTypeLabels(){
        this.assignedLabels = this.assignedLabels.filter((label) => !['feedback', 'question', '2nd-line-support'].includes(label.title))
      },

      handleMessageClick() {
        this.privateNote = false;
      },

      handleNoteClick() {
        this.privateNote = true;
      },
    },
    validations: {
      newTicket:{
        inbox: {
          required,
        },
        email: {
          email,
          required
        },
        name: {
          required
        },
        subject: {
          required
        },
        note: {
          required
        },
        phoneNumber: {},
      },
      bcc_emails: {
        email
      },
      cc_emails: {
        email
      }
    },
    watch: {
      assignedLabels() {
        this.newTicket.labels = this.assignedLabels.map((label) => label.title)
      },
      assignedTeam() {
        this.newTicket.team_id = this.assignedTeam ? this.assignedTeam.id : null
      },
      contactType(value){
        const label_title = value.toLowerCase() + '_contact'
        const label = this.allLabels.find((label) => label.title === label_title)
        
        this.clearContactTypeLabels()
        if(label){
          this.assignedLabels.push(label)
        }
      },

      issueType(){
        let label_title = '';
        switch(this.issueType){
          case 'Feedback':
            this.clearIssueTypeLabels();
            label_title = 'feedback';
            break;
          case 'Question':
            this.clearIssueTypeLabels();
            label_title = 'question';
            break;
          case '2nd Line Support':
            this.clearIssueTypeLabels();
            label_title = '2nd-line-support';
            break;
        }

        if (label_title){
          const label = this.allLabels.find((label) => label.title === label_title)
          if(label){
            this.assignedLabels.push(label)
          }
        }
      },

      privateNote(){
        this.$refs.messageEditor.reloadState(this.newTicket.note)
      },
      'newTicket.email': function(newEmail) {
        this.checkEmailDebounced(newEmail);
      }
    }
  };
</script>
<style lang="scss" scoped>
  label input[type="email"], label input[type="text"] {
    margin-bottom: 0px !important;
  }
  .multiselect {
    margin-bottom: 0px !important;
  }

  .button-group {
    @apply flex border-0 p-0 m-0;

    .button {
      @apply text-sm font-medium py-2.5 px-4 m-0 relative z-10;
      &.is-active {
        @apply bg-white dark:bg-slate-900;
      }
    }
    .button--reply {
      @apply border-r rounded-none border-b-0 border-l-0 border-t-0 border-slate-50 dark:border-slate-700;
      &:hover,
      &:focus {
        @apply border-r border-slate-50 dark:border-slate-700;
      }
    }
    .button--note {
      @apply border-l-0 rounded-none;
      &.is-active {
        @apply border-r border-b-0 bg-yellow-100 dark:bg-yellow-800 border-t-0 border-slate-50 dark:border-slate-700;
      }
      &:hover,
      &:active {
        @apply text-yellow-700 dark:text-yellow-700;
      }
    }
  }
  .button--note {
    @apply text-yellow-600 dark:text-yellow-600 bg-transparent dark:bg-transparent;
  }

  .newticket-box {
    transition:
      box-shadow 0.35s cubic-bezier(0.37, 0, 0.63, 1),
      height 2s cubic-bezier(0.37, 0, 0.63, 1);

    @apply relative border-t border-slate-50 dark:border-slate-700 bg-white dark:bg-slate-900;
    min-width: 550px;

    &.is-focused {
      box-shadow:
        0 1px 3px 0 rgba(0, 0, 0, 0.1),
        0 1px 2px 0 rgba(0, 0, 0, 0.06);
    }

    &.is-private {
      @apply bg-yellow-100 dark:bg-yellow-800;
      .newticket-box__top {
        > input {
          @apply bg-yellow-100 dark:bg-yellow-800;
        }
      }
      .message-editor{
        @apply bg-yellow-100 dark:bg-yellow-800;
      }
    }
  }

  .newticket-box__top {
    @apply relative py-0 px-0;

    textarea {
      @apply shadow-none border-transparent bg-transparent m-0 max-h-60 min-h-[3rem] pt-4 pb-0 px-0 resize-none;
    }
  }
  .email-label {
    position: relative;
  }
  .suggestions-list {
    @apply bg-white dark:bg-slate-900;

    position: absolute;
    z-index: 10;
    width: 100%;
    max-height: 200px;
    overflow-y: auto;
    border: 1px solid #e2e8f0;

    li {
      @apply cursor-pointer p-2;
      text-decoration: none;
      &:hover {
        @apply bg-slate-100 dark:bg-slate-800;
      }
    }
  }
</style>