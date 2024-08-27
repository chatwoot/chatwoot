<template>
  <div
    class="px-5 py-4 mb-2 bg-white border rounded-md dark:bg-slate-800 border-slate-50 dark:border-slate-900"
  >
    <div class="flex flex-row items-start justify-between">
      <div class="flex flex-col">
        <div
          class="mb-1 -mt-1 text-base font-medium text-slate-900 dark:text-slate-100"
        >
          {{ title }}
        </div>
        <div
          v-dompurify-html="
            formatMessage(campaign.message || campaign.private_note)
          "
          class="text-sm line-clamp-1 [&>p]:mb-0"
        />
      </div>
      <div class="flex flex-row space-x-4">
        <woot-button
          v-if="campaign.campaign_status === 'active'"
          variant="link"
          icon="edit"
          color-scheme="secondary"
          size="small"
          @click="$emit('edit', campaign)"
        >
          {{ $t('CAMPAIGN.LIST.BUTTONS.EDIT') }}
        </woot-button>
        <woot-button
          variant="link"
          icon="dismiss-circle"
          size="small"
          color-scheme="secondary"
          @click="$emit('delete', campaign)"
        >
          {{ $t('CAMPAIGN.LIST.BUTTONS.DELETE') }}
        </woot-button>
      </div>
    </div>

    <div class="flex flex-row items-center mt-5 space-x-3">
      <woot-label
        small
        :title="campaignStatus"
        :color-scheme="colorScheme"
        class="mr-3 text-xs"
      />
      <inbox-name
        v-if="campaign.inbox"
        :inbox="campaign.inbox"
        class="mb-1 ltr:ml-0 rtl:mr-0"
      />
      <div v-if="campaign.inboxes" class="mb-1 ltr:ml-0 rtl:mr-0 text-xs">
        {{ inboxNames }}
      </div>
      <user-avatar-with-name
        v-if="campaign.sender"
        :user="campaign.sender"
        class="mb-1"
      />
      <div
        v-if="campaign.trigger_rules.url"
        class="w-1/4 mb-1 text-xs text-woot-600 text-truncate"
      >
        {{ campaign.trigger_rules.url }}
      </div>
      <div
        v-if="campaign.scheduled_at"
        class="mb-1 text-xs text-slate-700 dark:text-slate-500"
      >
        {{ formattedScheduledAt }}
      </div>
      <div
        v-if="campaign.flexible_scheduled_at"
        class="mb-1 text-xs text-slate-700 dark:text-slate-500"
      >
        {{ flexibleScheduledLabel }}
      </div>
    </div>
  </div>
</template>

<script>
import UserAvatarWithName from 'dashboard/components/widgets/UserAvatarWithName.vue';
import InboxName from 'dashboard/components/widgets/InboxName.vue';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import { format } from 'date-fns';
import campaignMixin from 'shared/mixins/campaignMixin';
import contactFilterItems from '../../contacts/contactFilterItems';

export default {
  components: {
    UserAvatarWithName,
    InboxName,
  },
  mixins: [messageFormatterMixin, campaignMixin],
  props: {
    campaign: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      // eslint-disable-next-line vue/no-unused-components
      contactFilterItems,
    };
  },
  computed: {
    title() {
      const campaignTitle = this.campaign.planned
        ? this.$t('CAMPAIGN.LIST.PLANNED.YES')
        : this.$t('CAMPAIGN.LIST.PLANNED.NO');

      return `${campaignTitle}: ${this.campaign.title}`;
    },
    formattedScheduledAt() {
      return format(new Date(this.campaign.scheduled_at), 'dd/MM/yyyy, HH:mm');
    },
    flexibleScheduledLabel() {
      let label = '';
      const schedule = this.campaign.flexible_scheduled_at;
      if (schedule.attribute.type === 'contact_attribute') {
        const attr = this.contactFilterItems.find(
          i => i.attributeKey === schedule.attribute.key
        );
        label = this.$t(`CONTACTS_FILTER.ATTRIBUTES.${attr.attributeI18nKey}`);
      } else {
        const attr = this.$store.getters['attributes/getAttributeByKey'](
          schedule.attribute.key
        );
        label = attr?.attribute_display_name;
      }

      let calName = '';
      const calculation = this.scheduledCalculations.find(
        i => i.key === schedule.calculation
      );
      if (schedule.calculation.startsWith('equal')) {
        calName = calculation.name;
      } else {
        calName = calculation.name.replace('x', schedule.extra_days);
      }

      return `${label} (${calName})`;
    },
    inboxNames() {
      return this.campaign.inboxes.map(item => item.name).join(', ');
    },
    campaignStatus() {
      if (this.campaign.campaign_status === 'completed') {
        return this.$t('CAMPAIGN.LIST.STATUS.COMPLETED');
      }

      return this.campaign.enabled
        ? this.$t('CAMPAIGN.LIST.STATUS.ENABLED')
        : this.$t('CAMPAIGN.LIST.STATUS.DISABLED');
    },
    colorScheme() {
      if (this.isOngoingType) {
        return this.campaign.enabled ? 'success' : 'secondary';
      }
      return this.campaign.campaign_status === 'completed'
        ? 'secondary'
        : 'success';
    },
  },
};
</script>
