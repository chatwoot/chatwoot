<script setup>
import { ref } from 'vue';
import Dialog from './Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const alertDialog = ref(null);
const editDialog = ref(null);
const confirmDialog = ref(null);
const confirmDialogWithCustomFooter = ref(null);

const openAlertDialog = () => {
  alertDialog.value.open();
};
const openEditDialog = () => {
  editDialog.value.open();
};
const openConfirmDialog = () => {
  confirmDialog.value.open();
};
const openConfirmDialogWithCustomFooter = () => {
  confirmDialogWithCustomFooter.value.open();
};

// eslint-disable-next-line no-unused-vars
const onConfirm = dialog => {};
</script>

<template>
  <Story title="Components/Dialog" :layout="{ type: 'grid', width: '100%' }">
    <Variant title="Alert Dialog">
      <Button label="Open Alert Dialog" @click="openAlertDialog" />
      <Dialog
        ref="alertDialog"
        type="alert"
        title="Alert"
        description="This is an alert message."
      />
    </Variant>

    <Variant title="Edit Dialog">
      <Button label="Open Edit Dialog" @click="openEditDialog" />
      <Dialog
        ref="editDialog"
        type="edit"
        description="You can create a new portal here, by providing a name and a slug."
        title="Create Portal"
        confirm-button-label="Save"
        @confirm="onConfirm()"
      >
        <div class="flex flex-col gap-6">
          <Input
            id="portal-name"
            type="text"
            placeholder="User Guide | Chatwoot"
            label="Name"
            message="This will be the name of your public facing portal"
          />
          <Input
            id="portal-slug"
            type="text"
            placeholder="user-guide"
            label="Slug"
            message="app.chatwoot.com/hc/my-portal/en-US/categories/my-slug"
          />
        </div>
      </Dialog>
    </Variant>

    <Variant title="Confirm Dialog">
      <Button label="Open Confirm Dialog" @click="openConfirmDialog" />
      <Dialog
        ref="confirmDialog"
        type="confirm"
        title="Confirm Action"
        description="Are you sure you want to perform this action?"
        confirm-button-label="Yes, I'm sure"
        cancel-button-label="No, cancel"
        @confirm="onConfirm()"
      />
    </Variant>

    <Variant title="With custom footer">
      <Button
        label="Open Confirm Dialog with custom footer"
        @click="openConfirmDialogWithCustomFooter"
      />
      <Dialog
        ref="confirmDialogWithCustomFooter"
        title="Confirm Action"
        description="Are you sure you want to perform this action?"
      >
        <template #footer>
          <Button label="Custom Button" @click="onConfirm()" />
        </template>
      </Dialog>
    </Variant>
  </Story>
</template>
