<template>
  <div class="grouped-csat">
    <div v-for="question in questions" :key="question.id">
      <csat-question-accordion
        :question="question"
        :responses="responsesFromQuestion(question.content)"
      >
        <ve-table
          :fixed-header="true"
          :border-around="true"
          :columns="columns()"
          :table-data="responsesFromQuestion(question.content)"
        />
      </csat-question-accordion>
    </div>
  </div>
</template>
<script>
import { VeTable } from 'vue-easytable';
import UserAvatarWithName from 'dashboard/components/widgets/UserAvatarWithName.vue';
import { mapGetters } from 'vuex';
import CsatQuestionAccordion from './CsatQuestionAccordion.vue';
import { CSAT_RATINGS } from 'shared/constants/messages';
import timeMixin from 'dashboard/mixins/time';
import rtlMixin from 'shared/mixins/rtlMixin';

export default {
  components: {
    CsatQuestionAccordion,
    VeTable,
  },
  mixins: [timeMixin, rtlMixin],
  computed: {
    ...mapGetters({
      questions: 'csat/getCSATQuestions',
      csatResponses: 'csat/getCSATResponses',
    }),
  },
  methods: {
    responsesFromQuestion(content) {
      return this.tableData().filter(
        response => content === response.csatQuestion
      );
    },
    columns() {
      return [
        {
          field: 'contact',
          key: 'contact',
          title: this.$t('CSAT_REPORTS.TABLE.HEADER.CONTACT_NAME'),
          align: this.isRTLView ? 'right' : 'left',
          width: 200,
          renderBodyCell: ({ row }) => {
            if (row.contact) {
              return (
                <UserAvatarWithName
                  textClass="text-sm text-slate-800"
                  size="24px"
                  user={row.contact}
                />
              );
            }
            return '---';
          },
        },
        {
          field: 'assignedAgent',
          key: 'assignedAgent',
          title: this.$t('CSAT_REPORTS.TABLE.HEADER.AGENT_NAME'),
          align: this.isRTLView ? 'right' : 'left',
          width: 200,
          renderBodyCell: ({ row }) => {
            if (row.assignedAgent) {
              return (
                <UserAvatarWithName size="24px" user={row.assignedAgent} />
              );
            }
            return '---';
          },
        },
        {
          field: 'rating',
          key: 'rating',
          title: this.$t('CSAT_REPORTS.TABLE.HEADER.RATING'),
          align: 'center',
          width: 80,
          renderBodyCell: ({ row }) => {
            const [ratingObject = {}] = CSAT_RATINGS.filter(
              rating => rating.value === row.rating
            );
            return (
              <span class="emoji-response">{ratingObject.emoji || '---'}</span>
            );
          },
        },
        {
          field: 'feedbackText',
          key: 'feedbackText',
          title: this.$t('CSAT_REPORTS.TABLE.HEADER.FEEDBACK_TEXT'),
          align: this.isRTLView ? 'right' : 'left',
          width: 300,
        },
        {
          field: 'conversationId',
          key: 'conversationId',
          title: '',
          align: this.isRTLView ? 'right' : 'left',
          width: 100,
          renderBodyCell: ({ row }) => {
            const routerParams = {
              name: 'inbox_conversation',
              params: { conversation_id: row.conversationId },
            };
            return (
              <div class="text-right">
                <router-link to={routerParams}>
                  {`#${row.conversationId}`}
                </router-link>
                <div class="csat--timestamp" v-tooltip={row.createdAt}>
                  {row.createdAgo}
                </div>
              </div>
            );
          },
        },
      ];
    },
    tableData() {
      return this.csatResponses.map(response => ({
        contact: response.contact,
        assignedAgent: response.assigned_agent,
        rating: response.rating,
        feedbackText: response.feedback_message || '---',
        conversationId: response.conversation_id,
        createdAgo: this.dynamicTime(response.created_at),
        csatQuestion: response.csat_question,
        csatQuestionId: response.csat_question_id,
        createdAt: this.messageStamp(response.created_at, 'LLL d yyyy, h:mm a'),
      }));
    },
  },
};
</script>

<style>
.grouped-csat .ve-table-header-tr {
  display: none;
}
.ve-table-container.ve-table-border-around {
  overflow: hidden;
}
</style>
