<script setup>
import { defineProps, ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import ChannelList from '../../../routes/dashboard/settings/inbox/ChannelList.vue';
import AddAgents from '../../../routes/dashboard/settings/inbox/AddAgents.vue';
import Whatsapp from '../../../routes/dashboard/settings/inbox/channels/Whatsapp.vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  stepNumber: {
    type: Number,
    required: true,
  },
  currentStep: {
    type: Number,
    required: true,
  },
});
const { t } = useI18n();

const store = useStore();

const channelSelectedFactory = ref({
  whatsapp: { component: Whatsapp, props: { disabledAutoRoute: true } },
});

const channelSelected = ref(null);
const inboxes = computed(() => store.getters['inboxes/getInboxes']);
const channelAlreadyCreated = computed(() => {
  return inboxes.value.length > 0;
});

const handleAgentsAdded = () => {
  useAlert(t('ONBOARDING.ADD_CHANNEL.CHANNEL_AGENTS_UPDATED'));
};
</script>

<template>
  <div>
    <div v-if="props.currentStep === props.stepNumber">
      <ChannelList
        v-if="!channelSelected && !channelAlreadyCreated"
        disabled-auto-route
        @channel-item-click="channelSelected = $event"
      />
      <div v-else>
        <component
          :is="channelSelectedFactory[channelSelected].component"
          v-if="!channelAlreadyCreated"
          v-bind="channelSelectedFactory[channelSelected].props"
        />
        <div v-else>
          <h2 class="text-lg font-semibold">
            {{
              $t('ONBOARDING.ADD_CHANNEL.ADDING_AGENTS', {
                channel: inboxes[0].channel_type.split('::')[1],
              })
            }}
          </h2>
          <AddAgents
            :inbox-id="inboxes[inboxes.length - 1].id"
            disabled-auto-route
            @agents-added="handleAgentsAdded"
          />
        </div>
      </div>
    </div>
  </div>
</template>
