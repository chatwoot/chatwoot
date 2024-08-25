<template>
  <div class="h-auto overflow-auto flex flex-col">
    <woot-modal-header
      :header-title="pageTitle"
      :header-content="$t('CAMPAIGN.ADD.DESC')"
    />
    <form class="flex flex-col w-full" @submit.prevent="updateCampaign">
      <div class="w-full">
        <woot-input
          v-model="title"
          :label="$t('CAMPAIGN.ADD.FORM.TITLE.LABEL')"
          type="text"
          :class="{ error: $v.title.$error }"
          :error="$v.title.$error ? $t('CAMPAIGN.ADD.FORM.TITLE.ERROR') : ''"
          @blur="$v.title.$touch"
        />

        <div v-if="isOngoingType" class="editor-wrap">
          <label>
            {{ $t('CAMPAIGN.ADD.FORM.MESSAGE.LABEL') }}
          </label>
          <div>
            <woot-message-editor
              v-model="message"
              class="message-editor"
              :class="{ editor_warning: $v.message.$error }"
              @blur="$v.message.$touch"
            />
            <span v-if="$v.message.$error" class="editor-warning__message">
              {{ $t('CAMPAIGN.ADD.FORM.MESSAGE.ERROR') }}
            </span>
          </div>
        </div>

        <div v-else>
          <label v-if="!planned" :class="{ error: $v.message.$error }">
            {{ $t('CAMPAIGN.ADD.FORM.MESSAGE.LABEL') }}
            <textarea
              v-model="message"
              rows="5"
              type="text"
              @blur="$v.message.$touch"
            />
            <span v-if="$v.message.$error" class="message">
              {{ $t('CAMPAIGN.ADD.FORM.MESSAGE.ERROR') }}
            </span>
          </label>
          <woot-input
            v-else
            v-model="privateNote"
            :label="$t('CAMPAIGN.ADD.FORM.PRIVATE_NOTE.LABEL')"
            type="text"
            :class="{ error: $v.privateNote.$error }"
            :error="
              $v.privateNote.$error
                ? $t('CAMPAIGN.ADD.FORM.PRIVATE_NOTE.ERROR')
                : ''
            "
            @blur="$v.privateNote.$touch"
          />
        </div>

        <label
          class="multiselect-wrap--small"
          :class="{ error: $v.selectedInbox.$error }"
        >
          {{ $t('CAMPAIGN.ADD.FORM.INBOX.LABEL') }}
          <select
            v-if="isOngoingType"
            v-model="selectedInbox"
            @change="onChangeInbox($event)"
          >
            <option v-for="item in inboxes" :key="item.name" :value="item.id">
              {{ item.name }}
            </option>
          </select>
          <multiselect
            v-else
            v-model="selectedInboxes"
            :options="inboxes"
            track-by="id"
            label="name"
            :multiple="true"
            :close-on-select="false"
            :clear-on-select="false"
            :hide-selected="true"
            :placeholder="$t('CAMPAIGN.ADD.FORM.INBOX.PLACEHOLDER')"
            selected-label
            :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
            :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
            @blur="$v.selectedInboxes.$touch"
            @select="$v.selectedInboxes.$touch"
          />
          <span v-if="$v.selectedInboxes.$error" class="message">
            {{ $t('CAMPAIGN.ADD.FORM.INBOX.ERROR') }}
          </span>
        </label>

        <label
          v-if="isOneOffType || isFlexibleType"
          class="multiselect-wrap--small"
          :class="{ error: $v.selectedAudiences.$error }"
        >
          {{ $t('CAMPAIGN.ADD.FORM.AUDIENCE.LABEL') }}
          <multiselect
            v-model="selectedAudiences"
            :options="audienceList"
            track-by="id"
            label="title"
            :multiple="true"
            :close-on-select="false"
            :clear-on-select="false"
            :hide-selected="true"
            :placeholder="$t('CAMPAIGN.ADD.FORM.AUDIENCE.PLACEHOLDER')"
            selected-label
            :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
            :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
            @blur="$v.selectedAudiences.$touch"
            @select="$v.selectedAudiences.$touch"
          />
          <span v-if="$v.selectedAudiences.$error" class="message">
            {{ $t('CAMPAIGN.ADD.FORM.AUDIENCE.ERROR') }}
          </span>
        </label>

        <label
          v-if="isOngoingType"
          :class="{ error: $v.selectedSender.$error }"
        >
          {{ $t('CAMPAIGN.ADD.FORM.SENT_BY.LABEL') }}
          <select v-model="selectedSender">
            <option
              v-for="sender in sendersAndBotList"
              :key="sender.name"
              :value="sender.id"
            >
              {{ sender.name }}
            </option>
          </select>
          <span v-if="$v.selectedSender.$error" class="message">
            {{ $t('CAMPAIGN.ADD.FORM.SENT_BY.ERROR') }}
          </span>
        </label>

        <label v-if="isOneOffType">
          {{ $t('CAMPAIGN.ADD.FORM.SCHEDULED_AT.LABEL') }}
          <woot-date-time-picker
            v-model="scheduledAt"
            :confirm-text="$t('CAMPAIGN.ADD.FORM.SCHEDULED_AT.CONFIRM')"
            @change="onChange"
          />
        </label>

        <woot-input
          v-if="isOngoingType"
          v-model="endPoint"
          :label="$t('CAMPAIGN.ADD.FORM.END_POINT.LABEL')"
          type="text"
          :class="{ error: $v.endPoint.$error }"
          :error="
            $v.endPoint.$error ? $t('CAMPAIGN.ADD.FORM.END_POINT.ERROR') : ''
          "
          :placeholder="$t('CAMPAIGN.ADD.FORM.END_POINT.PLACEHOLDER')"
          @blur="$v.endPoint.$touch"
        />
        <woot-input
          v-if="isOngoingType"
          v-model="timeOnPage"
          :label="$t('CAMPAIGN.ADD.FORM.TIME_ON_PAGE.LABEL')"
          type="text"
          :class="{ error: $v.timeOnPage.$error }"
          :error="
            $v.timeOnPage.$error
              ? $t('CAMPAIGN.ADD.FORM.TIME_ON_PAGE.ERROR')
              : ''
          "
          :placeholder="$t('CAMPAIGN.ADD.FORM.TIME_ON_PAGE.PLACEHOLDER')"
          @blur="$v.timeOnPage.$touch"
        />
        <div v-if="isFlexibleType">
          <label :class="{ error: $v.flexibleScheduledAt.$error }">
            {{ $t('CAMPAIGN.ADD.FORM.SCHEDULED_AT.LABEL') }}
          </label>
          <div class="flex flex-row gap-2">
            <multiselect
              v-model="scheduledAttribute"
              :placeholder="$t('CAMPAIGN.FLEXIBLE.SCHEDULED_ATTRIBUTE')"
              class="multiselect-wrap--small max-w-[35%]"
              track-by="key"
              label="name"
              selected-label=""
              select-label=""
              deselect-label=""
              :options="contactDateAttributes"
            />
            <multiselect
              v-model="scheduledCalculation"
              :placeholder="$t('CAMPAIGN.FLEXIBLE.SCHEDULED_CALCULATION')"
              class="multiselect-wrap--small max-w-[40%]"
              track-by="key"
              label="name"
              selected-label=""
              select-label=""
              deselect-label=""
              :options="scheduledCalculations"
              @select="scheduledCalculationChange"
            />
            <input
              v-if="showExtraDays"
              v-model="extraDays"
              type="number"
              class="max-w-[25%]"
              :placeholder="$t('CAMPAIGN.FLEXIBLE.EXTRA_DAYS')"
            />
          </div>
          <span v-if="$v.flexibleScheduledAt.$error" class="message">
            {{ $t('CAMPAIGN.ADD.FORM.SCHEDULED_AT.ERROR') }}
          </span>
        </div>
        <label>
          <input
            v-model="enabled"
            type="checkbox"
            value="enabled"
            name="enabled"
          />
          {{ $t('CAMPAIGN.ADD.FORM.ENABLED') }}
        </label>
        <label v-if="isOngoingType">
          <input
            v-model="triggerOnlyDuringBusinessHours"
            type="checkbox"
            value="triggerOnlyDuringBusinessHours"
            name="triggerOnlyDuringBusinessHours"
          />
          {{ $t('CAMPAIGN.ADD.FORM.TRIGGER_ONLY_BUSINESS_HOURS') }}
        </label>
      </div>

      <div class="flex flex-row justify-end gap-2 py-2 px-0 w-full">
        <woot-button :is-loading="uiFlags.isCreating">
          {{
            selectedCampaign
              ? $t('CAMPAIGN.EDIT.UPDATE_BUTTON_TEXT')
              : $t('CAMPAIGN.ADD.CREATE_BUTTON_TEXT')
          }}
        </woot-button>
        <woot-button variant="clear" @click.prevent="onClose">
          {{ $t('CAMPAIGN.ADD.CANCEL_BUTTON_TEXT') }}
        </woot-button>
      </div>
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { required, requiredIf } from 'vuelidate/lib/validators';
import alertMixin from 'shared/mixins/alertMixin';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import campaignMixin from 'shared/mixins/campaignMixin';
import WootDateTimePicker from 'dashboard/components/ui/DateTimePicker.vue';
import { URLPattern } from 'urlpattern-polyfill';
import { CAMPAIGNS_EVENTS } from '../../../../helper/AnalyticsHelper/events';
import contactFilterItems from '../../contacts/contactFilterItems';
import { parseISO } from 'date-fns';

export default {
  components: {
    WootDateTimePicker,
    WootMessageEditor,
  },

  mixins: [alertMixin, campaignMixin],
  props: {
    selectedCampaign: {
      type: Object,
      default: () => {},
    },
    plannedDefault: {
      type: Boolean,
      default: true,
    },
  },
  data() {
    return {
      title: '',
      message: '',
      privateNote: '',
      planned: true,
      selectedSender: 0,
      selectedInbox: null,
      endPoint: '',
      timeOnPage: 10,
      show: true,
      enabled: true,
      triggerOnlyDuringBusinessHours: false,
      scheduledAt: null,
      scheduledAttribute: null,
      scheduledCalculation: null,
      extraDays: null,
      selectedAudiences: [],
      selectedInboxes: [],
      senderList: [],
      // eslint-disable-next-line vue/no-unused-components
      contactFilterItems,
    };
  },

  validations() {
    const commonValidations = {
      title: {
        required,
      },
      message: {
        required: requiredIf(() => {
          return this.planned === false;
        }),
      },
      privateNote: {
        required: requiredIf(() => {
          return this.planned === true;
        }),
      },
      selectedInbox: {
        required: requiredIf(() => {
          return this.selectedInboxes === [];
        }),
      },
      selectedInboxes: {
        required: requiredIf(() => {
          return this.selectedInbox === null;
        }),
      },
      flexibleScheduledAt: {
        required: requiredIf(() => {
          return (
            this.isFlexibleType &&
            (this.scheduledCalculation === null ||
              this.scheduledAttribute === null ||
              this.extraDays === null)
          );
        }),
      },
    };
    if (this.isOngoingType) {
      return {
        ...commonValidations,
        selectedSender: {
          required,
        },
        endPoint: {
          required,
          shouldBeAValidURLPattern(value) {
            try {
              // eslint-disable-next-line
              new URLPattern(value);
              return true;
            } catch (error) {
              return false;
            }
          },
          shouldStartWithHTTP(value) {
            if (value) {
              return (
                value.startsWith('https://') || value.startsWith('http://')
              );
            }
            return false;
          },
        },
        timeOnPage: {
          required,
        },
      };
    }
    return {
      ...commonValidations,
      selectedAudiences: {
        isEmpty() {
          return !!this.selectedAudiences.length;
        },
      },
    };
  },
  computed: {
    pageTitle() {
      if (this.selectedCampaign) {
        return `${this.$t('CAMPAIGN.EDIT.TITLE')} - ${
          this.selectedCampaign.title
        }`;
      }
      return this.$t('CAMPAIGN.ADD.TITLE');
    },
    ...mapGetters({
      uiFlags: 'campaigns/getUIFlags',
    }),
    inboxes() {
      if (this.isOngoingType) {
        return this.$store.getters['inboxes/getWebsiteInboxes'];
      }
      const inboxes = this.$store.getters['inboxes/getInboxes'];

      if (this.planned) {
        return inboxes.filter(
          item => item.channel_type !== 'Channel::WebWidget'
        );
      }

      return inboxes.filter(
        item =>
          item.channel_type !== 'Channel::StringeePhoneCall' &&
          item.channel_type !== 'Channel::WebWidget'
      );
    },
    sendersAndBotList() {
      return [
        {
          id: 0,
          name: 'Bot',
        },
        ...this.senderList,
      ];
    },
    showExtraDays() {
      return !this.scheduledCalculation?.key.startsWith('equal');
    },
  },
  mounted() {
    this.$track(CAMPAIGNS_EVENTS.OPEN_NEW_CAMPAIGN_MODAL, {
      type: this.campaignType,
    });
    this.$store.dispatch('customViews/get', 'contact');
    this.planned = this.plannedDefault;
    if (this.selectedCampaign) {
      this.setFormValues();
    }
  },
  methods: {
    scheduledCalculationChange() {
      if (this.scheduledCalculation.key.startsWith('equal')) {
        this.extraDays = 0;
      } else {
        this.extraDays = null;
      }
    },
    onClose() {
      this.$emit('on-close');
    },
    onChange(value) {
      this.scheduledAt = value;
    },
    async loadInboxMembers() {
      if (!this.selectedInbox) return;
      try {
        const response = await this.$store.dispatch('inboxMembers/get', {
          inboxId: this.selectedInbox,
        });
        const {
          data: { payload: inboxMembers },
        } = response;
        this.senderList = inboxMembers;
      } catch (error) {
        const errorMessage =
          error?.response?.message || this.$t('CAMPAIGN.ADD.API.ERROR_MESSAGE');
        this.showAlert(errorMessage);
      }
    },
    async onChangeInbox() {
      this.loadInboxMembers();
    },
    setFormValues() {
      const {
        title,
        message,
        private_note: privateNote,
        planned,
        enabled,
        trigger_only_during_business_hours: triggerOnlyDuringBusinessHours,
        trigger_rules: { url: endPoint, time_on_page: timeOnPage },
        sender,
        scheduled_at: scheduledAt,
      } = this.selectedCampaign;
      this.title = title;
      this.message = message;
      this.privateNote = privateNote;
      this.scheduledAt = scheduledAt ? parseISO(scheduledAt) : '';
      this.endPoint = endPoint;
      this.timeOnPage = timeOnPage;
      this.selectedInbox = this.selectedCampaign.inbox?.id;
      this.selectedInboxes = this.getSelectedInboxes();
      this.selectedAudiences = this.getSelectedAudiences();
      this.triggerOnlyDuringBusinessHours = triggerOnlyDuringBusinessHours;
      this.selectedSender = (sender && sender.id) || 0;
      this.enabled = enabled;
      this.planned = planned;
      this.setFlexibleSchedule();
      this.loadInboxMembers();
    },
    setFlexibleSchedule() {
      if (!this.selectedCampaign.flexible_scheduled_at?.calculation) return;
      const {
        calculation,
        contact_attribute: attribute,
        extra_days: extraDays,
      } = this.selectedCampaign.flexible_scheduled_at;
      this.scheduledCalculation = this.scheduledCalculations.find(
        i => i.key === calculation
      );
      this.scheduledAttribute = this.contactDateAttributes.find(
        i => i.key === attribute.key
      );
      this.extraDays = extraDays;
    },
    getSelectedInboxes() {
      return this.selectedCampaign.inboxes?.map(inbox => {
        return this.inboxes.find(i => i.id === inbox.id);
      });
    },
    getSelectedAudiences() {
      const audiences = this.audienceList;
      return this.selectedCampaign.audience?.map(item => {
        return audiences.find(i => i.id === item.id);
      });
    },
    getCampaignDetails() {
      let campaignDetails = null;
      if (this.isOngoingType) {
        campaignDetails = {
          title: this.title,
          message: this.message,
          inbox_id: this.selectedInbox,
          sender_id: this.selectedSender || null,
          enabled: this.enabled,
          trigger_only_during_business_hours:
            // eslint-disable-next-line prettier/prettier
            this.triggerOnlyDuringBusinessHours,
          trigger_rules: {
            url: this.endPoint,
            time_on_page: this.timeOnPage,
          },
        };
      } else {
        const audience = this.selectedAudiences.map(item => {
          return {
            id: item.id,
            type: item.type,
          };
        });
        const inboxes = this.selectedInboxes.map(item => {
          return {
            id: item.id,
            name: item.name,
          };
        });
        campaignDetails = {
          title: this.title,
          message: this.message,
          private_note: this.privateNote,
          planned: this.planned,
          inbox_id: this.selectedInbox,
          scheduled_at: this.scheduledAt,
          flexible_scheduled_at: {
            calculation: this.scheduledCalculation?.key,
            contact_attribute: {
              key: this.scheduledAttribute?.key,
              type: this.scheduledAttribute?.type,
            },
            extra_days: this.extraDays,
          },
          audience,
          inboxes,
          enabled: this.enabled,
        };
      }
      return {
        ...campaignDetails,
        campaign_type: this.campaignType,
      };
    },
    async updateCampaign() {
      if (this.selectedCampaign) this.editCampaign();
      else this.addCampaign();
    },
    async addCampaign() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      try {
        const campaignDetails = this.getCampaignDetails();
        await this.$store.dispatch('campaigns/create', campaignDetails);

        // tracking this here instead of the store to track the type of campaign
        this.$track(CAMPAIGNS_EVENTS.CREATE_CAMPAIGN, {
          type: this.campaignType,
        });

        this.showAlert(this.$t('CAMPAIGN.ADD.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        const errorMessage =
          error?.response?.message || this.$t('CAMPAIGN.ADD.API.ERROR_MESSAGE');
        this.showAlert(errorMessage);
      }
    },
    async editCampaign() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      try {
        const campaignDetails = this.getCampaignDetails();
        await this.$store.dispatch('campaigns/update', {
          id: this.selectedCampaign.id,
          ...campaignDetails,
        });
        this.showAlert(this.$t('CAMPAIGN.EDIT.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        this.showAlert(this.$t('CAMPAIGN.EDIT.API.ERROR_MESSAGE'));
      }
    },
  },
};
</script>
<style lang="scss" scoped>
::v-deep .ProseMirror-woot-style {
  height: 5rem;
}

.message-editor {
  @apply px-3;

  ::v-deep {
    .ProseMirror-menubar {
      @apply rounded-tl-[4px];
    }
  }
}
</style>
