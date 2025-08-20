<script setup>
import { defineProps, ref, computed, markRaw } from 'vue';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import ChannelList from '../../../routes/dashboard/settings/inbox/ChannelList.vue';
import AddAgents from '../../../routes/dashboard/settings/inbox/AddAgents.vue';
import Whatsapp from '../../../routes/dashboard/settings/inbox/channels/Whatsapp.vue';
import Instagram from '../../../routes/dashboard/settings/inbox/channels/Instagram.vue';
import { useI18n } from 'vue-i18n';
import { CUSTOM_EVENTS } from 'shared/constants/customEvents';

defineProps({
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

const channelSelected = ref(null);
const channelStep = ref('name'); // Track current step: 'name', 'qr', 'success'

const channelSelectedFactory = ref({
  whatsapp: {
    component: markRaw(Whatsapp),
    props: { disabledAutoRoute: true },
  },
  instagram: {
    component: markRaw(Instagram),
    props: { disabledAutoRoute: true },
  },
});

const inboxes = computed(() => store.getters['inboxes/getInboxes']);
const channelAlreadyCreated = computed(() => {
  return inboxes.value.length > 0;
});

// Channel is fully setup when it exists AND authentication is complete
const channelFullySetup = computed(() => {
  return channelAlreadyCreated.value && channelStep.value === 'success';
});

const showChannelList = computed(() => {
  return !channelSelected.value && !channelAlreadyCreated.value;
});

const handleStepChanged = (step) => {
  channelStep.value = step;
};

const handleAgentsAdded = () => {
  useAlert(t('ONBOARDING.ADD_CHANNEL.CHANNEL_AGENTS_UPDATED'));
};
</script>

<template>
  <div>
    <div v-if="currentStep === stepNumber">
      <ChannelList
        v-if="showChannelList"
        disabled-auto-route
        @[CUSTOM_EVENTS.ON_CHANNEL_ITEM_CLICK]="channelSelected = $event"
      />
      <div v-else>
        <component
          :is="channelSelectedFactory[channelSelected].component"
          v-if="!channelFullySetup"
          v-bind="channelSelectedFactory[channelSelected].props"
          @step-changed="handleStepChanged"
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
