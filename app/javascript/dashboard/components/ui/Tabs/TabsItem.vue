<template>
  <li
    :class="{
      'tabs-title': true,
      'is-active': active,
    }"
  >
    <a @click="onTabClick">
      {{ name }}
      <span v-if="showBadge" class="badge">
        {{ getItemCount }}
      </span>
    </a>
  </li>
</template>
<script>
export default {
  name: 'WootTabsItem',
  props: {
    index: {
      type: Number,
      default: 0,
    },
    name: {
      type: String,
      required: true,
    },
    disabled: {
      type: Boolean,
      default: false,
    },
    count: {
      type: Number,
      default: 0,
    },
    showBadge: {
      type: Boolean,
      default: true,
    },
  },

  computed: {
    active() {
      return this.index === this.$parent.index;
    },

    getItemCount() {
      return this.count;
    },
  },

  methods: {
    onTabClick(event) {
      event.preventDefault();
      if (!this.disabled) {
        this.$parent.$emit('change', this.index);
      }
    },
  },
};
</script>
