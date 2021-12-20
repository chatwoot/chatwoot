<template>
  <div>
    <div class="ui-snackbar">
      <div class="ui-snackbar-text">
        {{ message }}
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    message: String,
    showButton: Boolean,
    duration: {
      type: [String, Number],
      default: 3000,
    },
  },
  data() {
    return {
      toggleAfterTimeout: false,
    };
  },
  mounted() {},
  methods: {},
};
</script>
