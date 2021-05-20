<template>
  <modal :show.sync="show" :on-close="onClose" :close-on-backdrop-click="false">
    <div class="column content-box">
      <woot-modal-header
        :header-title="integration.name"
        :header-content="integration.description"
      />
      <FormulateForm
        #default="{ hasErrors }"
        v-model="values"
        :schema="schema"
        @submit="submitForm"
      >
        <FormulateInput type="text" label="Select a username">
          <template #label="{ label, id }">
            <label :for="id">
              {{ label }}
            </label>
          </template>
        </FormulateInput>
        <div class="modal-footer">
          <woot-button :disabled="hasErrors">
            Create
          </woot-button>
          <woot-button class="button clear" @click.prevent="onClose">
            Cancel
          </woot-button>
        </div>
      </FormulateForm>
      <span>{{ values }}</span>
    </div>
  </modal>
</template>
<script>
import Modal from '../../../../components/Modal';

export default {
  components: {
    Modal,
  },
  props: {
    onClose: {
      type: Function,
      required: true,
    },
    integration: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      endPoint: '',
      addWebHook: {
        showAlert: false,
        showLoading: false,
        message: '',
      },
      show: true,
      values: {},
      schema: [
        {
          label: 'Dialogflow Project ID',
          placeholder: 'Dialogflow Project ID',
          type: 'text',
          name: 'project_id',
          validation: 'required|min:5',
          validationName: 'Project Id',
          'validation-messages': {
            min: 'Miniumm 5 characters required',
          },
        },
        {
          label: 'Dialogflow Project Key File',
          placeholder: 'Dialogflow Project Key File',
          type: 'textarea',
          name: 'credentials',
          validation: 'required',
        },
      ],
    };
  },
  mounted() {
    console.log('Integration', this.integration);
  },
  methods: {
    submitForm() {
      console.log('Form submitted', this.values);
    },
  },
};
</script>
<style lang="scss" scoped></style>
