<template>
  <div
    class="border border-solid border-slate-100 dark:border-slate-700 rounded-md p-2 flex flex-col gap-2"
  >
    <div class="flex justify-between items-center">
      <p class="mb-0 text-xs">
        Call Summary ({{ callLog.inbound ? 'Inbound' : 'outbound' }})
      </p>
      <div class="flex gap-2">
        <woot-button
          v-if="callLog.transcript"
          variant="smooth"
          icon="closed-caption"
          size="large"
          :class="'p-0 !h-6 !w-7'"
          @click="toggleTranscriptModal"
        />
        <a
          v-if="callLog.recordingLink"
          :href="callLog.recordingLink"
          target="_blank"
        >
          <woot-button :class="'!h-6 text-xs'" variant="smooth">
            {{ 'See Recording' }}
          </woot-button>
        </a>
      </div>
    </div>
    <div
      class="w-full relative bg-slate-25 dark:bg-slate-800 rounded-md px-2 py-1"
    >
      <div class="flex justify-between items-center text-[10px]">
        <span>{{ readableTime }}</span>
        <div class="flex gap-3 items-center">
          <span>{{ callLog.callStatus }}</span>
          <span class="flex items-center text-[10px] gap-1.5">
            <fluent-icon
              :icon="'timer'"
              class="text-slate-600 dark:text-slate-400"
              size="12"
            />
            {{ formattedDuration }}
          </span>
        </div>
      </div>
      <p
        v-if="callLog.summary"
        class="text-xs mr-4 mt-2 max-h-32 overflow-y-scroll"
      >
        {{
          isExpanded ? callLog.summary : `${callLog.summary.slice(0, 100)}...`
        }}
      </p>
      <woot-button
        v-if="callLog.summary"
        variant="smooth"
        size="tiny"
        class="text-slate-600 dark:text-slate-400 absolute bottom-0 right-0 mr-1 mb-1 cursor-pointer"
        :icon="isExpanded ? 'subtract' : 'add'"
        @click="toggleSummary"
      />
    </div>
    <div class="flex gap-2">
      <woot-button
        v-if="callLog.category"
        color-scheme="secondary"
        variant="smooth"
        size="small"
        :class="'!h-6'"
      >
        {{ callLog.category }}
      </woot-button>
      <woot-button
        v-if="callLog.sentiment"
        color-scheme="secondary"
        variant="smooth"
        size="small"
        :class="'!h-6'"
      >
        {{ callLog.sentiment }}
      </woot-button>
    </div>
    <custom-attribute
      v-for="attribute in callAttributes"
      :key="attribute.id"
      :attribute-key="attribute.attributeKey"
      :attribute-type="attribute.attributeType"
      :values="attribute.values"
      :label="attribute.label"
      :description="attribute.description"
      :value="attribute.value"
      :show-actions="attribute.showActions"
      :class="'conversation--attribute'"
      :is-call-log="true"
      :hide-info-tag="true"
      @update="onUpdate"
      @delete="onDelete"
      @copy="onCopy"
    />
    <call-transcript-modal
      v-if="showTranscriptModal"
      :show="showTranscriptModal"
      :call-transcript="callLog.transcript"
      :readable-time="readableTime"
      :formatted-duration="formattedDuration"
      @cancel="toggleTranscriptModal"
    />
  </div>
</template>

<script>
import CallTranscriptModal from './CallTranscriptModal.vue';
import timeMixin from '../../../mixins/time';
import CustomAttribute from 'dashboard/components/CustomAttribute.vue';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import alertMixin from 'shared/mixins/alertMixin';
import accountMixin from 'dashboard/mixins/account';
import attributeMixin from 'dashboard/mixins/attributeMixin';

const CALL_STATUS_VALUES = [
  'Scheduled',
  'Not Picked',
  'Follow-up',
  'Converted',
  'Dropped',
];

const CALL_STATUS_VALUES_BSC = [
  'Scheduled',
  'Follow-up',
  'Converted',
  'Ringing, No Response',
  'Hung up after intro',
  'Conversation Happened',
  'Asked to Whatsapp',
  'Already Purchased',
  "Don't want",
  'Asked to call Later',
  'Other',
];

const BombayShavingAccountIds = [1058, 1126, 1125];

export default {
  components: {
    CallTranscriptModal,
    CustomAttribute,
  },
  mixins: [timeMixin, alertMixin, accountMixin, attributeMixin],
  props: {
    callLog: {
      type: Object,
      required: true,
    },
    index: {
      type: Number,
      required: true,
    },
    phoneNumber: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isExpanded: false,
      showTranscriptModal: false,
      attributeType: 'conversation_attribute',
    };
  },
  computed: {
    readableTime() {
      if (!this.callLog.callInitiatedAt) {
        return '';
      }
      try {
        const timestamp = Math.floor(
          new Date(this.callLog.callInitiatedAt).getTime() / 1000
        );
        const date = this.messageTimestamp(timestamp, 'dd MMMM yyyy');
        return `${date}`;
      } catch (error) {
        return 'Invalid date';
      }
    },
    formattedDuration() {
      const seconds = this.callLog.onCallDuration;
      if (!seconds) return '0 sec';
      const hours = Math.floor(seconds / 3600);
      const minutes = Math.floor((seconds % 3600) / 60);
      const remainingSeconds = seconds % 60;
      if (hours > 0) {
        return `${hours} hour${hours > 1 ? 's' : ''} ${
          minutes > 0 ? `${minutes} min` : ''
        }`;
      }
      if (minutes > 0) {
        return `${minutes} min`;
      }
      return `${remainingSeconds} sec`;
    },
    callAttributes() {
      const callingStatusAttribute = this.attributes.find(
        attribute => attribute.attribute_key === 'calling_status'
      );
      return [
        {
          id: '1',
          attributeKey: 'calling_status',
          attributeType: 'list',
          values: BombayShavingAccountIds.includes(this.accountId)
            ? callingStatusAttribute?.attribute_values ?? CALL_STATUS_VALUES_BSC
            : callingStatusAttribute?.attribute_values ?? CALL_STATUS_VALUES,
          label: 'Calling Status',
          description: 'Notes related to call for this conversations',
          value: this.callLog.agentCallStatus,
          showActions: true,
        },
        {
          id: '2',
          attributeKey: 'calling_notes',
          attributeType: 'text',
          label: 'Calling Notes',
          description: 'Notes related to call for this conversations',
          value: this.callLog.agentCallNote,
          showActions: true,
        },
      ];
    },
  },
  methods: {
    toggleSummary() {
      this.isExpanded = !this.isExpanded;
    },
    toggleTranscriptModal() {
      this.showTranscriptModal = !this.showTranscriptModal;
    },
    handleStatusChange(value) {
      this.selectedStatus = value;
      this.isStatusChanged = value.name !== this.callLog.agentCallStatus;
    },
    async onUpdate(key, value) {
      const updatePayload = {
        phoneNumber: this.phoneNumber,
        index: this.index,
        [key === 'calling_status' ? 'agentCallStatus' : 'agentCallNote']: value,
      };
      try {
        if (this.index === 0) {
          const updatedAttributes = {
            ...this.customAttributes,
            calling_status: value,
          };
          await this.$store.dispatch('updateCustomAttributes', {
            conversationId: this.conversationId,
            customAttributes: updatedAttributes,
          });
        }
        await this.$store.dispatch('contactCallLogs/update', updatePayload);
        this.showAlert(
          this.$t(
            `Call Log ${
              key === 'calling_status' ? 'Status' : 'Note'
            } updated successfully`
          )
        );
      } catch (error) {
        this.showAlert(
          this.$t(
            `Error Updating Call ${
              key === 'calling_status' ? 'Status' : 'Note'
            }`
          )
        );
      }
    },
    async onDelete(key) {
      const updatePayload = {
        phoneNumber: this.phoneNumber,
        index: this.index,
        [key === 'calling_status' ? 'agentCallStatus' : 'agentCallNote']: '',
      };
      try {
        await this.$store.dispatch('contactCallLogs/update', updatePayload);
        this.showAlert(
          `Call Log ${
            key === 'calling_status' ? 'Status' : 'Note'
          } Delete successfully`
        );
      } catch (error) {
        this.showAlert(
          `Error Deleting Call ${key === 'calling_status' ? 'Status' : 'Note'}`
        );
      }
    },
    async onCopy(attributeValue) {
      await copyTextToClipboard(attributeValue);
      this.showAlert(this.$t('CUSTOM_ATTRIBUTES.COPY_SUCCESSFUL'));
    },
  },
};
</script>
