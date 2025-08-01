<script>
import CardButton from 'shared/components/CardButton.vue';

export default {
  components: {
    CardButton,
  },
  props: {
    title: {
      type: String,
      default: '',
    },
    description: {
      type: String,
      default: '',
    },
    imageSrc: {
      type: String,
      default: '',
    },
    actions: {
      type: Array,
      default: () => [],
    },
  },
  methods: {
    onImageError(event) {
      this.imageError = true;
    },
  },
  data() {
    return {
      imageError: false,
    };
  },
  mounted() {
  },
};
</script>

<template>
  <div class="card-message">
    <img
      v-if="imageSrc && !imageError"
      class="card-image"
      :src="imageSrc"
      alt="Product image"
      @error="onImageError"
    />
    <div v-else class="card-image card-image--placeholder">
      <span>No Image</span>
    </div>
    <div class="card-body">
      <h4 class="card-title">
        {{ title }}
      </h4>
      <p class="card-description">
        {{ description }}
      </p>
      <div class="card-actions">
        <CardButton v-for="(action, idx) in actions" :key="action.id || action.text || idx" :action="action" :index="idx" />
      </div>
    </div>
  </div>
</template>

<style scoped>
.card-message {
  max-width: 350px;
  width: 100%;
  margin: 24px auto;
  border-radius: 16px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  background: #fff;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  align-items: stretch;
}
.card-image {
  width: 100%;
  height: 260px;
  object-fit: cover;
  background: #f3f4f6;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.1rem;
  color: #6b7280;
}
.card-image--placeholder {
  height: 260px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f3f4f6;
  color: #6b7280;
}
.card-body {
  padding: 20px 20px 16px 20px;
}
.card-title {
  font-size: 1.2rem;
  font-weight: 600;
  margin-bottom: 8px;
}
.card-description {
  font-size: 1rem;
  color: #6b7280;
  margin-bottom: 16px;
}
.card-actions {
  display: flex;
  gap: 12px;
  margin-top: 8px;
}
.card-actions .action-button {
  flex: 1;
}
</style>
