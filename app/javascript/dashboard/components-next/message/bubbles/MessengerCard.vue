<script setup>
import { getMediaUrl } from '@/shared/helpers/URLHelper';

defineProps({
  items: {
    type: Array,
    default: () => [],
  },
});

const handleImageError = event => {
  // Hide broken images gracefully
  event.target.style.display = 'none';
  // Show the debug URL instead
  const debugUrl = event.target.nextElementSibling;
  if (debugUrl && debugUrl.classList.contains('debug-url')) {
    debugUrl.style.display = 'block';
    debugUrl.style.color = 'red';
    debugUrl.innerHTML = `❌ Failed to load: ${event.target.src}`;
  }
};

const handleImageLoad = event => {
  // Hide debug URL when image loads successfully
  const debugUrl = event.target.nextElementSibling;
  if (debugUrl && debugUrl.classList.contains('debug-url')) {
    debugUrl.style.display = 'none';
  }
};

const getImageUrl = item => {
  return getMediaUrl(item);
};

const getLinkAction = item => {
  if (!item.actions || !Array.isArray(item.actions)) return null;
  return item.actions.find(action => action.type === 'link');
};
</script>

<template>
  <div class="messenger-card">
    <div class="card-container">
      <div v-for="(item, index) in items" :key="index" class="card-item">
        <div v-if="getImageUrl(item)" class="card-image">
          <img
            :src="getImageUrl(item)"
            :alt="item.title"
            @error="handleImageError"
            @load="handleImageLoad"
          />
          <!-- Debug: Show image URL -->
          <div class="debug-url">{{ getImageUrl(item) }}</div>
        </div>

        <div class="card-content">
          <h4 v-if="item.title" class="card-title">
            {{ item.title }}
          </h4>

          <p v-if="item.description || item.subtitle" class="card-subtitle">
            {{ item.description || item.subtitle }}
          </p>

          <a
            v-if="getLinkAction(item) || item.action_url"
            :href="getLinkAction(item)?.uri || item.action_url"
            target="_blank"
            rel="noopener noreferrer"
            class="card-link"
          >
            <span class="button-text">{{
              getLinkAction(item)?.text ||
              item.action_text ||
              $t('CONVERSATION.CARD.VIEW_MORE')
            }}</span>
            <svg
              class="button-icon"
              width="12"
              height="12"
              viewBox="0 0 12 12"
              fill="none"
            >
              <path
                d="M2 6h8M6 2l4 4-4 4"
                stroke="currentColor"
                stroke-width="1.5"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
            </svg>
          </a>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.messenger-card {
  .card-container {
    display: flex;
    gap: 16px;
    overflow-x: auto;
    padding: 12px 0;
    scroll-behavior: smooth;

    // Custom scrollbar styling
    &::-webkit-scrollbar {
      height: 6px;
    }

    &::-webkit-scrollbar-track {
      background: #f8fafc;
      border-radius: 3px;
    }

    &::-webkit-scrollbar-thumb {
      background: #cbd5e1;
      border-radius: 3px;

      &:hover {
        background: #94a3b8;
      }
    }

    .card-item {
      min-width: 280px;
      max-width: 320px;
      border-radius: 12px;
      overflow: hidden;
      background: #25282d !important;
      box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
      position: relative;

      .card-image {
        position: relative;
        height: 200px;
        overflow: hidden;

        img {
          width: 100%;
          height: 100%;
          object-fit: cover;
        }

        .debug-url {
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background: rgba(0, 0, 0, 0.9);
          color: white;
          font-size: 10px;
          padding: 12px;
          word-break: break-all;
          display: none;
          overflow-y: auto;
          backdrop-filter: blur(4px);
        }
      }

      .card-content {
        padding: 20px;

        .card-title {
          font-size: 18px;
          font-weight: 600;
          margin: 0 0 8px 0;
          color: #fcffff;
          line-height: 1.4;
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto,
            sans-serif;
        }

        .card-subtitle {
          font-size: 14px;
          color: #a2a5aa;
          margin: 0 0 20px 0;
          line-height: 1.5;
          font-weight: 400;
        }

        .card-link {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 8px;
          font-size: 14px;
          font-weight: 500;
          color: #fcffff;
          text-decoration: none;
          padding: 12px 18px;
          background: #2b2f38;
          border-radius: 8px;
          border: none;
          cursor: pointer;
          width: 100%;

          .button-text {
            position: relative;
          }

          .button-icon {
            position: relative;
            transition: transform 0.2s ease;
          }

          &:hover {
            background: #1e212a;

            .button-icon {
              transform: translateX(2px);
            }
          }

          &:active {
            background: #16191f;
          }
        }
      }
    }
  }
}

// Remove debug styling in production
@media (min-width: 1px) {
  .debug-url {
    display: none !important;
  }
}
</style>
