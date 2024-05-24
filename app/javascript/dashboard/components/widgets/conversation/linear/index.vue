<template>
  <div class="relative" :class="{ group: linkedIssue }">
    <woot-button
      v-on-clickaway="closeIssue"
      v-tooltip="tooltipText"
      variant="clear"
      color-scheme="secondary"
      @click="openIssue"
    >
      <fluent-icon
        icon="linear"
        size="19"
        class="text-[#5E6AD2]"
        view-box="0 0 19 19"
      />
      <span v-if="linkedIssue" class="text-xs font-medium text-ash-800">
        {{ linkedIssue.issue.identifier }}
      </span>
    </woot-button>
    <issue
      v-if="linkedIssue"
      :issue="linkedIssue.issue"
      :link-id="linkedIssue.id"
      class="absolute right-0 top-[40px] invisible group-hover:visible"
      @unlink-issue="unlinkIssue"
    />
    <woot-modal
      :show.sync="shouldShowPopup"
      :on-close="closePopup"
      class="!items-start [&>div]:!top-12"
    >
      <create-or-link-issue
        :conversation="conversation"
        :account-id="currentAccountId"
        @close="closePopup"
      />
    </woot-modal>
  </div>
</template>

<script setup>
import { computed, ref, onMounted, watch } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useStoreGetters } from 'dashboard/composables/store';
import { useI18n } from 'dashboard/composables/useI18n';
import LinearAPI from 'dashboard/api/integrations/linear';
import CreateOrLinkIssue from './CreateOrLinkIssue.vue';
import Issue from './Issue.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const getters = useStoreGetters();
const { t } = useI18n();

const linkedIssue = ref(null);
const shouldShow = ref(false);
const shouldShowPopup = ref(false);

const currentAccountId = getters.getCurrentAccountId;

const conversation = computed(() =>
  getters.getConversationById.value(props.conversationId)
);

const tooltipText = computed(() => {
  return linkedIssue.value === null
    ? t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK_BUTTON')
    : null;
});

const loadLinkedIssue = async () => {
  linkedIssue.value = null;
  try {
    const response = await LinearAPI.getLinkedIssue(props.conversationId);
    const issues = response.data;
    linkedIssue.value = issues && issues.length ? issues[0] : null;
  } catch (error) {
    useAlert(error?.message || t('INTEGRATION_SETTINGS.LINEAR.LOADING_ERROR'));
  }
};

const unlinkIssue = async linkId => {
  try {
    await LinearAPI.unlinkIssue(linkId);
    linkedIssue.value = null;
    useAlert(t('INTEGRATION_SETTINGS.LINEAR.UNLINK.SUCCESS'));
  } catch (error) {
    useAlert(t('INTEGRATION_SETTINGS.LINEAR.UNLINK.ERROR'));
  }
};

const openIssue = () => {
  if (!linkedIssue.value) shouldShowPopup.value = true;
  shouldShow.value = true;
};

const closePopup = () => {
  shouldShowPopup.value = false;
  loadLinkedIssue();
};

const closeIssue = () => {
  shouldShow.value = false;
};

watch(
  () => props.conversationId,
  () => {
    loadLinkedIssue();
  }
);

onMounted(() => {
  loadLinkedIssue();
});
</script>
