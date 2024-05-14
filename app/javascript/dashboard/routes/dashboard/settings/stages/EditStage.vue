<template>
  <div class="h-auto overflow-auto flex flex-col">
    <woot-modal-header :header-title="pageTitle" />
    <form class="flex flex-col w-full" @submit.prevent="editStage">
      <div class="w-full">
        <div class="gap-2 flex flex-row">
          <div class="w-[50%]">
            <woot-input
              v-model.trim="name"
              :label="$t('STAGES_MGMT.EDIT.FORM.NAME.LABEL')"
              type="text"
              :class="{ error: $v.name.$error }"
              :error="
                $v.name.$error ? $t('STAGES_MGMT.EDIT.FORM.NAME.ERROR') : ''
              "
              :placeholder="$t('STAGES_MGMT.EDIT.FORM.NAME.PLACEHOLDER')"
              @blur="$v.name.$touch"
            />
          </div>
          <div class="w-[50%]">
            <woot-input
              v-model.trim="code"
              :label="$t('STAGES_MGMT.EDIT.FORM.CODE.LABEL')"
              type="text"
              readonly
            />
          </div>
        </div>
        <label :class="{ error: $v.description.$error }">
          {{ $t('STAGES_MGMT.EDIT.FORM.DESC.LABEL') }}
          <textarea
            v-model.trim="description"
            rows="5"
            type="text"
            :placeholder="$t('STAGES_MGMT.EDIT.FORM.DESC.PLACEHOLDER')"
            @blur="$v.description.$touch"
          />
          <span v-if="$v.description.$error" class="message">
            {{ $t('STAGES_MGMT.EDIT.FORM.DESC.ERROR') }}
          </span>
        </label>
      </div>
      <div class="flex flex-row justify-end gap-2 py-2 px-0 w-full">
        <woot-button :is-loading="isUpdating" :disabled="isButtonDisabled">
          {{ $t('STAGES_MGMT.EDIT.SUBMIT') }}
        </woot-button>
        <woot-button variant="clear" @click.prevent="onClose">
          {{ $t('STAGES_MGMT.EDIT.CANCEL_BUTTON_TEXT') }}
        </woot-button>
      </div>
    </form>
  </div>
</template>

<script>
import { required, minLength } from 'vuelidate/lib/validators';
import alertMixin from 'shared/mixins/alertMixin';
export default {
  components: {},
  mixins: [alertMixin],
  props: {
    selectedStage: {
      type: Object,
      default: () => {},
    },
    isUpdating: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      name: '',
      description: '',
      show: true,
      code: '',
      isTouched: true,
    };
  },
  validations: {
    name: {
      required,
    },
    description: {
      required,
      minLength: minLength(1),
    },
  },
  computed: {
    isButtonDisabled() {
      return this.$v.description.$invalid || this.isMultiselectInvalid;
    },

    pageTitle() {
      return `${this.$t('STAGES_MGMT.EDIT.TITLE')} - ${
        this.selectedStage.name
      }`;
    },
  },
  mounted() {
    this.setFormValues();
  },
  methods: {
    onClose() {
      this.$emit('on-close');
    },
    setFormValues() {
      this.name = this.selectedStage.name;
      this.description = this.selectedStage.description;
      this.code = this.selectedStage.code;
    },
    async editStage() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      try {
        await this.$store.dispatch('stages/update', {
          id: this.selectedStage.id,
          description: this.description,
          name: this.name,
        });
        this.alertMessage = this.$t('STAGES_MGMT.EDIT.API.SUCCESS_MESSAGE');
        this.onClose();
      } catch (error) {
        const errorMessage = error?.message;
        this.alertMessage =
          errorMessage || this.$t('STAGES_MGMT.EDIT.API.ERROR_MESSAGE');
      } finally {
        this.showAlert(this.alertMessage);
      }
    },
  },
};
</script>
