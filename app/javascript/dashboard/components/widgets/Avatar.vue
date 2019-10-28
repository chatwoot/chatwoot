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
    },
    backgroundColor: {
      type: String,
    },
    color: {
      type: String,
    },
    customStyle: {
      type: Object,
    },
    size: {
      type: Number,
      default: 40,
    },
    src: {
      type: String,
    },
    rounded: {
      type: Boolean,
      default: true,
    },
  },
  computed: {
    style() {
      return {
        display: 'flex',
        width: `${this.size}px`,
        height: `${this.size}px`,
        borderRadius: this.rounded ? '50%' : 0,
        lineHeight: `${this.size + Math.floor(this.size / 20)}px`,
        fontWeight: 'bold',
        alignItems: 'center',
        justifyContent: 'center',
        textAlign: 'center',
        backgroundColor: this.backgroundColor,
        font: `${Math.floor(this.size / 2.5)}px/${
          this.size
        }px Helvetica, Arial, sans-serif`,
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
