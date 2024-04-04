<template>
  <div class="contact-attribute">
    <div class="title-wrap">
      <h4 class="text-sm title">
        <div class="title--icon">
          <emoji-or-icon :icon="icon" :emoji="emoji" />
        </div>
        {{ label }}
      </h4>
    </div>
    <div v-show="isEditing">
      <div class="mb-2 w-full flex items-center">
        <input
          ref="inputfield"
          v-model="editedValue"
          type="text"
          class="!h-8 ltr:rounded-r-none rtl:rounded-l-none !mb-0 !text-sm"
          autofocus="true"
          @keyup.enter="onUpdate"
        />
        <div>
          <woot-button
            size="small"
            icon="ion-checkmark"
            class="rounded-l-none rtl:rounded-r-none"
            @click="onUpdate"
          />
        </div>
      </div>
    </div>
    <div
      v-show="!isEditing"
      class="value--view"
      :class="{ 'is-editable': showEdit }"
    >
      <p class="value">
        {{ value || '---' }}
      </p>
      <woot-button
        v-if="showEdit"
        variant="clear link"
        size="small"
        color-scheme="secondary"
        icon="edit"
        class-names="edit-button"
        @click="onEdit"
      />
    </div>
  </div>
</template>

<script>
import EmojiOrIcon from 'shared/components/EmojiOrIcon.vue';

export default {
  components: {
    EmojiOrIcon,
  },
  props: {
    label: { type: String, required: true },
    icon: { type: String, default: '' },
    emoji: { type: String, default: '' },
    value: { type: [String, Number], default: '' },
    showEdit: { type: Boolean, default: false },
  },
  data() {
    return {
      isEditing: false,
      editedValue: this.value,
    };
  },
  methods: {
    focusInput() {
      this.$refs.inputfield.focus();
    },
    onEdit() {
      this.isEditing = true;
      this.$nextTick(() => {
        this.focusInput();
      });
    },
    onUpdate() {
      this.isEditing = false;
      this.$emit('update', this.editedValue);
    },
  },
};
</script>

<style lang="scss" scoped>
.contact-attribute {
  margin-bottom: var(--space-small);
}
.title-wrap {
  display: flex;
  align-items: center;
  margin-bottom: var(--space-mini);
}
.title {
  display: flex;
  align-items: center;
  margin: 0;
}
.title--icon {
  width: var(--space-two);
}
.edit-button {
  display: none;
}
.value--view {
  display: flex;

  &.is-editable:hover {
    .value {
      background: var(--color-background);
    }
    .edit-button {
      display: block;
    }
  }
}
.value {
  display: inline-block;
  min-width: var(--space-mega);
  border-radius: var(--border-radius-small);
  word-break: break-all;
  margin: 0 var(--space-smaller) 0 var(--space-normal);
  padding: var(--space-micro) var(--space-smaller);
}
</style>
