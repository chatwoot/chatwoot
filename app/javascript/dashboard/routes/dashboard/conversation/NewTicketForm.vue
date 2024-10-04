<template>
  <div>
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
        <span v-if="$v.newTicket.inbox.$error" class="message text-red-400">
          Inbox is required
        </span>
      </div>

      <div class="w-full">
        <label class="mb-2 ml-2">
          Email Address
          <input type="email" v-model="newTicket.email" @input="$v.newTicket.email.$touch"/>
          <span v-if="$v.newTicket.email.$error" class="message text-red-400">
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
          <span v-if="$v.newTicket.name.$error" class="message text-red-400">
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
      <label :class="{ error: $v.newTicket.note.$error }">
        {{ $t('CANNED_MGMT.EDIT.FORM.CONTENT.LABEL') }}
      </label>
      <div>
        <woot-message-editor
          v-model="newTicket.note"
          class="message-editor [&>div]:px-1"
          :class="{ editor_warning: $v.newTicket.note.$error }"
          :enable-variables="true"
          :enable-canned-responses="false"
          :placeholder="$t('CONVERSATION.REPLYBOX.CREATE')"
          @blur="$v.newTicket.note.$touch"
        />
      </div>

      <span v-if="$v.newTicket.note.$error" class="message text-red-400">
        Note is required
      </span>
    </div>

    <div class="w-full flex items-center gap-2">
      <input type="checkbox" value="true" v-model="newTicket.response_needed">
      <label for="conversation_creation">
        In need of response
      </label>
    </div>
  </div>
</template>

<script>
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

  export default {
    mixins: [alertMixin],
    components: {
      LabelSelector,
      InboxDropdownItem,
      WootMessageEditor,
      MultiselectDropdown,
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
        currentAccountId: 'getCurrentAccountId',
        'customAttributes': 'getCustomAttributes',
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
      customAttributes(){
        return {
          response_needed: this.newTicket.response_needed,
          issue_type: this.newTicket.issue_type,
          contact_type: this.contactType,
        }
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
        }
      }
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
      submitForm(){
        console.log(this.newTicketData)
        this.$v.$touch();

        if (this.$v.$invalid) {
          this.showAlert('There are validation errors')
        } else {
          this.$store.dispatch('saveTicket', this.newTicketData).then((result) => {
            this.showAlert('Ticket created!')
            this.clearTicket()
            this.navigateToTicket(result.data.id)
          }).catch(() => {
            this.showAlert('Failed to create ticket', 'error')
          })
        }
      },

      getValidationErrors() {
        const errors = {};
        

        return errors;
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
      }
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
        note: {
          required
        },
        phoneNumber: {},
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
    }
  };
</script>
<style scoped>
  label input[type="email"], label input[type="text"] {
    margin-bottom: 0px !important;
  }
  .multiselect {
    margin-bottom: 0px !important;
  }
</style>