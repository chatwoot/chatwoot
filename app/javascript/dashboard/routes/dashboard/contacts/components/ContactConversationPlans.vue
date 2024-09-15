<template>
  <div class="contact-conversation-plan--panel pb-2">
    <div
      v-if="!uiFlags.isFetchingConversationPlans"
      class="contact-conversation-plan__wrap"
    >
      <div v-if="!conversationPlans.length" class="italic">
        <span>
          {{ $t('CONTACT_PANEL.ACTIONS.NO_ACTION') }}
        </span>
      </div>
      <div v-else class="contact-conversation-plan--list">
        <div
          v-for="conversationPlan in conversationPlans"
          :key="conversationPlan.id"
          class="px-0 py-1 border-b flex-1 border-slate-50 dark:border-slate-800/75 w-auto max-w-full hover:bg-slate-25 dark:hover:bg-slate-800 group"
          @click="onCardClick(conversationPlan)"
        >
          <div class="flex justify-between">
            <div
              class="inbox--name inline-flex items-center py-0.5 px-0 leading-3 whitespace-nowrap font-medium bg-none text-slate-600 dark:text-slate-500 text-xs my-0 mx-2.5"
            >
              {{ moreInformation(conversationPlan) }}
            </div>
            <div class="flex gap-2 mx-2">
              <span
                class="text-slate-500 dark:text-slate-400 text-xs font-medium leading-3 py-0.5 px-0 inline-flex text-ellipsis overflow-hidden whitespace-nowrap"
              >
                <fluent-icon
                  icon="timer"
                  size="12"
                  class="text-slate-500 dark:text-slate-400"
                />
                {{ formattedDate(conversationPlan.action_date) }}
              </span>
            </div>
          </div>

          <div class="flex justify-between items-end">
            <h4
              class="conversation--user text-sm my-0 mx-2 capitalize pt-0.5 text-ellipsis font-medium overflow-hidden whitespace-nowrap w-[calc(100%-70px)] text-slate-900 dark:text-slate-100"
            >
              {{ conversationPlan.description }}
            </h4>
            <woot-button
              v-if="showCompleteActionButton(conversationPlan)"
              icon="arrow-right"
              variant="link"
              size="small"
              class="mr-2"
              @click.stop="confirmCompleting(conversationPlan.id)"
            >
              {{ $t('COMPLETE_CONVERSATION_PLAN.BUTTON_LABEL') }}
            </woot-button>
          </div>
        </div>
        <woot-confirm-modal
          ref="confirmCompletingDialog"
          :title="$t('COMPLETE_CONVERSATION_PLAN.CONFIRM.TITLE')"
          :description="$t('COMPLETE_CONVERSATION_PLAN.CONFIRM.MESSAGE')"
          :confirm-label="$t('COMPLETE_CONVERSATION_PLAN.CONFIRM.YES')"
          :cancel-label="$t('COMPLETE_CONVERSATION_PLAN.CONFIRM.NO')"
        />
      </div>
    </div>
    <spinner v-else />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner.vue';
import { format } from 'date-fns';
import alertMixin from 'shared/mixins/alertMixin';
import { conversationUrl, frontendURL } from '../../../../helper/URLHelper';
import router from '../../../index';

export default {
  components: {
    Spinner,
  },
  mixins: [alertMixin],
  props: {
    contactId: {
      type: [String, Number],
      required: true,
    },
  },
  computed: {
    ...mapGetters({
      uiFlags: 'contacts/getUIFlags',
      accountId: 'getCurrentAccountId',
    }),
    conversationPlans() {
      return this.$store.getters['contacts/getConversationPlans'](
        this.contactId
      );
    },
  },
  watch: {
    contactId(newContactId, prevContactId) {
      if (newContactId && newContactId !== prevContactId) {
        this.$store.dispatch('contacts/fetchConversationPlans', newContactId);
      }
    },
  },
  mounted() {
    this.$store.dispatch('contacts/fetchConversationPlans', this.contactId);
  },
  methods: {
    formattedDate(date) {
      return format(new Date(date), 'dd/MM/yyyy');
    },
    moreInformation(conversationPlan) {
      const status = this.$t(
        'CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.' +
          conversationPlan.status +
          '.TEXT'
      );

      return `${conversationPlan.inbox_type} / ${status}`;
    },
    showCompleteActionButton(conversationPlan) {
      return conversationPlan.status !== 'resolved';
    },
    async confirmCompleting(id) {
      const ok = await this.$refs.confirmCompletingDialog.showConfirmation();

      if (ok) {
        await this.completeConversationPlan(id);
      }
    },
    async completeConversationPlan(id) {
      try {
        await this.$store.dispatch('contacts/completeConversationPlan', {
          contactId: this.contactId,
          conversationPlanId: id,
        });
        this.showAlert(
          this.$t('COMPLETE_CONVERSATION_PLAN.API.SUCCESS_MESSAGE')
        );
      } catch (error) {
        this.showAlert(
          error.message
            ? error.message
            : this.$t('COMPLETE_CONVERSATION_PLAN.API.ERROR_MESSAGE')
        );
      }
    },
    onCardClick(conversationPlan) {
      const chat_id = conversationPlan.conversation_id;
      const path = frontendURL(
        conversationUrl({
          accountId: this.accountId,
          id: chat_id,
        })
      );
      if (this.$route.path !== path) {
        router.push({ path });
      }
    },
  },
};
</script>
