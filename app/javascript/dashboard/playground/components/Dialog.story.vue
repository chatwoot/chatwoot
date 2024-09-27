<script setup>
import { ref } from 'vue';
import DialogV4 from './Dialog.vue';
import ButtonV4 from './Button.vue';
import InputV4 from './Input.vue';

const alertDialog = ref(null);
const editDialog = ref(null);
const confirmDialog = ref(null);

const openAlertDialog = () => {
  alertDialog.value.open();
};

const openEditDialog = () => {
  editDialog.value.open();
};

const openConfirmDialog = () => {
  confirmDialog.value.open();
};

const onConfirm = () => {
  console.log('Dialog confirmed');
};
</script>

<template>
  <Story title="Components/Dialog" :layout="{ type: 'grid', width: '100%' }">
    <Variant title="Alert Dialog">
      <ButtonV4 label="Open Alert Dialog" @click="openAlertDialog" />
      <DialogV4
        ref="alertDialog"
        type="alert"
        title="Alert"
        description="This is an alert message."
      />
    </Variant>

    <Variant title="Edit Dialog">
      <ButtonV4 label="Open Edit Dialog" @click="openEditDialog" />
      <DialogV4
        ref="editDialog"
        type="edit"
        description="You can create a new portal here, by providing a name and a slug."
        title="Create Portal"
        confirm-button-label="Save"
        @confirm="onConfirm"
      >
        <template #form>
          <div class="flex flex-col gap-6">
            <InputV4
              id="portal-name"
              type="text"
              placeholder="User Guide | Chatwoot"
              label="Name"
              message="This will be the name of your public facing portal"
            />
            <InputV4
              id="portal-slug"
              type="text"
              placeholder="user-guide"
              label="Slug"
              message="app.chatwoot.com/hc/my-portal/en-US/categories/my-slug"
            />
          </div>
        </template>
      </DialogV4>
    </Variant>

    <Variant title="Confirm Dialog">
      <ButtonV4 label="Open Confirm Dialog" @click="openConfirmDialog" />
      <DialogV4
        ref="confirmDialog"
        type="confirm"
        title="Confirm Action"
        description="Are you sure you want to perform this action?"
        confirm-button-label="Yes, I'm sure"
        cancel-button-label="No, cancel"
        @confirm="onConfirm"
      />
    </Variant>
  </Story>
</template>
