<script setup>

import { computed } from 'vue';

import { useI18n } from 'vue-i18n';

import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

import { getInboxIconByType } from 'dashboard/helper/inbox';



import CardLayout from 'dashboard/components-next/CardLayout.vue';

import Button from 'dashboard/components-next/button/Button.vue';

import LiveChatCampaignDetails from './LiveChatCampaignDetails.vue';

import SMSCampaignDetails from './SMSCampaignDetails.vue';



const props = defineProps({

  title: {

    type: String,

    default: '',

  },

  message: {

    type: String,

    default: '',

  },

  isLiveChatType: {

    type: Boolean,

    default: false,

  },

  isEnabled: {

    type: Boolean,

    default: false,

  },

  status: {

    type: String,

    default: '',

  },

  sender: {

    type: Object,

    default: null,

  },

  inbox: {

    type: Object,

    default: null,

  },

  scheduledAt: {

    type: Number,

    default: 0,

  },

  executionStats: {

    type: Object,

    default: () => ({}),

  },

  clickable: {

    type: Boolean,

    default: false,

  },

  showAnalytics: {

    type: Boolean,

    default: false,

  },

});



const emit = defineEmits(['edit', 'delete', 'select', 'analytics']);



const { t } = useI18n();



const STATUS_COMPLETED = 'completed';

const STATUS_PROCESSING = 'processing';

const STATUS_DRAFT = 'draft';

const STATUS_ACTIVE = 'active';



const { formatMessage } = useMessageFormatter();



const isDraft = computed(() => props.status === STATUS_DRAFT);



const isActive = computed(() => {

  if (props.isLiveChatType) return props.isEnabled;

  return props.status !== STATUS_COMPLETED && props.status !== STATUS_DRAFT;

});



const statusTextColor = computed(() => ({

  'text-n-teal-11': isActive.value,

  'text-n-amber-11': isDraft.value,

  'text-n-slate-12': !isActive.value && !isDraft.value,

}));



const campaignStatus = computed(() => {

  if (props.isLiveChatType) {

    return props.isEnabled

      ? t('CAMPAIGN.LIVE_CHAT.CARD.STATUS.ENABLED')

      : t('CAMPAIGN.LIVE_CHAT.CARD.STATUS.DISABLED');

  }



  if (props.status === STATUS_DRAFT) {

    return t('CAMPAIGN.SMS.CARD.STATUS.DRAFT');

  }



  if (props.status === STATUS_COMPLETED) {

    return t('CAMPAIGN.SMS.CARD.STATUS.COMPLETED');

  }



  if (props.status === STATUS_PROCESSING) {

    return t('CAMPAIGN.SMS.CARD.STATUS.PROCESSING');

  }



  return t('CAMPAIGN.SMS.CARD.STATUS.SCHEDULED');

});



// One-off: edit draft + scheduled (active); not processing/completed

const showEditButton = computed(

  () =>

    props.isLiveChatType ||

    props.status === STATUS_DRAFT ||

    props.status === STATUS_ACTIVE

);



const inboxName = computed(() => props.inbox?.name || '');



const inboxIcon = computed(() => {

  const {

    medium,

    channel_type: type,

    voice_enabled: voiceEnabled,

  } = props.inbox;

  return getInboxIconByType(type, medium, 'fill', voiceEnabled);

});



const statsSummary = computed(() => {

  const stats = props.executionStats || {};

  if (!stats.audience_total && !stats.sent && !stats.failed) return '';

  const parts = [];

  if (stats.sent) {

    parts.push(t('CAMPAIGN.WHATSAPP.CARD.STATS.SENT', { count: stats.sent }));

  }

  if (stats.delivered) {

    parts.push(

      t('CAMPAIGN.WHATSAPP.CARD.STATS.DELIVERED', { count: stats.delivered })

    );

  }

  if (stats.read) {

    parts.push(t('CAMPAIGN.WHATSAPP.CARD.STATS.READ', { count: stats.read }));

  }

  if (stats.failed) {

    parts.push(

      t('CAMPAIGN.WHATSAPP.CARD.STATS.FAILED', { count: stats.failed })

    );

  }

  if (stats.skipped) {

    parts.push(

      t('CAMPAIGN.WHATSAPP.CARD.STATS.SKIPPED', { count: stats.skipped })

    );

  }

  const queuedCount = stats.queued || stats.pending;
  if (queuedCount) {

    parts.push(

      t('CAMPAIGN.WHATSAPP.CARD.STATS.PENDING', { count: queuedCount })

    );

  }

  return parts.join(' · ');

});

</script>



<template>

  <CardLayout

    layout="row"

    :class="{ 'cursor-pointer': clickable }"

    @click="() => clickable && emit('select')"

  >

    <div class="flex flex-col items-start justify-between flex-1 min-w-0 gap-2">

      <div class="flex justify-between gap-3 w-fit">

        <span

          class="text-base font-medium capitalize text-n-slate-12 line-clamp-1"

        >

          {{ title }}

        </span>

        <span

          class="text-xs font-medium inline-flex items-center h-6 px-2 py-0.5 rounded-md bg-n-alpha-2"

          :class="statusTextColor"

        >

          {{ campaignStatus }}

        </span>

      </div>

      <div

        v-dompurify-html="formatMessage(message, false, false, false)"

        class="text-sm text-n-slate-11 line-clamp-1 [&>p]:mb-0 h-6"

      />

      <div class="flex items-center w-full h-6 gap-2 overflow-hidden">

        <LiveChatCampaignDetails

          v-if="isLiveChatType"

          :sender="sender"

          :inbox-name="inboxName"

          :inbox-icon="inboxIcon"

        />

        <SMSCampaignDetails

          v-else

          :inbox-name="inboxName"

          :inbox-icon="inboxIcon"

          :scheduled-at="scheduledAt"

        />

      </div>

      <p v-if="statsSummary" class="text-xs text-n-slate-11 line-clamp-1">

        {{ statsSummary }}

      </p>

    </div>

    <div class="flex items-center justify-end w-20 gap-2" @click.stop>

      <Button

        v-if="showAnalytics"

        v-tooltip.top="t('CAMPAIGN.WHATSAPP.CARD.ANALYTICS')"

        variant="faded"

        size="sm"

        color="slate"

        icon="i-lucide-chart-no-axes-column"

        :title="t('CAMPAIGN.WHATSAPP.CARD.ANALYTICS')"

        @click="emit('analytics')"

      />

      <Button

        v-if="showEditButton"

        variant="faded"

        size="sm"

        color="slate"

        icon="i-lucide-sliders-vertical"

        @click="emit('edit')"

      />

      <Button

        variant="faded"

        color="ruby"

        size="sm"

        icon="i-lucide-trash"

        @click="emit('delete')"

      />

    </div>

  </CardLayout>

</template>


