<template>
  <form class="conversation--form w-full" @submit.prevent="onFormSubmit">
    <div class="gap-2 flex flex-row">
      <div class="w-[50%]">
        <label>
          {{ $t('CONTACT_PANEL.NEW_ACTION.CHANNEL') }}
        </label>
        <div
          class="multiselect-wrap--small"
          :class="{ 'has-multi-select-error': $v.targetInbox.$error }"
        >
          <multiselect
            v-model="targetInbox"
            track-by="id"
            label="name"
            placeholder=""
            selected-label=""
            select-label=""
            deselect-label=""
            :max-height="160"
            :close-on-select="true"
            :options="[...inboxes]"
          >
            <template slot="singleLabel" slot-scope="{ option }">
              <inbox-dropdown-item
                v-if="option.name"
                :name="option.name"
                :inbox-identifier="computedInboxSource(option)"
                :channel-type="option.channel_type"
              />
            </template>
            <template slot="option" slot-scope="{ option }">
              <inbox-dropdown-item
                :name="option.name"
                :inbox-identifier="computedInboxSource(option)"
                :channel-type="option.channel_type"
              />
            </template>
          </multiselect>
        </div>

        <label :class="{ error: $v.targetInbox.$error }">
          <span v-if="$v.targetInbox.$error" class="message">
            {{ $t('CONTACT_PANEL.NEW_ACTION.CHANNEL_ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-[50%]">
        <woot-input
          v-model="description"
          :label="$t('CONTACT_PANEL.NEW_ACTION.DESCRIPTION')"
          type="text"
          :class="{ error: $v.description.$error }"
          :error="
            $v.description.$error
              ? $t('CONTACT_PANEL.NEW_ACTION.DESCRIPTION_ERROR')
              : ''
          "
        />
      </div>
    </div>

    <div class="gap-2 flex flex-row">
      <div class="w-[50%]">
        <label>
          {{ $t('CONTACT_PANEL.NEW_ACTION.SNOOZED_TIME') }}
          <woot-date-time-picker
            :value="scheduledAt"
            :confirm-text="$t('CAMPAIGN.ADD.FORM.SCHEDULED_AT.CONFIRM')"
            @change="onScheduledAtChange"
          />
        </label>
        <label :class="{ error: $v.scheduledAt.$error }">
          <span v-if="$v.scheduledAt.$error" class="message">
            {{ $t('CONTACT_PANEL.NEW_ACTION.SNOOZED_ERROR') }}
          </span>
        </label>
      </div>
      <div class="w-[50%]">
        <label>
          {{ $t('CONTACT_PANEL.NEW_ACTION.PRIORITY') }}
        </label>
        <div class="multiselect-wrap--small">
          <multiselect
            v-model="priority"
            track-by="id"
            label="name"
            placeholder=""
            :max-height="160"
            :close-on-select="true"
            :options="priorityOptions"
          />
        </div>
      </div>
    </div>

    <div class="gap-2 flex flex-row">
      <div class="w-[50%]">
        <label>
          {{ $t('CONTACT_PANEL.NEW_ACTION.ASSIGNEE') }}
        </label>
        <div
          class="multiselect-wrap--small"
          :class="{ 'has-multi-select-error': $v.agent.$error }"
        >
          <multiselect
            v-model="agent"
            class="no-margin"
            placeholder=""
            label="name"
            track-by="id"
            :options="agents"
            :max-height="160"
            :close-on-select="true"
            :show-labels="false"
          />
        </div>

        <label :class="{ error: $v.agent.$error }">
          <span v-if="$v.agent.$error" class="message">
            {{ $t('CONTACT_PANEL.NEW_ACTION.ASSIGNEE_ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-[50%]">
        <label>
          {{ $t('CONTACT_PANEL.NEW_ACTION.TEAM') }}
        </label>
        <div class="multiselect-wrap--small">
          <multiselect
            v-model="team"
            class="no-margin"
            placeholder=""
            label="name"
            track-by="id"
            :options="teams"
            :max-height="160"
            :close-on-select="true"
            :show-labels="false"
          />
        </div>
      </div>
    </div>

    <div class="flex flex-row justify-end gap-2 py-2 px-0 w-full">
      <button class="button clear" @click.prevent="onCancel">
        {{ $t('CONTACT_PANEL.NEW_ACTION.CANCEL') }}
      </button>
      <woot-button type="submit" :is-loading="conversationsUiFlags.isCreating">
        {{ $t('CONTACT_PANEL.NEW_ACTION.SUBMIT') }}
      </woot-button>
    </div>
  </form>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import { required } from 'vuelidate/lib/validators';
import WootDateTimePicker from 'dashboard/components/ui/DateTimePicker.vue';
import InboxDropdownItem from 'dashboard/components/widgets/InboxDropdownItem.vue';
import { getInboxSource } from 'dashboard/helper/inbox';
import { ExceptionWithMessage } from 'shared/helpers/CustomErrors';
import { CONVERSATION_PRIORITY } from '../../../../../shared/constants/messages.js';

export default {
  components: {
    WootDateTimePicker,
    InboxDropdownItem,
  },
  mixins: [alertMixin],
  props: {
    contact: {
      type: Object,
      default: () => ({}),
    },
    onSubmit: {
      type: Function,
      default: () => {},
    },
    channelType: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      description: '',
      targetInbox: {},
      priority: {},
      agent: null,
      team: null,
      scheduledAt: null,
      priorityOptions: [
        {
          id: CONVERSATION_PRIORITY.URGENT,
          name: this.$t('CONVERSATION.PRIORITY.OPTIONS.URGENT'),
          thumbnail: `/assets/images/dashboard/priority/${CONVERSATION_PRIORITY.URGENT}.svg`,
        },
        {
          id: CONVERSATION_PRIORITY.HIGH,
          name: this.$t('CONVERSATION.PRIORITY.OPTIONS.HIGH'),
          thumbnail: `/assets/images/dashboard/priority/${CONVERSATION_PRIORITY.HIGH}.svg`,
        },
        {
          id: CONVERSATION_PRIORITY.MEDIUM,
          name: this.$t('CONVERSATION.PRIORITY.OPTIONS.MEDIUM'),
          thumbnail: `/assets/images/dashboard/priority/${CONVERSATION_PRIORITY.MEDIUM}.svg`,
        },
        {
          id: CONVERSATION_PRIORITY.LOW,
          name: this.$t('CONVERSATION.PRIORITY.OPTIONS.LOW'),
          thumbnail: `/assets/images/dashboard/priority/${CONVERSATION_PRIORITY.LOW}.svg`,
        },
      ],
    };
  },
  validations: {
    targetInbox: {
      required,
    },
    description: {
      required,
    },
    scheduledAt: {
      required,
    },
    agent: {
      required,
    },
  },
  computed: {
    ...mapGetters({
      conversationsUiFlags: 'contactConversations/getUIFlags',
      agents: 'agents/getAgents',
      teams: 'teams/getTeams',
      currentUser: 'getCurrentUser',
    }),
    inboxes() {
      const inboxList =
        this.contact.contactableInboxes.filter(
          item =>
            this.contact.phone_number ||
            item.inbox.channel_type !== 'Channel::StringeePhoneCall'
        ) || [];
      return inboxList.map(inbox => ({
        ...inbox.inbox,
        sourceId: inbox.source_id,
      }));
    },
    newMessagePayload() {
      const content = this.$t('CONTACT_PANEL.NEW_ACTION.CONTENT', {
        description: this.description,
        userName: this.currentUser.name,
      });
      const payload = {
        inbox_id: this.targetInbox.id,
        source_id: this.targetInbox.sourceId,
        contact_id: this.contact.id,
        conversation_type: 'planned',
        status: 'snoozed',
        snoozed_until: this.scheduledAt,
        priority: this.priority ? this.priority.id : null,
        assignee_id: this.agent ? this.agent.id : null,
        team_id: this.team ? this.team.id : null,
        conversation_plan: {
          description: this.description,
        },
        message: {
          content: content,
          message_type: 'activity',
          sender_id: this.currentUser.id,
        },
      };
      return payload;
    },
  },
  mounted() {
    this.$store.dispatch('agents/get');
    this.agent = this.contact.assignee;
    this.team = this.contact.team;
  },
  methods: {
    onScheduledAtChange(value) {
      this.scheduledAt = value;
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
    onCancel() {
      this.$emit('cancel');
    },
    onSuccess() {
      this.$emit('success');
    },
    onFormSubmit() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      this.createConversation({
        payload: this.newMessagePayload,
      });
    },
    async createConversation({ payload }) {
      try {
        const data = await this.onSubmit(payload);
        this.$store.dispatch('contacts/show', { id: this.contact.id });
        const action = {
          type: 'link',
          to: `/app/accounts/${data.account_id}/conversations/${data.id}`,
          message: this.$t('NEW_CONVERSATION.FORM.GO_TO_CONVERSATION'),
        };
        this.onSuccess();
        this.showAlert(
          this.$t('NEW_CONVERSATION.FORM.SUCCESS_MESSAGE'),
          action
        );
      } catch (error) {
        if (error instanceof ExceptionWithMessage) {
          this.showAlert(error.data);
        } else {
          this.showAlert(this.$t('NEW_CONVERSATION.FORM.ERROR_MESSAGE'));
        }
      }
    },
  },
};
</script>
