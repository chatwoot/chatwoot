<template>
  <div class="status-bar" :class="type">
    <p class="message">{{message}}</p>
    <router-link
      :to="buttonRoute"
      class="button small warning nice"
      v-if="showButton"
    >
      {{buttonText}}
    </router-link>
  </div>
</template>

<script>
export default {
  props: {
    message: String,
    buttonRoute: String,
    buttonText: String,
    showButton: Boolean,
    type: String, // Danger, Info, Success, Warning
  },
};
</script>
