<template>
  <div>
    <woot-button
      icon="more-vertical"
      color-scheme="secondary"
      variant="clear"
      size="small"
      @click="toggleOptions"
    />
    <div
      v-if="showMore"
      v-on-clickaway="onClickAway"
      class="rtl:left-auto rtl:right-3 w-30 absolute z-30 rounded-md shadow-xl bg-white dark:bg-slate-800 py-2 px-2 border border-slate-25 dark:border-slate-700"
      :class="{ 'block visible': showMore }"
    >
      <woot-dropdown-menu>
        <woot-dropdown-item>
          <woot-button
            variant="clear"
            color-scheme="secondary"
            size="small"
            icon="edit"
            @click="onEdit"
          >
            Edit
          </woot-button>
        </woot-dropdown-item>
        <woot-dropdown-item>
          <woot-button
            variant="clear"
            color-scheme="secondary"
            size="small"
            icon="delete"
            @click="onDelete"
          >
            Delete
          </woot-button>
        </woot-dropdown-item>
      </woot-dropdown-menu>
    </div>
  </div>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';

export default {
  mixins: [alertMixin],
  props: {
    templateId: {
      type: Number,
      default: 0,
    },
  },
  data() {
    return {
      showMore: false,
    };
  },
  mounted() {
    document.addEventListener('keydown', e => {
      if (this.showMore && e.code === 'Escape') {
        this.onClose();
      }
    });
  },
  destroyed() {},
  methods: {
    toggleOptions() {
      this.showMore = !this.showMore;
    },
    onClose() {
      this.showMore = false;
    },
    onClickAway() {
      this.onClose();
    },
    onEdit() {
      this.$emit('on-edit');
      this.$store.dispatch('csatTemplates/getCsatTemplate', this.templateId);
    },
    onDelete() {
      this.$emit('on-delete');
      this.$store.dispatch('csatTemplates/delete', this.templateId);
      this.showAlert('Successfully removed.');
    },
  },
};
</script>

<style></style>
