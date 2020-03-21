<template>
  <div
    class="avatar-container"
    :style="[style, customStyle]"
    aria-hidden="true"
  >
    <span>{{ userInitial }}</span>
  </div>
</template>

<script>
export default {
  name: 'Avatar',
  props: {
    username: {
      type: String,
      default: '',
    },
    backgroundColor: {
      type: String,
      default: 'white',
    },
    color: {
      type: String,
      default: '#1f93ff',
    },
    customStyle: {
      type: Object,
      default: undefined,
    },
    size: {
      type: Number,
      default: 40,
    },
    src: {
      type: String,
      default: '',
    },
    rounded: {
      type: Boolean,
      default: true,
    },
  },
  computed: {
    style() {
      return {
        width: `${this.size}px`,
        height: `${this.size}px`,
        borderRadius: this.rounded ? '50%' : 0,
        lineHeight: `${this.size + Math.floor(this.size / 20)}px`,
        backgroundColor: this.backgroundColor,
        fontSize: `${Math.floor(this.size / 2.5)}px`,
        color: this.color,
      };
    },
    userInitial() {
      return this.initials || this.initial(this.username);
    },
  },
  methods: {
    initial(username) {
      const parts = username ? username.split(/[ -]/) : [];
      let initials = '';
      for (let i = 0; i < parts.length; i += 1) {
        initials += parts[i].charAt(0);
      }
      if (initials.length > 2 && initials.search(/[A-Z]/) !== -1) {
        initials = initials.replace(/[a-z]+/g, '');
      }
      initials = initials.substr(0, 2).toUpperCase();
      return initials;
    },
  },
};
</script>

<style lang="scss" scoped>
.avatar-container {
  display: flex;
  font-weight: 500;
  align-items: center;
  justify-content: center;
  text-align: center;
  background-image: linear-gradient(to top, #4481eb 0%, #04befe 100%);
}
</style>
