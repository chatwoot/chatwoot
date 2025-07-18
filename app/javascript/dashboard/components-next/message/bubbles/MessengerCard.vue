<template>
  <div class="messenger-card">
    <div class="card-container">
      <div 
        v-for="(item, index) in items" 
        :key="index"
        class="card-item"
      >
        <div v-if="getImageUrl(item)" class="card-image">
          <img 
            :src="getImageUrl(item)" 
            :alt="item.title"
            @error="handleImageError"
            @load="handleImageLoad"
          />
          <!-- Debug: Show image URL -->
          <div class="debug-url">{{ getImageUrl(item) }}</div>
          <!-- Gradient overlay for better text readability -->
          <div class="image-overlay"></div>
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
            <span class="button-text">{{ getLinkAction(item)?.text || item.action_text || $t('CONVERSATION.CARD.VIEW_MORE') }}</span>
            <svg class="button-icon" width="12" height="12" viewBox="0 0 12 12" fill="none">
              <path d="M2 6h8M6 2l4 4-4 4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          </a>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  items: {
    type: Array,
    required: true,
    default: () => []
  }
});

const handleImageError = (event) => {
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

const handleImageLoad = (event) => {
  // Hide debug URL when image loads successfully
  const debugUrl = event.target.nextElementSibling;
  if (debugUrl && debugUrl.classList.contains('debug-url')) {
    debugUrl.style.display = 'none';
  }
};

const getImageUrl = (item) => {
  // Support multiple field name formats: mediaUrl (camelCase), media_url (snake_case), image_url
  let url = item.mediaUrl || item.media_url || item.image_url;
  if (url) {
    // Decode any escaped characters
    url = url.replace(/\\u0026/g, '&');
    
    // Convert Google Drive URLs to direct image URLs
    if (url.includes('drive.google.com')) {
      // Extract file ID from various Google Drive URL formats
      let fileId = null;
      
      // Format: https://drive.google.com/uc?id=FILE_ID&export=download
      if (url.includes('uc?id=')) {
        fileId = url.match(/uc\?id=([a-zA-Z0-9_-]+)/)?.[1];
      }
      // Format: https://drive.google.com/file/d/FILE_ID/view
      else if (url.includes('/file/d/')) {
        fileId = url.match(/\/file\/d\/([a-zA-Z0-9_-]+)/)?.[1];
      }
      // Format: https://drive.google.com/open?id=FILE_ID
      else if (url.includes('open?id=')) {
        fileId = url.match(/open\?id=([a-zA-Z0-9_-]+)/)?.[1];
      }
      
      if (fileId) {
        // Convert to direct image URL format
        url = `https://drive.google.com/thumbnail?id=${fileId}&sz=w400-h300-c`;
      }
    }
    
    return url;
  }
  return null;
};

const getLinkAction = (item) => {
  if (!item.actions || !Array.isArray(item.actions)) return null;
  return item.actions.find(action => action.type === 'link');
};
</script>

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
      border-radius: 16px;
      overflow: hidden;
      background: linear-gradient(145deg, #ffffff 0%, #f8fafc 100%);
      box-shadow: 
        0 4px 20px rgba(0, 0, 0, 0.08),
        0 1px 3px rgba(0, 0, 0, 0.05);
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      border: 1px solid rgba(226, 232, 240, 0.8);
      position: relative;
      
      &:hover {
        transform: translateY(-8px);
        box-shadow: 
          0 12px 40px rgba(0, 0, 0, 0.15),
          0 4px 12px rgba(0, 0, 0, 0.1);
        border-color: rgba(99, 102, 241, 0.2);
      }
      
      .card-image {
        position: relative;
        height: 180px;
        overflow: hidden;
        
        img {
          width: 100%;
          height: 100%;
          object-fit: cover;
          transition: transform 0.3s ease;
        }
        
        .image-overlay {
          position: absolute;
          bottom: 0;
          left: 0;
          right: 0;
          height: 40%;
          background: linear-gradient(
            to top,
            rgba(0, 0, 0, 0.3) 0%,
            rgba(0, 0, 0, 0.1) 50%,
            transparent 100%
          );
          pointer-events: none;
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
      
      &:hover .card-image img {
        transform: scale(1.05);
      }
      
      .card-content {
        padding: 20px;
        
        .card-title {
          font-size: 18px;
          font-weight: 700;
          margin: 0 0 8px 0;
          color: #1e293b;
          line-height: 1.3;
          letter-spacing: -0.025em;
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        }
        
        .card-subtitle {
          font-size: 14px;
          color: #64748b;
          margin: 0 0 20px 0;
          line-height: 1.5;
          font-weight: 400;
          letter-spacing: -0.01em;
        }
        
        .card-link {
          display: inline-flex;
          align-items: center;
          gap: 8px;
          font-size: 14px;
          font-weight: 600;
          color: #ffffff;
          text-decoration: none;
          padding: 12px 20px;
          background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
          border-radius: 12px;
          border: none;
          cursor: pointer;
          transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
          box-shadow: 
            0 2px 8px rgba(99, 102, 241, 0.3),
            inset 0 1px 0 rgba(255, 255, 255, 0.1);
          position: relative;
          overflow: hidden;
          
          .button-text {
            position: relative;
            z-index: 2;
          }
          
          .button-icon {
            position: relative;
            z-index: 2;
            transition: transform 0.2s ease;
          }
          
          &::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: linear-gradient(135deg, #5b58eb 0%, #7c3aed 100%);
            opacity: 0;
            transition: opacity 0.2s ease;
            z-index: 1;
          }
          
          &:hover {
            transform: translateY(-2px);
            box-shadow: 
              0 4px 16px rgba(99, 102, 241, 0.4),
              inset 0 1px 0 rgba(255, 255, 255, 0.2);
            
            &::before {
              opacity: 1;
            }
            
            .button-icon {
              transform: translateX(2px);
            }
          }
          
          &:active {
            transform: translateY(0);
            box-shadow: 
              0 2px 8px rgba(99, 102, 241, 0.3),
              inset 0 1px 0 rgba(255, 255, 255, 0.1);
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