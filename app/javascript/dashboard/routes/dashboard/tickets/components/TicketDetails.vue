<template>
  <section class="ticket-page bg-white dark:bg-slate-900">
    <div class="flex flex-col w-full">
      <div
        class="flex items-center justify-between py-4 px-4 pb-3 border-b border-slate-75 dark:border-slate-700"
      >
        <h1
          class="text-xl break-words overflow-hidden whitespace-nowrap text-ellipsis text-black-900 dark:text-slate-100 mb-0"
          title="Tickets"
        >
          {{ $t('TICKETS.TITLE') }} # {{ ticket.id }}
        </h1>

        <more-actions-dropdown
          :ticket="ticket"
          :is-editing="isEditing"
          @toggle-edit-mode="toggleEditMode"
        />
      </div>
      <div class="p-4 flex flex-col w-full justify-between h-full">
        <div class="flex flex-col gap-1">
          <div v-if="isEditing">
            <woot-input
              v-model.trim="ticket.title"
              name="title"
              type="text"
              :label="$t('TICKETS.TITLE')"
              :placeholder="$t('TICKETS.TITLE_PLACEHOLDER')"
              help-text="Forneça um título para o ticket."
            />
            <woot-text-area
              v-model.trim="ticket.description"
              class="rounded-none"
              rows="4"
              :label="$t('TICKETS.DESCRIPTION')"
              :placeholder="$t('TICKETS.DESCRIPTION_PLACEHOLDER')"
              help-text="Forneça uma descrição detalhada."
            />
            <woot-button
              color-scheme="primary"
              class="my-4 w-full"
              @click="saveChanges"
            >
              {{ $t('TICKETS.ACTIONS.SAVE') }}
            </woot-button>
          </div>
          <div v-else class="flex flex-col">
            <div>
              <h3 class="text-sm text-slate-600">{{ $t('TICKETS.TITLE') }}:</h3>
              <p class="text-sm text-slate-600">
                <strong>{{ ticket.title || '-' }}</strong>
              </p>
            </div>
            <div>
              <h3 class="text-sm text-slate-600">
                {{ $t('TICKETS.DESCRIPTION') }}:
              </h3>
              <p class="text-sm text-slate-600">
                <strong>{{ ticket.description || '-' }}</strong>
              </p>
            </div>
            <div>
              <h3 class="text-sm text-slate-600">
                {{ $t('TICKETS.ASSIGNEE.ASSIGNED_TO') }}:
              </h3>
              <p class="text-sm text-slate-600">
                <strong>{{ assigneeFormatted }}</strong>
              </p>
            </div>
            <div>
              <h3 class="text-sm text-slate-600">
                {{ $t('TICKETS.STATUS.TITLE') }}:
              </h3>
              <p class="text-sm text-slate-600">
                <strong>{{
                  $t(`TICKETS.STATUS.${ticket.status.toUpperCase()}`)
                }}</strong>
              </p>
            </div>
            <div>
              <h3 class="text-sm text-slate-600">
                {{ $t('TICKETS.RESOLVED_AT') }}:
              </h3>
              <p class="text-sm text-slate-600">
                <strong>{{ ticket.resolved_at || '-' }}</strong>
              </p>
            </div>
          </div>
          <div class="flex flex-col">
            <h3 class="text-sm text-slate-600">
              {{ $t('TICKETS.LABELS.TITLE') }}:
            </h3>
            <woot-label
              v-for="label in ticket.labels"
              :key="label.id"
              :title="label.title"
              :description="label.description"
              :show-close="true"
              :color="label.color"
              variant="smooth"
              @click="removeLabel(label)"
            />
            <label-selector
              v-if="showLabelSelector"
              :account-labels="accountLabels"
              :selected-labels="ticket.labels"
              @add="addLabel"
              @remove="removeLabel"
              @close="toggleLabelSelector"
            />
            <woot-button
              variant="clear"
              color-scheme="secondary"
              :icon="showLabelSelector ? 'dismiss-circle' : 'add'"
              @click="toggleLabelSelector"
            >
              {{
                showLabelSelector
                  ? $t('TICKETS.ACTIONS.CLOSE')
                  : $t('TICKETS.LABELS.CREATE')
              }}
            </woot-button>
          </div>
        </div>
      </div>
    </div>
    <woot-modal :show.sync="createModalVisible" :on-close="toggleModalLabel">
      <add-label-modal
        :prefill-title="ticket.title"
        @close="toggleModalLabel"
      />
    </woot-modal>
  </section>
</template>
<script>
import { mapGetters } from 'vuex';
import MoreActionsDropdown from './MoreActionsDropdown.vue';
import AddLabelModal from 'dashboard/routes/dashboard/settings/labels/AddLabel.vue';
import LabelSelector from './LabelSelector.vue';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  name: 'TicketDetails',
  components: {
    MoreActionsDropdown,
    LabelSelector,
    AddLabelModal,
  },
  mixins: [alertMixin],
  props: {
    ticketId: {
      type: [Number, String],
      required: true,
    },
  },
  data: () => ({
    isEditing: false,
    createModalVisible: false,
    showLabelSelector: false,
  }),
  computed: {
    ...mapGetters({
      ticket: 'tickets/getTicket',
      currentUserId: 'getCurrentUserID',
      accountLabels: 'labels/getTeamLabels',
    }),
    assigneeFormatted() {
      if (!this.ticket.assigned_to)
        return this.$t('TICKETS.ASSIGNEE_FILTER.UNASSIGNED');
      if (this.ticket.assigned_to.id === this.currentUserId)
        return this.$t('TICKETS.ASSIGNEE_FILTER.ME');

      return this.ticket.assigned_to.name;
    },
  },
  methods: {
    updateDescription(newValue) {
      this.$store.dispatch('tickets/update', {
        ticketId: this.ticketId,
        field: 'description',
        value: newValue,
      });
    },
    toggleEditMode() {
      this.isEditing = !this.isEditing;
    },
    toggleModalLabel() {
      this.createModalVisible = !this.createModalVisible;
    },
    saveChanges() {
      this.isEditing = false;
      this.$store.dispatch('tickets/update', {
        ticketId: this.ticketId,
        body: {
          title: this.ticket.title,
          description: this.ticket.description,
        },
      });
    },
    toggleLabelSelector() {
      this.showLabelSelector = !this.showLabelSelector;
    },
    addLabel(label) {
      this.$store
        .dispatch('tickets/addLabel', {
          ticketId: this.ticketId,
          label,
        })
        .catch(error => {
          this.showAlert(error);
        });
    },
    removeLabel(label) {
      this.$store
        .dispatch('tickets/removeLabel', {
          ticketId: this.ticketId,
          label,
        })
        .catch(error => {
          this.showAlert(error);
        });
    },
  },
};
</script>
