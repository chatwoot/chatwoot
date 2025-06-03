<script setup>
import { computed, ref, onMounted, watch } from 'vue';
import { format } from 'date-fns';
import { useAlert } from 'dashboard/composables';
import { useStoreGetters } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import LinearAPI from 'dashboard/api/integrations/linear';
import CreateOrLinkIssue from './CreateOrLinkIssue.vue';
import IssueHeader from './IssueHeader.vue';
import UserAvatarWithName from 'dashboard/components/widgets/UserAvatarWithName.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { useTrack } from 'dashboard/composables';
import { LINEAR_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { parseLinearAPIErrorResponse } from 'dashboard/store/utils/api';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();
const getters = useStoreGetters();

const linkedIssues = ref([]);
const isLoading = ref(false);
const isUnlinking = ref(false);
const shouldShowCreateModal = ref(false);

const currentAccountId = getters.getCurrentAccountId;

const conversation = computed(
  () => getters.getConversationById.value(props.conversationId) || {}
);

const priorityMap = {
  1: 'Urgent',
  2: 'High',
  3: 'Medium',
  4: 'Low',
};

const getFormattedDate = createdAt => {
  return format(new Date(createdAt), 'hh:mm a, MMM dd');
};

const getAssignee = issue => {
  const assigneeDetails = issue.assignee;
  if (!assigneeDetails) return null;
  const { name, avatarUrl } = assigneeDetails;
  return {
    name,
    thumbnail: avatarUrl,
  };
};

const getLabels = issue => {
  return issue.labels?.nodes || [];
};

const getPriorityLabel = priority => {
  return priorityMap[priority];
};

const loadLinkedIssues = async () => {
  isLoading.value = true;
  linkedIssues.value = [];
  try {
    const response = await LinearAPI.getLinkedIssue(props.conversationId);
    const issues = response.data;
    linkedIssues.value = issues || [];
  } catch (error) {
    // We don't want to show an error message here, as it's not critical
  } finally {
    isLoading.value = false;
  }
};

const unlinkIssue = async linkId => {
  try {
    isUnlinking.value = true;
    await LinearAPI.unlinkIssue(linkId);
    useTrack(LINEAR_EVENTS.UNLINK_ISSUE);
    linkedIssues.value = linkedIssues.value.filter(
      issue => issue.id !== linkId
    );
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

const hasIssues = computed(() => linkedIssues.value.length > 0);

const openCreateModal = () => {
  shouldShowCreateModal.value = true;
};

const closeCreateModal = () => {
  shouldShowCreateModal.value = false;
  loadLinkedIssues();
};

watch(
  () => props.conversationId,
  () => {
    loadLinkedIssues();
  }
);

onMounted(() => {
  loadLinkedIssues();
});
</script>

<template>
  <div class="space-y-3">
    <!-- Create or link button -->
    <Button
      ghost
      sm
      class="justify-start w-full gap-2 text-blue-500 hover:bg-blue-50 dark:hover:bg-blue-900/20"
      @click="openCreateModal"
    >
      <fluent-icon icon="add" size="16" />
      {{ $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK_BUTTON') }}
    </Button>

    <!-- Loading state -->
    <div v-if="isLoading" class="flex items-center justify-center py-4">
      <span class="text-sm">{{
        $t('INTEGRATION_SETTINGS.LINEAR.LOADING')
      }}</span>
      <Spinner class="size-5" />
    </div>

    <!-- Empty state -->
    <div v-else-if="!hasIssues" class="py-4 text-center">
      <p class="text-sm text-slate-600 dark:text-slate-400">
        {{ $t('INTEGRATION_SETTINGS.LINEAR.NO_LINKED_ISSUES') }}
      </p>
    </div>

    <!-- Issues list -->
    <div v-else class="space-y-3">
      <div
        v-for="linkedIssue in linkedIssues"
        :key="linkedIssue.id"
        class="flex flex-col items-start bg-n-alpha-3 backdrop-blur-[100px] px-4 py-3 border border-solid border-n-container rounded-xl gap-4"
      >
        <!-- Issue Header -->
        <div class="flex flex-col w-full">
          <IssueHeader
            :identifier="linkedIssue.issue.identifier"
            :link-id="linkedIssue.id"
            :issue-url="linkedIssue.issue.url"
            @unlink-issue="unlinkIssue"
          />

          <!-- Issue Title -->
          <span class="mt-2 text-sm font-medium text-n-slate-12">
            {{ linkedIssue.issue.title }}
          </span>

          <!-- Issue Description -->
          <span
            v-if="linkedIssue.issue.description"
            class="mt-1 text-sm text-n-slate-11 line-clamp-3"
          >
            {{ linkedIssue.issue.description }}
          </span>
        </div>

        <!-- Issue Metadata -->
        <div class="flex flex-row items-center h-6 gap-2">
          <!-- Assignee -->
          <UserAvatarWithName
            v-if="getAssignee(linkedIssue.issue)"
            :user="getAssignee(linkedIssue.issue)"
            class="py-1"
          />
          <div
            v-if="getAssignee(linkedIssue.issue)"
            class="w-px h-3 bg-n-slate-4"
          />

          <!-- Status -->
          <div class="flex items-center gap-1 py-1">
            <fluent-icon
              icon="status"
              size="14"
              :style="{ color: linkedIssue.issue.state?.color }"
            />
            <h6 class="text-xs text-n-slate-12">
              {{ linkedIssue.issue.state?.name }}
            </h6>
          </div>

          <!-- Priority -->
          <div
            v-if="getPriorityLabel(linkedIssue.issue.priority)"
            class="w-px h-3 bg-n-slate-4"
          />
          <div
            v-if="getPriorityLabel(linkedIssue.issue.priority)"
            class="flex items-center gap-1 py-1"
          >
            <fluent-icon
              :icon="`priority-${getPriorityLabel(linkedIssue.issue.priority).toLowerCase()}`"
              size="14"
              view-box="0 0 12 12"
            />
            <h6 class="text-xs text-n-slate-12">
              {{ getPriorityLabel(linkedIssue.issue.priority) }}
            </h6>
          </div>
        </div>

        <!-- Labels -->
        <div
          v-if="getLabels(linkedIssue.issue).length"
          class="flex flex-wrap items-center gap-1"
        >
          <woot-label
            v-for="label in getLabels(linkedIssue.issue)"
            :key="label.id"
            :title="label.name"
            :description="label.description"
            :color="label.color"
            variant="smooth"
            small
          />
        </div>

        <!-- Created Date -->
        <div class="flex items-center">
          <span class="text-xs text-n-slate-11">
            {{
              $t('INTEGRATION_SETTINGS.LINEAR.ISSUE.CREATED_AT', {
                createdAt: getFormattedDate(linkedIssue.issue.createdAt),
              })
            }}
          </span>
        </div>
      </div>
    </div>

    <woot-modal
      v-model:show="shouldShowCreateModal"
      :on-close="closeCreateModal"
      :close-on-backdrop-click="false"
      class="!items-start [&>div]:!top-12 [&>div]:sticky"
    >
      <CreateOrLinkIssue
        :conversation="conversation"
        :account-id="currentAccountId"
        @close="closeCreateModal"
      />
    </woot-modal>
  </div>
</template>
