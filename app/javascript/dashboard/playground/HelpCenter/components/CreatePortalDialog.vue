<script setup>
import { ref } from 'vue';
import Dialog from 'dashboard/playground/components/Dialog.vue';
import InputV4 from 'dashboard/playground/components/Input.vue';

const emit = defineEmits(['confirm']);

const dialogRef = ref(null);

const handleDialogConfirm = () => {
  emit('confirm');
};

// Expose the dialogRef to the parent component
defineExpose({ dialogRef });
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    title="Create New Portal"
    @confirm="handleDialogConfirm"
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
  </Dialog>
</template>
