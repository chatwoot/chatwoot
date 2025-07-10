<script setup>
import { onMounted, onBeforeUnmount } from 'vue';
import InboxReconnectionRequired from '../../components/InboxReconnectionRequired.vue';
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';
import { useWhatsappReauthorization } from 'dashboard/composables/useWhatsappReauthorization';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
});
const {
  processingMessage,
  showLoader,
  launchReauthorization,
  initialize,
  cleanupMessageListener,
} = useWhatsappReauthorization(props.inbox.id);

onMounted(() => {
  initialize();
});

onBeforeUnmount(() => {
  cleanupMessageListener();
});
</script>

<template>
  <div>
    <InboxReconnectionRequired
      class="mx-8 mt-5"
      @reauthorize="launchReauthorization"
    />
    <LoadingState v-if="showLoader" :message="processingMessage" />
  </div>
</template>
