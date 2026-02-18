<script setup>
import { computed, onMounted, onBeforeUnmount, ref, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import leadFollowUpSequencesAPI from 'dashboard/api/leadFollowUpSequences';
import Button from 'dashboard/components-next/button/Button.vue';
import SettingIntroBanner from 'dashboard/components/widgets/SettingIntroBanner.vue';

const { t } = useI18n();
const router = useRouter();
const route = useRoute();

const sequence = ref(null);
const loading = ref(false);
const enrolledConversations = ref([]);
const enrolledLoading = ref(false);
const statusFilter = ref(null);
const statusCounts = ref({});
const selectedFollowUps = ref([]);
const cancellingFollowUps = ref(false);
const totalSteps = ref(0);

const goBack = () => {
  router.push({ name: 'copilots_list' });
};

const goToEdit = () => {
  router.push({
    name: 'copilots_edit',
    params: { sequenceId: route.params.sequenceId },
  });
};

const goToConversation = displayId => {
  router.push({
    name: 'inbox_conversation',
    params: { conversation_id: displayId },
  });
};

const goToContact = contactId => {
  router.push({
    name: 'contacts_edit',
    params: { contactId },
  });
};

const fetchSequence = async () => {
  try {
    loading.value = true;
    const response = await leadFollowUpSequencesAPI.show(
      route.params.sequenceId
    );
    sequence.value = response.data;
  } catch (error) {
    useAlert('Error al cargar el copilot');
    goBack();
  } finally {
    loading.value = false;
  }
};

const fetchEnrolledConversations = async () => {
  enrolledLoading.value = true;
  try {
    const response = await leadFollowUpSequencesAPI.getEnrolledConversations(
      route.params.sequenceId,
      { status: statusFilter.value }
    );
    enrolledConversations.value = response.data.enrolled_conversations;
    statusCounts.value = response.data.status_counts;
    totalSteps.value = response.data.total_steps || 0;
  } catch (error) {
    console.error('Error fetching enrolled conversations:', error);
    useAlert('Error al cargar conversaciones');
  } finally {
    enrolledLoading.value = false;
  }
};

const totalEnrolled = computed(() => {
  return Object.values(statusCounts.value).reduce(
    (sum, count) => sum + count,
    0
  );
});

const getStatusColor = status => {
  const colors = {
    active: 'bg-n-blue-3 text-n-blue-11 dark:bg-n-blue-3 dark:text-n-blue-11',
    paused:
      'bg-n-amber-3 text-n-amber-11 dark:bg-n-amber-3 dark:text-n-amber-11',
    completed:
      'bg-n-teal-3 text-n-teal-11 dark:bg-n-teal-3 dark:text-n-teal-11',
    cancelled:
      'bg-n-slate-3 text-n-slate-11 dark:bg-n-slate-3 dark:text-n-slate-11',
    failed: 'bg-n-ruby-3 text-n-ruby-11 dark:bg-n-ruby-3 dark:text-n-ruby-11',
  };
  return colors[status] || 'bg-n-slate-3 text-n-slate-11';
};

const getStatusLabel = status => {
  return t(`LEAD_RETARGETING.SHOW.STATUS.${status}`) || status;
};

const formatNextAction = (nextActionAt, status) => {
  if (status === 'completed' || status === 'cancelled' || status === 'failed') {
    return '-';
  }

  if (!nextActionAt) return t('LEAD_RETARGETING.SHOW.NEXT_ACTION.NOT_SCHEDULED');
  const date = new Date(nextActionAt);
  const now = new Date();
  const diffMs = date - now;
  const diffMins = Math.floor(diffMs / 60000);

  if (diffMins < 0) return t('LEAD_RETARGETING.SHOW.NEXT_ACTION.PENDING');
  if (diffMins < 60)
    return t('LEAD_RETARGETING.SHOW.NEXT_ACTION.IN_MINS', { count: diffMins });

  const diffHours = Math.floor(diffMins / 60);
  if (diffHours < 24)
    return t('LEAD_RETARGETING.SHOW.NEXT_ACTION.IN_HOURS', { count: diffHours });

  const diffDays = Math.floor(diffHours / 24);
  return t('LEAD_RETARGETING.SHOW.NEXT_ACTION.IN_DAYS', { count: diffDays });
};

const formatDate = dateString => {
  if (!dateString) return '-';
  const date = new Date(dateString);
  return date.toLocaleString('es-ES', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

const formatPhoneNumber = phoneNumber => {
  if (!phoneNumber) return '';
  // Mexico logic: If it starts with +521 and has 13/14 characters
  if (phoneNumber.startsWith('+521')) {
    const cleaned = phoneNumber.replace('+521', '');
    if (cleaned.length === 10) {
      return `+52 1 ${cleaned.slice(0, 2)} ${cleaned.slice(2, 6)} ${cleaned.slice(6)}`;
    }
  }
  return phoneNumber;
};

const getStepTypeName = type => {
  const typeNames = {
    wait: t('LEAD_RETARGETING.STEPS.WAIT.ADD'),
    send_message: t('LEAD_RETARGETING.STEPS.SEND_MESSAGE.ADD'),
    add_label: t('LEAD_RETARGETING.STEPS.ADD_LABEL.ADD'),
    remove_label: t('LEAD_RETARGETING.STEPS.REMOVE_LABEL.ADD'),
    assign_agent: t('LEAD_RETARGETING.STEPS.ASSIGN_AGENT.ADD'),
    assign_team: t('LEAD_RETARGETING.STEPS.ASSIGN_TEAM.ADD'),
    condition: t('LEAD_RETARGETING.STEPS.CONDITION.ADD'),
    webhook: t('LEAD_RETARGETING.STEPS.WEBHOOK.ADD'),
    change_priority: t('LEAD_RETARGETING.STEPS.CHANGE_PRIORITY.ADD'),
    update_pipeline_status: t(
      'LEAD_RETARGETING.STEPS.UPDATE_PIPELINE_STATUS.ADD'
    ),
    send_email: t('LEAD_RETARGETING.STEPS.SEND_EMAIL.ADD'),
    first_contact: t('LEAD_RETARGETING.STEPS.FIRST_CONTACT.ADD'),
  };
  return typeNames[type] || type;
};

const getStopReason = (item) => {
  const { status, completion_reason: completionReason, metadata } = item;

  if (status === 'completed' || status === 'cancelled') {
    if (!completionReason) return null;

    const exactReasons = {
      'Contact replied': t('LEAD_RETARGETING.SHOW.STOP_REASONS.CONTACT_REPLIED'),
      'Conversation resolved': t('LEAD_RETARGETING.SHOW.STOP_REASONS.CONVERSATION_RESOLVED'),
      'All steps completed': t('LEAD_RETARGETING.SHOW.STOP_REASONS.ALL_STEPS_COMPLETED'),
      'Condition branch: complete': t('LEAD_RETARGETING.SHOW.STOP_REASONS.CONDITION_MET'),
      'Copilot deactivated': t('LEAD_RETARGETING.SHOW.STOP_REASONS.COPILOT_DEACTIVATED'),
      'Manually cancelled by user': t('LEAD_RETARGETING.SHOW.STOP_REASONS.MANUALLY_CANCELLED'),
    };

    if (exactReasons[completionReason]) return exactReasons[completionReason];

    // Razones dinámicas (incluyen nombre del agente)
    if (completionReason.startsWith('Agent assigned:')) {
      return t('LEAD_RETARGETING.SHOW.STOP_REASONS.AGENT_ASSIGNED', { name: completionReason.replace('Agent assigned: ', '') });
    }
    if (completionReason.startsWith('Agent replied:')) {
      return t('LEAD_RETARGETING.SHOW.STOP_REASONS.AGENT_REPLIED', { name: completionReason.replace('Agent replied: ', '') });
    }

    return completionReason;
  }

  if (status === 'failed') {
    return metadata?.failure_reason || null;
  }

  return null;
};

const toggleSelectAll = () => {
  if (selectedFollowUps.value.length === enrolledConversations.value.length) {
    selectedFollowUps.value = [];
  } else {
    selectedFollowUps.value = enrolledConversations.value
      .filter(item => item.status === 'active')
      .map(item => item.id);
  }
};

const toggleSelect = followUpId => {
  const index = selectedFollowUps.value.indexOf(followUpId);
  if (index > -1) {
    selectedFollowUps.value.splice(index, 1);
  } else {
    selectedFollowUps.value.push(followUpId);
  }
};

const cancelSelectedFollowUps = async () => {
  if (selectedFollowUps.value.length === 0) {
    useAlert('Selecciona al menos un follow-up para cancelar');
    return;
  }

  if (
    !confirm(
      `¿Estás seguro de cancelar ${selectedFollowUps.value.length} follow-up(s)?`
    )
  ) {
    return;
  }

  try {
    cancellingFollowUps.value = true;
    await leadFollowUpSequencesAPI.cancelFollowUps(
      route.params.sequenceId,
      selectedFollowUps.value
    );
    useAlert('Follow-ups cancelados exitosamente');
    selectedFollowUps.value = [];
    await fetchEnrolledConversations();
  } catch (error) {
    console.error('Error cancelling follow-ups:', error);
    useAlert('Error al cancelar follow-ups');
  } finally {
    cancellingFollowUps.value = false;
  }
};

const resetData = () => {
  sequence.value = null;
  enrolledConversations.value = [];
  statusFilter.value = null;
  statusCounts.value = {};
  selectedFollowUps.value = [];
  totalSteps.value = 0;
};

const loadData = async () => {
  await fetchSequence();
  await fetchEnrolledConversations();
};

onMounted(async () => {
  await loadData();
});

// Watch para cambios en el sequenceId de la ruta
watch(
  () => route.params.sequenceId,
  async (newId, oldId) => {
    if (newId && newId !== oldId) {
      resetData();
      await loadData();
    }
  }
);

onBeforeUnmount(() => {
  resetData();
});
</script>

<template>
  <div
    class="overflow-auto flex-grow flex-shrink pr-0 pl-0 w-full min-w-0 settings"
  >
    <SettingIntroBanner :header-title="t('LEAD_RETARGETING.SHOW.HEADER')">
      <button
        class="flex items-center gap-1 text-n-slate-11 hover:text-n-slate-12 text-sm mb-4"
        @click="goBack"
      >
        <i class="i-lucide-arrow-left text-base" />
        {{ t('LEAD_RETARGETING.SHOW.BACK_TO_LIST') }}
      </button>
    </SettingIntroBanner>

    <section v-if="loading" class="mx-auto w-full max-w-6xl">
      <div class="flex items-center justify-center py-20">
        <i class="i-lucide-loader-2 animate-spin text-4xl text-n-blue-11" />
      </div>
    </section>

    <section v-else-if="sequence" class="mx-auto w-full max-w-6xl">
      <div class="mx-8 space-y-6">
        <!-- Header Actions -->
        <div class="flex items-center justify-between">
          <div>
            <h2 class="text-xl font-semibold text-n-slate-12">
              {{ sequence.name }}
            </h2>
            <p v-if="sequence.description" class="text-sm text-n-slate-11 mt-1">
              {{ sequence.description }}
            </p>
            <!-- Badge de auto-desactivación -->
            <div
              v-if="
                !sequence.active &&
                sequence.metadata?.auto_deactivation_reason ===
                  'all_conversations_completed'
              "
              class="mt-2"
            >
              <span
                class="inline-flex items-center gap-1.5 px-2.5 py-1 bg-n-teal-2 dark:bg-n-teal-3 text-n-teal-11 rounded-md text-xs font-medium"
                :title="
                  t('LEAD_RETARGETING.SHOW.AUTO_DEACTIVATED_AT', {
                    date: formatDate(sequence.metadata.auto_deactivated_at),
                  })
                "
              >
                <i class="i-lucide-check-circle text-sm" />
                {{ t('LEAD_RETARGETING.SHOW.AUTO_DEACTIVATED_DESC') }}
              </span>
            </div>
          </div>
          <div class="flex gap-2">
            <Button
              slate
              faded
              icon="i-lucide-refresh-cw"
              :class="{ 'animate-spin': enrolledLoading }"
              @click="fetchEnrolledConversations"
            />
            <Button
              slate
              faded
              :label="t('LEAD_RETARGETING.SHOW.EDIT')"
              icon="i-lucide-pencil"
              @click="goToEdit"
            />
            <span
              class="px-3 py-2 rounded-lg text-sm font-medium"
              :class="
                sequence.active
                  ? 'bg-n-teal-3 text-n-teal-11'
                  : 'bg-n-slate-3 text-n-slate-11'
              "
            >
              {{
                sequence.active
                  ? t('LEAD_RETARGETING.STATUS.ACTIVE')
                  : t('LEAD_RETARGETING.STATUS.INACTIVE')
              }}
            </span>
          </div>
        </div>

        <!-- Stats Cards -->
        <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
          <div
            class="p-4 bg-n-slate-2 dark:bg-n-slate-3 rounded-lg border border-n-weak/60"
          >
            <p class="text-xs text-n-slate-11 mb-1">
              {{ t('LEAD_RETARGETING.SHOW.TOTAL_STATS') }}
            </p>
            <p class="text-2xl font-bold text-n-slate-12">
              {{ totalEnrolled }}
            </p>
          </div>
          <button
            v-for="(count, status) in statusCounts"
            :key="status"
            class="p-4 rounded-lg border transition-all hover:scale-105"
            :class="[
              statusFilter === status
                ? 'border-n-blue-9 bg-n-blue-2 dark:bg-n-blue-3'
                : 'border-n-weak/60 bg-n-slate-2 dark:bg-n-slate-3 hover:border-n-blue-6',
            ]"
            @click="
              statusFilter = statusFilter === status ? null : status;
              fetchEnrolledConversations();
            "
          >
            <p class="text-xs text-n-slate-11 mb-1">
              {{ getStatusLabel(status) }}
            </p>
            <p class="text-2xl font-bold text-n-slate-12">{{ count }}</p>
          </button>
        </div>

        <!-- Enrolled Conversations List -->
        <div
          class="bg-white dark:bg-n-slate-2 rounded-lg border border-n-weak/60"
        >
          <div class="p-4 border-b border-n-weak/60">
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-3">
                <h3 class="text-lg font-semibold text-n-slate-12">
                  {{ t('LEAD_RETARGETING.SHOW.ENROLLED_CONVERSATIONS') }}
                </h3>
                <span
                  v-if="selectedFollowUps.length > 0"
                  class="text-xs px-2 py-1 bg-n-blue-3 text-n-blue-11 rounded-full"
                >
                  {{
                    t('LEAD_RETARGETING.SHOW.ENROLLED_TABLE.SELECTED_COUNT', {
                      count: selectedFollowUps.length,
                    })
                  }}
                </span>
              </div>
              <div class="flex items-center gap-2">
                <Button
                  v-if="selectedFollowUps.length > 0"
                  ruby
                  faded
                  xs
                  icon="i-lucide-x-circle"
                  :label="
                    t('LEAD_RETARGETING.SHOW.ENROLLED_TABLE.CANCEL_SELECTED')
                  "
                  :loading="cancellingFollowUps"
                  @click="cancelSelectedFollowUps"
                />
                <button
                  v-if="statusFilter"
                  class="text-xs text-n-blue-11 hover:text-n-blue-12"
                  @click="
                    statusFilter = null;
                    fetchEnrolledConversations();
                  "
                >
                  {{ t('LEAD_RETARGETING.SHOW.ENROLLED_TABLE.CLEAR_FILTER') }}
                </button>
              </div>
            </div>
          </div>

          <div
            v-if="enrolledLoading"
            class="flex items-center justify-center py-20"
          >
            <i class="i-lucide-loader-2 animate-spin text-3xl text-n-blue-11" />
          </div>

          <div
            v-else-if="enrolledConversations.length === 0"
            class="py-20 text-center"
          >
            <i class="i-lucide-inbox text-4xl text-n-slate-11 mb-2" />
            <p class="text-n-slate-11">
              {{
                statusFilter
                  ? t(
                      'LEAD_RETARGETING.SHOW.ENROLLED_TABLE.NO_CONVERSATIONS_FOUND'
                    )
                  : t(
                      'LEAD_RETARGETING.SHOW.ENROLLED_TABLE.NO_CONVERSATIONS_ENROLLED'
                    )
              }}
            </p>
          </div>

          <div v-else class="overflow-x-auto">
            <table class="w-full">
              <thead class="bg-n-slate-2 dark:bg-n-slate-3">
                <tr>
                  <th
                    class="px-4 py-3 text-center text-xs font-medium text-n-slate-11 w-12"
                  >
                    <input
                      type="checkbox"
                      class="w-4 h-4 rounded border-gray-300 dark:border-gray-600 text-blue-600 focus:ring-blue-500 dark:focus:ring-blue-600 cursor-pointer"
                      :checked="
                        selectedFollowUps.length > 0 &&
                        selectedFollowUps.length ===
                          enrolledConversations.filter(
                            c => c.status === 'active'
                          ).length
                      "
                      @change="toggleSelectAll"
                    />
                  </th>
                  <th
                    class="px-4 py-3 text-left text-xs font-medium text-n-slate-11"
                  >
                    {{ t('LEAD_RETARGETING.SHOW.ENROLLED_TABLE.CONTACT') }}
                  </th>
                  <th
                    class="px-4 py-3 text-left text-xs font-medium text-n-slate-11"
                  >
                    {{ t('LEAD_RETARGETING.SHOW.ENROLLED_TABLE.CONV_ID') }}
                  </th>
                  <th
                    class="px-4 py-3 text-left text-xs font-medium text-n-slate-11"
                  >
                    {{ t('LEAD_RETARGETING.SHOW.ENROLLED_TABLE.STATUS') }}
                  </th>
                  <th
                    class="px-4 py-3 text-left text-xs font-medium text-n-slate-11"
                  >
                    {{ t('LEAD_RETARGETING.SHOW.ENROLLED_TABLE.STEP') }}
                  </th>
                  <th
                    class="px-4 py-3 text-left text-xs font-medium text-n-slate-11"
                  >
                    {{ t('LEAD_RETARGETING.SHOW.ENROLLED_TABLE.NEXT_ACTION') }}
                  </th>
                  <th
                    class="px-4 py-3 text-left text-xs font-medium text-n-slate-11"
                  >
                    {{ t('LEAD_RETARGETING.SHOW.ENROLLED_TABLE.STOP_REASON') }}
                  </th>
                  <th
                    class="px-4 py-3 text-left text-xs font-medium text-n-slate-11"
                  >
                    {{ t('LEAD_RETARGETING.SHOW.ENROLLED_TABLE.RE_ENROLLMENTS') }}
                  </th>
                  <th
                    class="px-4 py-3 text-left text-xs font-medium text-n-slate-11"
                  >
                    {{ t('LEAD_RETARGETING.SHOW.ENROLLED_TABLE.ENROLLED') }}
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-n-weak/60">
                <tr
                  v-for="item in enrolledConversations"
                  :key="item.id"
                  class="hover:bg-n-slate-2 dark:hover:bg-n-slate-3 transition-colors"
                >
                  <td class="px-4 py-3 text-center">
                    <input
                      v-if="item.status === 'active'"
                      type="checkbox"
                      class="w-4 h-4 rounded border-gray-300 dark:border-gray-600 text-blue-600 focus:ring-blue-500 dark:focus:ring-blue-600 cursor-pointer"
                      :checked="selectedFollowUps.includes(item.id)"
                      @change="toggleSelect(item.id)"
                    />
                    <span v-else class="text-n-slate-11">-</span>
                  </td>
                  <td class="px-4 py-3">
                    <button
                      class="text-left hover:opacity-80 transition-opacity"
                      @click="goToContact(item.contact?.id)"
                    >
                      <p
                        class="text-sm font-medium text-n-blue-11 hover:text-n-blue-12"
                      >
                        {{ item.contact?.name || 'Sin nombre' }}
                      </p>
                      <p class="text-xs text-n-slate-11">
                        {{
                          formatPhoneNumber(item.contact?.phone_number) ||
                          t('LEAD_RETARGETING.SHOW.ENROLLMENT.NO_PHONE')
                        }}
                      </p>
                    </button>
                  </td>
                  <td class="px-4 py-3">
                    <button
                      class="text-xs px-2 py-1 bg-n-weak/60 rounded font-mono hover:bg-n-blue-3 hover:text-n-blue-11 transition-colors"
                      @click="goToConversation(item.display_id)"
                    >
                      #{{ item.display_id }}
                    </button>
                  </td>
                  <td class="px-4 py-3">
                    <span
                      class="text-xs px-2 py-1 rounded font-medium"
                      :class="getStatusColor(item.status)"
                    >
                      {{ getStatusLabel(item.status) }}
                    </span>
                  </td>
                  <td class="px-4 py-3">
                    <div>
                      <p class="text-sm font-medium text-n-slate-12">
                        {{ item.current_step + 1 }}/{{ totalSteps }}
                      </p>
                      <p
                        v-if="item.current_step_type"
                        class="text-xs text-n-slate-11"
                      >
                        {{ getStepTypeName(item.current_step_type) }}
                      </p>
                      <p
                        v-if="item.metadata?.last_error"
                        class="text-xs text-n-ruby-11 mt-1"
                      >
                        Error: {{ item.metadata.last_error }}
                      </p>
                    </div>
                  </td>
                  <td class="px-4 py-3">
                    <div>
                      <p class="text-sm text-n-slate-12">
                        {{ formatNextAction(item.next_action_at, item.status) }}
                      </p>
                      <p
                        v-if="item.next_action_at && item.status === 'active'"
                        class="text-xs text-n-slate-11"
                      >
                        {{ formatDate(item.next_action_at) }}
                      </p>
                    </div>
                  </td>
                  <td class="px-4 py-3">
                    <p
                      v-if="getStopReason(item)"
                      class="text-xs text-n-slate-11"
                    >
                      {{ getStopReason(item) }}
                    </p>
                    <span v-else class="text-xs text-n-slate-11">-</span>
                  </td>
                  <td class="px-4 py-3">
                    <div
                      v-if="item.metadata?.re_enrollment_count > 0"
                      class="flex items-center gap-1.5"
                    >
                      <span
                        class="inline-flex items-center gap-1 px-2 py-0.5 bg-n-iris-2 dark:bg-n-iris-3 text-n-iris-11 rounded text-xs font-medium"
                      >
                        <i class="i-lucide-refresh-ccw text-xs" />
                        {{ item.metadata.re_enrollment_count }}x
                      </span>
                      <button
                        v-if="item.metadata?.previous_completion"
                        class="text-xs text-n-slate-11 hover:text-n-slate-12"
                        :title="
                          t('LEAD_RETARGETING.SHOW.ENROLLMENT.LAST_COMPLETION', {
                            date: formatDate(item.metadata.previous_completion),
                          })
                        "
                      >
                        <i class="i-lucide-info text-xs" />
                      </button>
                    </div>
                    <span v-else class="text-xs text-n-slate-11">
                      {{ t('LEAD_RETARGETING.SHOW.ENROLLMENT.FIRST_TIME') }}
                    </span>
                  </td>
                  <td class="px-4 py-3">
                    <p class="text-xs text-n-slate-11">
                      {{ formatDate(item.created_at) }}
                    </p>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>
