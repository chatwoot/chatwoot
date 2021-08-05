<template>
  <div>
    <div class="medium-12 columns">
      <label
        :class="{ error: $v.ccEmails.$error }"
        class="multiselect-wrap--small"
      >
        {{ $t('INBOX_MGMT.ADD.AGENTS.TITLE') }}
        <multiselect
          v-model="ccEmails"
          :options="ccOptions"
          track-by="id"
          label="name"
          :multiple="true"
          :taggable="true"
          :close-on-select="false"
          :clear-on-select="false"
          :hide-selected="true"
          tag-position="top"
          selected-label
          :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
          :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
          :placeholder="$t('INBOX_MGMT.ADD.AGENTS.PICK_AGENTS')"
          @select="$v.ccEmails.$touch"
          @tag="addCCEmail"
        >
        </multiselect>
        <span v-if="$v.ccEmails.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.AGENTS.VALIDATION_ERROR') }}
        </span>
      </label>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      ccEmails: [],
      ccOptions: [],
    };
  },
  validations: {
    ccEmails: {
      isEmpty() {
        return !!this.ccEmails.length;
      },
    },
  },
  methods: {
    addCCEmail(newEmail) {
      const option = {
        id: newEmail,
        name: newEmail,
      };
      //   this.ccOptions.push(option);
      this.ccEmails.push(option);
    },
  },
};
</script>
