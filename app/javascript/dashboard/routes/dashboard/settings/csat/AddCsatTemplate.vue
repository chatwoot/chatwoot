<template>
  <div class="h-auto overflow-auto flex flex-col">
    <woot-modal-header :header-title="$t('CSAT_TEMPLATES.TEMPLATE.ADD')" />
    <form class="flex flex-col w-full" @submit.prevent="addCsatTemplate()">
      <label>
        {{ $t('CSAT_TEMPLATES.FORM.NAME') }}
        <input
              v-model="name"
              class="mb-1"
              type="text"
            />
      </label>
      <label :class="{ error: $v.inboxes.$error }">
        {{ $t('CSAT_TEMPLATES.FORM.INBOXES.LABEL') }}
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
        <span v-if="$v.inboxes.$error" class="message">
          {{ $t('CSAT_TEMPLATES.FORM.INBOXES.ERROR') }}
        </span>
      </label>
      <div
        v-for="(question, index) in custom_questions"
        :key="index"
        class="w-full"
      >
        <label
          :class="{ error: $v.custom_questions.$each[index].content.$error }"
        >
          {{ question.label }}
          <div class="flex">
            <input
              v-model="question.content"
              class="mb-1"
              type="text"
              :placeholder="$t('CSAT_TEMPLATES.TEMPLATE.PLACEHOLDER')"
            />
            <woot-button
              type="button"
              icon="delete"
              size="small"
              variant="clear"
              @click.prevent="deleteQuestion(index)"
            />
          </div>
          <span
            v-if="$v.custom_questions.$each[index].content.$error"
            class="message"
          >
            {{ $t('CSAT_TEMPLATES.FORM.QUESTION.ERROR') }}
          </span>
        </label>
      </div>
      <span v-if="!$v.custom_questions.maxLength">
        {{ $t('CSAT_TEMPLATES.FORM.QUESTION.ERROR_MAX_LENGTH') }}
      </span>
      <div v-if="$v.custom_questions.maxLength" class="mt-2 w-full">
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
          :button-text="$t('CSAT_TEMPLATES.ADD.FORM.SUBMIT')"
        />
        <button class="button clear" @click.prevent="onClose">
          {{ $t('CANNED_MGMT.ADD.CANCEL_BUTTON_TEXT') }}
        </button>
      </div>
    </form>
  </div>
</template>

<script>
import { required, minLength, maxLength } from 'vuelidate/lib/validators';
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
      name: '',
      custom_questions: [],
      inboxes: [],
    };
  },
  validations: {
    custom_questions: {
      required,
      minLength: minLength(1),
      maxLength: maxLength(20),
      $each: {
        content: {
          required,
        },
      },
    },
    inboxes: {
      required,
    },
  },
  computed: {
    ...mapGetters({
      dropdownValues: 'csatTemplates/inboxesForSelect',
    }),
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
    addCsatTemplate() {
      this.$v.$touch();

      if (this.$v.$invalid) {
        this.showAlert(this.$t('GENERAL_SETTINGS.FORM.ERROR'));
        return;
      }

      this.$store
        .dispatch('csatTemplates/create', this.csatTemplate())
        .then(() => {
          this.$store.dispatch('csatTemplates/get');
          this.onClose();
          this.showAlert('Successfully added.');
        })
        .catch(() => {
          this.onClose();
          this.showAlert('Something went wrong');
        });
    },
    csatTemplate() {
      return {
        csat_template: {
          name: this.name,
          inbox_ids: this.inboxes.map(inbox => inbox.id),
          csat_template_questions_attributes: this.custom_questions,
        },
      };
    },
  },
};
</script>
