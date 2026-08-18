<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import TicketDueDate from './TicketDueDate.vue';
import TicketStatusChip from './TicketStatusChip.vue';
import { SETTLED_TICKET_CATEGORIES } from './constants';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';

defineProps({
  tickets: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  noDataMessage: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['open']);

const { t } = useI18n();

const headers = computed(() => [
  t('TICKETS.TABLE.NUMBER'),
  t('TICKETS.TABLE.SUBJECT'),
  t('TICKETS.TABLE.TYPE'),
  t('TICKETS.TABLE.STATUS'),
  t('TICKETS.TABLE.WAITING_ON'),
  t('TICKETS.TABLE.DUE_AT'),
  t('TICKETS.TABLE.ASSIGNEE'),
  t('TICKETS.TABLE.UPDATED_AT'),
]);

const isSettled = ticket =>
  SETTLED_TICKET_CATEGORIES.includes(ticket.statusCategory);

const typeLabel = ticket =>
  ticket.ticketType
    ? t(`TICKETS.TYPE.${ticket.ticketType.toUpperCase()}`)
    : '—';

const waitingLabel = ticket =>
  ticket.waitingOn && ticket.waitingOn !== 'none'
    ? t(`TICKETS.WAITING_ON.${ticket.waitingOn.toUpperCase()}`)
    : '—';

const updatedLabel = ticket =>
  dynamicTime(Math.floor(new Date(ticket.updatedAt).getTime() / 1000));
</script>

<template>
  <div class="w-full min-w-0 overflow-x-auto">
    <BaseTable
      :headers="headers"
      :items="tickets"
      :loading="isLoading"
      :no-data-message="noDataMessage"
    >
      <template #row="{ items }">
        <BaseTableRow
          v-for="ticket in items"
          :key="ticket.id"
          :item="ticket"
          class="cursor-pointer hover:bg-n-alpha-1"
          @click="emit('open', ticket)"
        >
          <BaseTableCell>
            <span class="tabular-nums text-n-slate-11">
              #{{ ticket.conversationId }}
            </span>
          </BaseTableCell>
          <BaseTableCell>
            <span
              class="block max-w-96 truncate text-n-slate-12"
              :title="ticket.subject"
            >
              {{ ticket.subject }}
            </span>
          </BaseTableCell>
          <BaseTableCell>
            <span class="whitespace-nowrap">{{ typeLabel(ticket) }}</span>
          </BaseTableCell>
          <BaseTableCell>
            <TicketStatusChip :status-category="ticket.statusCategory" />
          </BaseTableCell>
          <BaseTableCell>
            <span class="whitespace-nowrap">{{ waitingLabel(ticket) }}</span>
          </BaseTableCell>
          <BaseTableCell>
            <TicketDueDate
              :due-at="ticket.dueAt"
              :is-settled="isSettled(ticket)"
            />
          </BaseTableCell>
          <BaseTableCell>
            <div
              v-if="ticket.assignee"
              class="flex items-center gap-2 whitespace-nowrap"
            >
              <Avatar
                :src="ticket.assignee.thumbnail"
                :name="ticket.assignee.name"
                :size="20"
                rounded-full
              />
              <span class="text-n-slate-12">{{ ticket.assignee.name }}</span>
            </div>
            <span v-else>—</span>
          </BaseTableCell>
          <BaseTableCell>
            <span class="whitespace-nowrap">{{ updatedLabel(ticket) }}</span>
          </BaseTableCell>
        </BaseTableRow>
      </template>
    </BaseTable>
  </div>
</template>
