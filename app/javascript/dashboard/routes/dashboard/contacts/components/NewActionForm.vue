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
            class="no-margin"
            label="name"
            track-by="id"
            placeholder=""
            :options="inboxes"
            :max-height="160"
            :close-on-select="true"
            :show-labels="false"
          />
        </div>

        <label :class="{ error: $v.targetInbox.$error }">
          <span v-if="$v.targetInbox.$error" class="message">
            {{ $t('NEW_CONVERSATION.FORM.INBOX.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-[50%]">
        <woot-input
          v-model="name"
          :label="$t('CONTACT_PANEL.NEW_ACTION.DESCRIPTION')"
          type="text"
          :class="{ error: $v.name.$error }"
          :error="$v.name.$error ? $t('CAMPAIGN.ADD.FORM.TITLE.ERROR') : ''"
          @blur="$v.name.$touch"
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
            @change="onChange"
          />
        </label>
      </div>
      <div class="w-[50%]">
        <label :class="{ error: $v.name.$error }">
          {{ $t('CONTACT_PANEL.NEW_ACTION.PRIORITY') }}
        </label>
        <div
          class="multiselect-wrap--small"
          :class="{ 'has-multi-select-error': $v.targetInbox.$error }"
        >
          <multiselect
            v-model="priority"
            track-by="id"
            label="name"
            :placeholder="$t('FORMS.MULTISELECT.SELECT')"
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
            {{ $t('NEW_CONVERSATION.FORM.INBOX.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-[50%]">
        <label>
          {{ $t('CONTACT_PANEL.NEW_ACTION.TEAM') }}
        </label>
        <div
          class="multiselect-wrap--small"
          :class="{ 'has-multi-select-error': $v.team.$error }"
        >
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

        <label :class="{ error: $v.team.$error }">
          <span v-if="$v.team.$error" class="message">
            {{ $t('NEW_CONVERSATION.FORM.INBOX.ERROR') }}
          </span>
        </label>
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
import { CONVERSATION_PRIORITY } from '../../../../../shared/constants/messages.js';

export default {
  components: {
    WootDateTimePicker,
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
      name: '',
      targetInbox: {},
      priority: {},
      agent: null,
      team: null,
      scheduledAt: null,
      priorityOptions: [
        {
          id: null,
          name: this.$t('CONVERSATION.PRIORITY.OPTIONS.NONE'),
          thumbnail: `/assets/images/dashboard/priority/none.svg`,
        },
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
    name: {
      required,
    },
    agent: {
      required,
    },
    team: {
      required,
    },
    targetInbox: {
      required,
    },
  },
  computed: {
    ...mapGetters({
      conversationsUiFlags: 'contactConversations/getUIFlags',
      inboxes: 'inboxes/getInboxes',
      agents: 'agents/getAgents',
      teams: 'teams/getTeams',
    }),
  },
  methods: {
    onChange(value) {
      this.scheduledAt = value;
    },
  },
};
</script>
