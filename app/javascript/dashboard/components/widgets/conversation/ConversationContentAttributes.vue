<template>
  <div v-if="hasContentAttributes" class="content-attributes-panel">
    <h4 class="panel-title">
      <i class="icon ion-ios-analytics"></i>
      Conversation Insights
    </h4>
    
    <!-- Debug: Show raw data -->
    <div class="debug-section">
      <h5>Debug - Raw Content Attributes:</h5>
      <pre>{{ JSON.stringify(contentAttributes, null, 2) }}</pre>
    </div>
    
    <!-- Conversation Context -->
    <div v-if="conversationContext" class="attribute-section">
      <h5>Context</h5>
      <div class="attribute-row">
        <span class="label">Source:</span>
        <span class="value">{{ conversationContext.source_type }}</span>
      </div>
      <div class="attribute-row">
        <span class="label">Page:</span>
        <span class="value">{{ conversationContext.initial_page }}</span>
      </div>
      <div class="attribute-row">
        <span class="label">Referrer:</span>
        <span class="value">{{ conversationContext.referrer }}</span>
      </div>
      <div class="attribute-row">
        <span class="label">Pages Visited:</span>
        <span class="value">{{ conversationContext.pages_visited }}</span>
      </div>
    </div>
    
    <!-- Interaction Patterns -->
    <div v-if="interactionPatterns" class="attribute-section">
      <h5>Interaction Metrics</h5>
      <div class="attribute-row">
        <span class="label">Messages:</span>
        <span class="value">{{ interactionPatterns.messages_count }}</span>
      </div>
      <div class="attribute-row">
        <span class="label">Avg Response Time:</span>
        <span class="value">{{ formatResponseTime(interactionPatterns.agent_response_time) }}</span>
      </div>
      <div class="attribute-row">
        <span class="label">Last Activity:</span>
        <span class="value">{{ interactionPatterns.last_activity_type }}</span>
      </div>
    </div>

    <!-- Resolution Context -->
    <div v-if="resolutionContext" class="attribute-section">
      <h5>Resolution Details</h5>
      <div class="attribute-row">
        <span class="label">Category:</span>
        <span class="value badge" :class="getCategoryClass(resolutionContext.topic_category)">
          {{ resolutionContext.topic_category }}
        </span>
      </div>
      <div class="attribute-row">
        <span class="label">Complexity:</span>
        <span class="value badge" :class="getComplexityClass(resolutionContext.complexity_level)">
          {{ resolutionContext.complexity_level }}
        </span>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ConversationContentAttributes',
  props: {
    conversation: {
      type: Object,
      required: true,
    },
  },
  
  computed: {
    contentAttributes() {
      return this.conversation.content_attributes || {};
    },
    
    hasContentAttributes() {
      return Object.keys(this.contentAttributes).length > 0;
    },
    
    conversationContext() {
      return this.contentAttributes.conversation_context;
    },
    
    interactionPatterns() {
      return this.contentAttributes.interaction_patterns;
    },

    resolutionContext() {
      return this.contentAttributes.resolution_context;
    },
  },
  
  methods: {
    formatResponseTime(seconds) {
      if (!seconds) return 'N/A';
      if (seconds < 60) return `${Math.round(seconds)}s`;
      if (seconds < 3600) return `${Math.round(seconds / 60)}m`;
      return `${Math.round(seconds / 3600)}h`;
    },

    getCategoryClass(category) {
      const classes = {
        billing: 'badge--warning',
        technical: 'badge--danger',
        general: 'badge--info',
        complaint: 'badge--alert'
      };
      return classes[category] || 'badge--secondary';
    },
    
    getComplexityClass(complexity) {
      const classes = {
        simple: 'badge--success',
        moderate: 'badge--warning',
        complex: 'badge--danger'
      };
      return classes[complexity] || 'badge--secondary';
    },
  },
};
</script>

<style scoped>
.content-attributes-panel {
  padding: 16px;
  background: #f8f9fa;
  border-radius: 8px;
  margin-bottom: 16px;
  border: 1px solid #e5e7eb;
}

.panel-title {
  display: flex;
  align-items: center;
  margin-bottom: 16px;
  font-size: 14px;
  font-weight: 600;
  color: #1f2937;
}

.panel-title .icon {
  margin-right: 8px;
  color: #6b7280;
}

.debug-section {
  margin-bottom: 16px;
  padding: 12px;
  background: #fff;
  border-radius: 4px;
  border: 1px solid #d1d5db;
}

.debug-section h5 {
  margin: 0 0 8px 0;
  font-size: 11px;
  font-weight: 600;
  color: #6b7280;
  text-transform: uppercase;
}

.debug-section pre {
  font-size: 10px;
  margin: 0;
  white-space: pre-wrap;
  word-break: break-all;
  color: #374151;
}

.attribute-section {
  margin-bottom: 16px;
}

.attribute-section h5 {
  font-size: 12px;
  font-weight: 600;
  color: #374151;
  margin-bottom: 8px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.attribute-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 6px 0;
  font-size: 13px;
  border-bottom: 1px solid #f3f4f6;
}

.attribute-row:last-child {
  border-bottom: none;
}

.attribute-row .label {
  color: #6b7280;
  font-weight: 500;
  flex-shrink: 0;
}

.attribute-row .value {
  color: #1f2937;
  font-weight: 400;
  max-width: 150px;
  word-break: break-all;
  text-align: right;
}

.badge {
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 10px;
  font-weight: 600;
  text-transform: capitalize;
  text-align: center;
  min-width: 60px;
}

.badge--success { background: #d1fae5; color: #065f46; }
.badge--warning { background: #fef3c7; color: #92400e; }
.badge--danger { background: #fecaca; color: #991b1b; }
.badge--info { background: #dbeafe; color: #1e40af; }
.badge--alert { background: #fed7d7; color: #c53030; }
.badge--secondary { background: #f3f4f6; color: #374151; }
</style>
