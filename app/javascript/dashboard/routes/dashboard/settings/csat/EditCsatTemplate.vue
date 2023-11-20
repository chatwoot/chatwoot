<template>
  <div class="h-auto overflow-auto flex flex-col">
    <woot-modal-header :header-title="$t('CSAT_SETTINGS.TEMPLATE.EDIT')" />
    <form class="flex flex-col w-full" @submit.prevent="editCsatTemplate()">
      <label>Inbox</label>
      <multiselect
        v-model="inboxes"
        :options="dropdownValues"
        track-by="id"
        label="name"
        :placeholder="$t('FORMS.MULTISELECT.SELECT')"
        :multiple="true"
        :close-on-select="false"
        :clear-on-select="false"
        :hide-selected="true"
        selected-label
        :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
        deselect-label=""
        :max-height="160"
        :option-height="104"
      />
      <div
        v-for="(question, index) in custom_questions"
        :key="index"
        class="w-full"
      >
        <label>
          {{ question.label }}
          <div class="flex">
            <input
              v-model="question.content"
              type="text"
              :placeholder="$t('CSAT_SETTINGS.TEMPLATE.PLACEHOLDER')"
            />
            <woot-button
              type="button"
              icon="delete"
              size="small"
              variant="clear"
              @click.prevent="deleteQuestion(index)"
            />
          </div>
        </label>
      </div>
      <div class="w-full">
        <woot-button
          type="button"
          color-scheme="success"
          icon="add"
          size="small"
          @click.prevent="addNewQuestion"
        >
          Add Question
        </woot-button>
      </div>
      <div class="flex flex-row justify-end gap-2 py-2 px-0 w-full">
        <woot-submit-button
          :button-text="$t('CSAT_SETTINGS.EDIT.FORM.SUBMIT')"
        />
        <button class="button clear" @click.prevent="onClose">Cancel</button>
      </div>
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
export default {
  mixins: [alertMixin],
  props: {
    onClose: {
      type: Function,
      default: () => {},
    },
  },
  data() {
    return {
      custom_questions: [],
      inboxes: [],
    };
  },
  computed: {
    ...mapGetters({
      dropdownValues: 'csatTemplates/inboxesForSelect',
      currentTemplateId: 'csatTemplates/getCurrentTemplateId',
      currentTemplate: 'csatTemplates/getCurrentTemplate',
    }),
  },
  watch: {
    currentTemplate(temp) {
      const saved_q = [];

      for (let index = 0; index < temp.questions.length; index = +1) {
        const question = temp.questions[index];

        saved_q.push({ ...question, label: 'Question' + (index + 1) });
      }
      this.custom_questions = saved_q;
      this.inboxes = temp.selected_inboxes;
    },
  },
  mounted() {
    this.$store.dispatch('csatTemplates/getInboxes');
  },
  methods: {
    addNewQuestion() {
      this.custom_questions.push(this.newQuestion());
    },
    newQuestion() {
      return {
        id: null,
        label: this.newLabel(),
        content: '',
      };
    },
    newLabel() {
      return 'Question ' + (this.custom_questions.length + 1);
    },
    deleteQuestion(index) {
      this.custom_questions.splice(index, 1);
    },
    editCsatTemplate() {
      this.showAlert('Successfully updated.');
      this.onClose();
    },
  },
};
</script>
