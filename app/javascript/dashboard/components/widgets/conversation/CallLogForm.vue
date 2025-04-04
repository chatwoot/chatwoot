<template>
  <form
    class="w-full px-8 pt-6 pb-8 contact--form"
    @submit.prevent="handleSubmit"
  >
    <custom-attribute
      :key="callStatusData.id"
      :attribute-key="callStatusData.attributeKey"
      :attribute-type="callStatusData.attributeType"
      :values="callStatusData.values"
      :label="callStatusData.label"
      :description="callStatusData.description"
      :value="callStatusData.value"
      :show-actions="callStatusData.showActions"
      :class="'conversation--attribute'"
      :hide-info-tag="true"
      @update="onUpdate"
    />
    <div class="w-full px-4">
      <label :class="{ error: $v.callNote.$error }">
        {{ 'Call Note' }}
        <input
          v-model.trim="callNote"
          type="text"
          :placeholder="'Call Note'"
          @input="$v.callNote.$touch"
        />
      </label>
    </div>
    <div class="w-full px-4">
      <label>
        {{ 'Call Type' }}
      </label>
      <multiselect
        v-model="callType"
        track-by="value"
        label="name"
        :placeholder="'call type'"
        selected-label
        :max-height="160"
        :options="callTypeValues"
        :allow-empty="true"
        :option-height="40"
      />
    </div>
    <div class="w-full px-4">
      <label :class="{ error: $v.date.$error }">
        {{ 'Date' }}
        <woot-date-time-picker
          name="callLogDate"
          :value="date"
          :confirm-text="$t('CAMPAIGN.ADD.FORM.SCHEDULED_AT.CONFIRM')"
          :placeholder="$t('CAMPAIGN.ADD.FORM.SCHEDULED_AT.PLACEHOLDER')"
          :disable-date-after="true"
          @change="onChange"
        />
      </label>
    </div>
    <div class="w-full px-4">
      <label>
        {{ 'Call Duration (in Min)' }}
        <input
          v-model="callDuration"
          type="number"
          :placeholder="'1'"
          @blur="$v.callNote.$touch"
        />
      </label>
    </div>
    <div class="flex flex-row justify-end gap-2 py-2 px-0 w-full">
      <button class="button clear" @click.prevent="onCancel">
        {{ 'Cancel' }}
      </button>
      <woot-button
        type="submit"
        :is-disabled="isLoading"
        :is-loading="isLoading"
      >
        {{ 'Create Call Log' }}
      </woot-button>
    </div>
  </form>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import { required } from 'vuelidate/lib/validators';
import CustomAttribute from 'dashboard/components/CustomAttribute.vue';
import attributeMixin from 'dashboard/mixins/attributeMixin';
import WootDateTimePicker from 'dashboard/components/ui/DateTimePicker.vue';
import { mapGetters } from 'vuex';

const CALL_STATUS_VALUES = [
  'Scheduled',
  'Not Picked',
  'Follow-up',
  'Converted',
  'Dropped',
];

const CALL_STATUS_VALUES_BSC = [
  'Ringing, No Response',
  'Hung up after intro',
  'Conversation Happened',
  'Asked to Whatsapp',
  'Not interested',
  'Asked to call Later',
  'Other',
];

const BombayShavingAccountIds = [1058, 1126, 1125];

export default {
  components: {
    CustomAttribute,
    WootDateTimePicker,
  },
  mixins: [alertMixin, attributeMixin],
  props: {
    inProgress: {
      type: Boolean,
      default: false,
    },
    onSubmit: {
      type: Function,
      default: () => {},
    },
  },
  data() {
    return {
      callNote: '',
      callStatus: 'Scheduled',
      date: null,
      callDuration: 0,
      attributeType: 'conversation_attribute',
      isLoading: false,
      callType: {
        value: 'outbound',
        name: 'OUTBOUND',
      },
      callTypeValues: [
        {
          value: 'inbound',
          name: 'INBOUND',
        },
        {
          value: 'outbound',
          name: 'OUTBOUND',
        },
      ],
    };
  },
  validations: {
    callNote: {
      required,
    },
    callStatus: {
      required,
    },
    date: {
      required,
    },
    callDuration: 0,
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
    }),
    callStatusData() {
      const callingStatusAttribute = this.attributes.find(
        attribute => attribute.attribute_key === 'calling_status'
      );
      return {
        id: '1',
        attributeKey: 'calling_status',
        attributeType: 'list',
        values: BombayShavingAccountIds.includes(this.accountId)
          ? callingStatusAttribute?.attribute_values ?? CALL_STATUS_VALUES_BSC
          : callingStatusAttribute?.attribute_values ?? CALL_STATUS_VALUES,
        label: 'Calling Status',
        description: 'Notes related to call for this conversations',
        value: this.callStatus,
        showActions: true,
      };
    },
  },
  methods: {
    onUpdate(key, value) {
      if (key === 'calling_status') {
        this.callStatus = value;
      }
    },
    onSuccess() {
      this.$emit('success');
    },
    onCancel() {
      this.$emit('cancel');
    },
    onChange(value) {
      this.date = value;
    },
    async handleSubmit() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      if (this.callDuration < 0) {
        this.showAlert("Call duration can't be negative");
        return;
      }
      if (!this.callType?.value) {
        this.showAlert('Call Type is Required');
        return;
      }
      try {
        this.isLoading = true;
        await this.onSubmit({
          callStatus: this.callStatus,
          callNote: this.callNote,
          date: this.date,
          callDuration: this.callDuration,
          contactId: this.contact.id,
          conversationId: this.conversationId,
          inboxId: this.currentChat.inbox_id,
          isInbound: this.callType.value === 'inbound',
          agentPhoneNo: this.currentUser?.custom_attributes?.phone_number,
        });
        this.onSuccess();
        this.showAlert('Call log create successfully');
      } catch (error) {
        this.showAlert('Error Creating Call log');
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>
