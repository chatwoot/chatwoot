<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import camelcaseKeys from 'camelcase-keys';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import ConversationTicketAPI from 'dashboard/api/conversationTicket';

import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import TicketDueDate from './TicketDueDate.vue';
import TicketForm from './TicketForm.vue';
import TicketStatusChip from './TicketStatusChip.vue';
import TicketTaskList from './TicketTaskList.vue';
import { SETTLED_TICKET_CATEGORIES, TICKET_TASK_STATUS } from './constants';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();

const currentChat = useMapGetter('getSelectedChat');

const ticket = ref(null);
const isLoading = ref(false);
const isSaving = ref(false);
const isEditing = ref(false);
const isCreating = ref(false);

const isSettled = computed(() =>
  SETTLED_TICKET_CATEGORIES.includes(ticket.value?.statusCategory)
);

const typeLabel = computed(() =>
  ticket.value?.ticketType
    ? t(`TICKETS.TYPE.${ticket.value.ticketType.toUpperCase()}`)
    : ''
);

const waitingLabel = computed(() =>
  ticket.value?.waitingOn && ticket.value.waitingOn !== 'none'
    ? t(`TICKETS.WAITING_ON.${ticket.value.waitingOn.toUpperCase()}`)
    : ''
);

const alertError = (error, fallbackKey) => {
  const message = parseAPIErrorResponse(error);
  useAlert(typeof message === 'string' ? message : t(fallbackKey));
};

const setTicket = data => {
  ticket.value = camelcaseKeys(data, { deep: true });
};

const fetchTicket = async () => {
  isLoading.value = true;
  isEditing.value = false;
  isCreating.value = false;
  try {
    const { data } = await ConversationTicketAPI.getTicket(
      props.conversationId
    );
    setTicket(data);
  } catch (error) {
    // A conversation without a case answers 404; that is the empty state.
    if (error.response?.status === 404) {
      ticket.value = null;
    } else {
      alertError(error, 'TICKETS.PANEL.LOAD_ERROR');
    }
  } finally {
    isLoading.value = false;
  }
};

const createTicket = async payload => {
  isSaving.value = true;
  try {
    const { data } = await ConversationTicketAPI.createTicket(
      props.conversationId,
      payload
    );
    setTicket(data);
    isCreating.value = false;
  } catch (error) {
    alertError(error, 'TICKETS.PANEL.SAVE_ERROR');
  } finally {
    isSaving.value = false;
  }
};

const updateTicket = async payload => {
  isSaving.value = true;
  try {
    const { data } = await ConversationTicketAPI.updateTicket(
      props.conversationId,
      payload
    );
    setTicket(data);
    isEditing.value = false;
  } catch (error) {
    alertError(error, 'TICKETS.PANEL.SAVE_ERROR');
  } finally {
    isSaving.value = false;
  }
};

const createTask = async title => {
  try {
    const { data } = await ConversationTicketAPI.createTask(
      props.conversationId,
      { title }
    );
    const task = camelcaseKeys(data, { deep: true });
    ticket.value.tasks = [...ticket.value.tasks, task];
  } catch (error) {
    alertError(error, 'TICKETS.TASKS.SAVE_ERROR');
  }
};

const replaceTask = updated => {
  ticket.value.tasks = ticket.value.tasks.map(task =>
    task.id === updated.id ? updated : task
  );
};

const toggleTask = async task => {
  const nextStatus =
    task.status === TICKET_TASK_STATUS.DONE
      ? TICKET_TASK_STATUS.OPEN
      : TICKET_TASK_STATUS.DONE;
  // Optimistic: the checkbox has already flipped visually, so mirror it in state
  // and put the old task back if the write fails.
  replaceTask({ ...task, status: nextStatus });
  try {
    const { data } = await ConversationTicketAPI.updateTask(
      props.conversationId,
      task.id,
      { status: nextStatus }
    );
    replaceTask(camelcaseKeys(data, { deep: true }));
  } catch (error) {
    replaceTask(task);
    alertError(error, 'TICKETS.TASKS.SAVE_ERROR');
  }
};

const updateTaskOwner = async (task, owner) => {
  replaceTask({
    ...task,
    assigneeId: owner.assignee_id,
    teamId: owner.team_id,
  });
  try {
    const { data } = await ConversationTicketAPI.updateTask(
      props.conversationId,
      task.id,
      owner
    );
    replaceTask(camelcaseKeys(data, { deep: true }));
  } catch (error) {
    replaceTask(task);
    alertError(error, 'TICKETS.TASKS.SAVE_ERROR');
  }
};

const deleteTask = async task => {
  const previousTasks = ticket.value.tasks;
  ticket.value.tasks = previousTasks.filter(item => item.id !== task.id);
  try {
    await ConversationTicketAPI.deleteTask(props.conversationId, task.id);
  } catch (error) {
    ticket.value.tasks = previousTasks;
    alertError(error, 'TICKETS.TASKS.SAVE_ERROR');
  }
};

watch(() => props.conversationId, fetchTicket);
// The status category is derived from the conversation, so a resolve or reopen
// elsewhere in the dashboard has to be reflected here.
watch(
  () => currentChat.value?.status,
  () => {
    if (ticket.value) fetchTicket();
  }
);

onMounted(fetchTicket);
</script>

<template>
  <div class="flex flex-col gap-3 px-2 py-3">
    <div v-if="isLoading" class="flex items-center justify-center py-4">
      <Spinner :size="16" />
    </div>
    <template v-else-if="!ticket">
      <TicketForm
        v-if="isCreating"
        :is-saving="isSaving"
        show-cancel
        @submit="createTicket"
        @cancel="isCreating = false"
      />
      <div v-else class="flex flex-col items-start gap-2">
        <p class="mb-0 text-sm text-n-slate-11">
          {{ t('TICKETS.PANEL.EMPTY') }}
        </p>
        <Button
          size="sm"
          icon="i-lucide-plus"
          :label="t('TICKETS.PANEL.CREATE')"
          @click="isCreating = true"
        />
      </div>
    </template>
    <template v-else>
      <TicketForm
        v-if="isEditing"
        :ticket="ticket"
        :is-saving="isSaving"
        show-cancel
        @submit="updateTicket"
        @cancel="isEditing = false"
      />
      <div v-else class="flex flex-col gap-2">
        <div class="flex items-start justify-between gap-2">
          <TicketStatusChip :status-category="ticket.statusCategory" />
          <Button
            variant="ghost"
            color="slate"
            size="xs"
            icon="i-lucide-pencil"
            class="shrink-0 !h-6 !w-6"
            :aria-label="t('TICKETS.PANEL.EDIT')"
            @click="isEditing = true"
          />
        </div>
        <h4 class="mb-0 text-sm font-medium text-n-slate-12">
          {{ ticket.subject }}
        </h4>
        <dl class="grid grid-cols-[auto_1fr] gap-x-3 gap-y-1 mb-0 text-sm">
          <template v-if="typeLabel">
            <dt class="text-n-slate-11">{{ t('TICKETS.FORM.TYPE') }}</dt>
            <dd class="mb-0 text-n-slate-12">{{ typeLabel }}</dd>
          </template>
          <template v-if="waitingLabel">
            <dt class="text-n-slate-11">{{ t('TICKETS.FORM.WAITING_ON') }}</dt>
            <dd class="mb-0 text-n-slate-12">
              {{ waitingLabel }}
              <span v-if="ticket.waitingNote" class="text-n-slate-11">
                &middot; {{ ticket.waitingNote }}
              </span>
            </dd>
          </template>
          <template v-if="ticket.dueAt">
            <dt class="text-n-slate-11">{{ t('TICKETS.FORM.DUE_AT') }}</dt>
            <dd class="mb-0">
              <TicketDueDate :due-at="ticket.dueAt" :is-settled="isSettled" />
            </dd>
          </template>
        </dl>
      </div>
      <TicketTaskList
        :tasks="ticket.tasks"
        @toggle="toggleTask"
        @update-owner="updateTaskOwner"
        @delete="deleteTask"
        @create="createTask"
      />
    </template>
  </div>
</template>
