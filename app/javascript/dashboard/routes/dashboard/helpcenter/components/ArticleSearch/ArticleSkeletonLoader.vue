<template>
  <div class="skeleton-loader">
    <div>
      <div class="skeleton-meta" />
      <div class="skeleton-title" />
    </div>
    <div class="skeleton-body">
      <div class="skeleton-line" />
      <div class="skeleton-line" />
      <div class="skeleton-line" />
    </div>
    <div class="skeleton-body">
      <div class="skeleton-line" />
      <div class="skeleton-line" />
      <div class="skeleton-line" />
    </div>
  </div>
</template>

<script>
export default {
  name: 'SkeletonLoader',
};
</script>

<style scoped>
@keyframes shimmer {
  0% {
    background-position: -200px 0;
  }
  100% {
    background-position: 200px 0;
  }
}

.skeleton-loader {
  padding: var(--space-medium);
}

.skeleton-meta {
  width: 100%;
  height: var(--space-medium);
  background-color: var(--s-50);
  border-radius: var(--border-radius-small);
  margin-bottom: var(--space-small);
  width: 20%;
}

.skeleton-title {
  flex-grow: 1;
  height: var(--space-larger);
  background-color: var(--s-50);
  margin-bottom: var(--space-medium);
  border-radius: var(--border-radius-small);
  max-width: 60%;
}

.skeleton-body {
  margin-bottom: var(--space-medium);
}
.skeleton-line {
  height: var(--space-two);
  background-color: var(--s-50);
  margin-bottom: var(--space-small);
  border-radius: var(--border-radius-small);
}

.skeleton-meta,
.skeleton-body .skeleton-line {
  background: linear-gradient(
    90deg,
    var(--s-50) 25%,
    var(--s-75) 50%,
    var(--s-50) 75%
  );
  background-size: 400px 400px;
  background-position: center center;
  background-repeat: repeat;
  animation: shimmer 2s infinite ease-in;
}

.skeleton-body .skeleton-line:last-child {
  width: 70%;
}
</style>
