<script setup>
import { computed, ref, onMounted, watch, defineOptions, provide } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useStoreGetters } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import LinearAPI from 'dashboard/api/integrations/linear';
import CreateOrLinkIssue from './CreateOrLinkIssue.vue';
import Issue from './Issue.vue';
import { useTrack } from 'dashboard/composables';
import { LINEAR_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { parseLinearAPIErrorResponse } from 'dashboard/store/utils/api';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
  parentWidth: {
    type: Number,
    default: 10000,
  },
});

defineOptions({
  name: 'Linear',
});

const getters = useStoreGetters();
const { t } = useI18n();

const linkedIssue = ref(null);
const shouldShow = ref(false);
const shouldShowPopup = ref(false);
const isUnlinking = ref(false);

provide('isUnlinking', isUnlinking);

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
    // We don't want to show an error message here, as it's not critical. When someone clicks on the Linear icon, we can inform them that the integration is disabled.
  }
};

const unlinkIssue = async linkId => {
  try {
    isUnlinking.value = true;
    await LinearAPI.unlinkIssue(linkId);
    useTrack(LINEAR_EVENTS.UNLINK_ISSUE);
    linkedIssue.value = null;
    useAlert(t('INTEGRATION_SETTINGS.LINEAR.UNLINK.SUCCESS'));
  } catch (error) {
    const errorMessage = parseLinearAPIErrorResponse(
      error,
      t('INTEGRATION_SETTINGS.LINEAR.UNLINK.ERROR')
    );
    useAlert(errorMessage);
  } finally {
    isUnlinking.value = false;
  }
};

const shouldShowIssueIdentifier = computed(() => {
  if (!linkedIssue.value) {
    return false;
  }

  return props.parentWidth > 600;
});

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

<template>
  <div
    class="relative after:content-[''] after:h-5 after:bg-transparent after:top-5 after:w-full after:block after:absolute after:z-0"
    :class="{ group: linkedIssue }"
  >
    <Button
      v-on-clickaway="closeIssue"
      v-tooltip="tooltipText"
      sm
      ghost
      slate
      class="!gap-1 group-hover:bg-n-alpha-2"
      @click="openIssue"
    >
      <fluent-icon
        icon="linear"
        size="19"
        class="text-[#5E6AD2] flex-shrink-0"
        view-box="0 0 19 19"
      />
      <span
        v-if="shouldShowIssueIdentifier"
        class="text-xs font-medium text-n-slate-11"
      >
        {{ linkedIssue.issue.identifier }}
      </span>
    </Button>
    <Issue
      v-if="linkedIssue"
      :issue="linkedIssue.issue"
      :link-id="linkedIssue.id"
      class="absolute rtl:left-0 ltr:right-0 top-9 invisible group-hover:visible"
      @unlink-issue="unlinkIssue"
    />
    <woot-modal
      v-model:show="shouldShowPopup"
      :on-close="closePopup"
      :close-on-backdrop-click="false"
      class="!items-start [&>div]:!top-12 [&>div]:sticky"
    >
      <CreateOrLinkIssue
        :conversation="conversation"
        :account-id="currentAccountId"
        @close="closePopup"
      />
    </woot-modal>
  </div>
</template>
