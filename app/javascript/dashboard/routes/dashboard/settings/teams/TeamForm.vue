<template>
  <div class="mx-0 flex flex-wrap">
    <div class="flex-shrink-0 flex-grow-0 w-full md:w-[65%]">
      <form class="mx-0 flex flex-wrap" @submit.prevent="handleSubmit">
        <woot-input
          v-model.trim="title"
          :class="{ error: $v.title.$error }"
          class="w-full"
          :label="$t('TEAMS_SETTINGS.FORM.NAME.LABEL')"
          :placeholder="$t('TEAMS_SETTINGS.FORM.NAME.PLACEHOLDER')"
          @input="$v.title.$touch"
        />

        <woot-input
          v-model.trim="description"
          :class="{ error: $v.description.$error }"
          class="w-full"
          :label="$t('TEAMS_SETTINGS.FORM.DESCRIPTION.LABEL')"
          :placeholder="$t('TEAMS_SETTINGS.FORM.DESCRIPTION.PLACEHOLDER')"
          @input="$v.description.$touch"
        />

        <div class="w-full flex items-center gap-2">
          <input v-model="allowAutoAssign" type="checkbox" :value="true" />
          <label for="conversation_creation">
            {{ $t('TEAMS_SETTINGS.FORM.AUTO_ASSIGN.LABEL') }}
          </label>
        </div>
        <div class="flex flex-row justify-end gap-2 py-2 px-0 w-full">
          <div class="w-full">
            <woot-submit-button
              :disabled="$v.title.$invalid || submitInProgress"
              :button-text="submitButtonText"
              :loading="submitInProgress"
            />
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
import WootSubmitButton from '../../../../components/buttons/FormSubmitButton.vue';
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
    submitInProgress: {
      type: Boolean,
      default: false,
    },
    formData: {
      type: Object,
      default: () => {},
    },
    submitButtonText: {
      type: String,
      default: '',
    },
  },
  data() {
    const formData = this.formData || {};
    const {
      description = '',
      name: title = '',
      allow_auto_assign: allowAutoAssign = true,
    } = formData;

    return {
      description,
      title,
      allowAutoAssign,
    };
  },
  validations,
  methods: {
    handleSubmit() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      this.onSubmit({
        description: this.description,
        name: this.title,
        allow_auto_assign: this.allowAutoAssign,
      });
    },
  },
};
</script>
