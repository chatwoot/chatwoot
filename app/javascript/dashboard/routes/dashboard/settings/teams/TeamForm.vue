<template>
  <div class="row">
    <div class="column content-box">
      <woot-modal-header
        :header-title="modalTitle"
        :header-content="modalDescription"
      />
      <form class="row" @submit.prevent="handleSubmit">
        <woot-input
          v-model.trim="title"
          :class="{ error: $v.title.$error }"
          class="medium-12 columns"
          :label="$t('TEAMS_SETTINGS.FORM.NAME.LABEL')"
          :placeholder="$t('TEAMS_SETTINGS.FORM.NAME.PLACEHOLDER')"
          @input="$v.title.$touch"
        />

        <woot-input
          v-model.trim="description"
          :class="{ error: $v.description.$error }"
          class="medium-12 columns"
          :label="$t('TEAMS_SETTINGS.FORM.DESCRIPTION.LABEL')"
          :placeholder="$t('TEAMS_SETTINGS.FORM.DESCRIPTION.PLACEHOLDER')"
          @input="$v.description.$touch"
        />

        <div class="medium-12">
          <label>
            {{ $t('TEAMS_SETTINGS.FORM.COLOR.LABEL') }}
            <woot-color-picker v-model="color" />
          </label>
        </div>
        <div class="medium-12">
          <input v-model="allowAutoAssign" type="checkbox" :value="true" />
          <label for="conversation_creation">
            {{ $t('TEAMS_SETTINGS.FORM.AUTO_ASSIGN.LABEL') }}
          </label>
        </div>
        <div class="modal-footer">
          <div class="medium-12 columns">
            <woot-submit-button
              :disabled="$v.title.$invalid || submitInProgress"
              :button-text="$t('TEAMS_SETTINGS.FORM.CREATE')"
              :loading="submitInProgress"
            />
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
import WootSubmitButton from '../../../../components/buttons/FormSubmitButton';
import validations from './helpers/validations';

export default {
  components: {
    WootSubmitButton,
  },

  props: {
    onSubmit: {
      type: Function,
      default: () => {},
    },
    modalTitle: {
      type: String,
      default: '',
    },
    modalDescription: {
      type: String,
      default: '',
    },
    submitInProgress: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      color: '#000',
      description: '',
      title: '',
      allowAutoAssign: true,
    };
  },
  validations,
  mounted() {
    this.color = this.getRandomColor();
  },
  methods: {
    getRandomColor() {
      const letters = '0123456789ABCDEF';
      let color = '#';
      for (let i = 0; i < 6; i += 1) {
        color += letters[Math.floor(Math.random() * 16)];
      }
      return color;
    },
    handleSubmit() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      this.onSubmit({
        color: this.color,
        description: this.description,
        name: this.title,
        allow_auto_assign: this.allowAutoAssign,
      });
    },
  },
};
</script>
