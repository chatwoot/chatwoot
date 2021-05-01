<template>
  <div>
    <div class="notelist-wrap">
      <h3 class="page-sub-title">
        Notes
      </h3>
      <contact-note
        v-for="note in notes"
        :key="note.id"
        :note="note.content"
        :user-name="note.user.name"
        :time-stamp="note.created_at"
        :thumbnail="note.user.thumbnail"
      />
      <woot-button variant="clear link" @click="onclick">
        View all notes
        <i class="ion-arrow-right-c" />
      </woot-button>
    </div>
  </div>
</template>

<script>
import ContactNote from './ContactNote';
export default {
  components: {
    ContactNote,
  },

  props: {
    notes: {
      type: Array,
      default: () => [],
    },
  },

  methods: {
    onclick() {
      this.$emit('show');
    },
  },
};
</script>

<style lang="scss" scoped></style>
