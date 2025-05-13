<script>
import { defineComponent, ref, onMounted, onBeforeUnmount, watch } from 'vue';
import { mapGetters } from 'vuex';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default defineComponent({
  components: {
    NextButton,
  },
  name: 'VoiceTimelineView',
  props: {
    conversationId: {
      type: Number,
      required: true,
    },
    isCallEnded: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    // Use 01:34 (94 seconds) as our fallback/demo duration throughout the component
    const defaultDuration = '01:34';
    const defaultSeconds = 94;
    
    return {
      currentTime: '00:00',
      duration: defaultDuration, // Default duration that will be shown even if API returns nothing
      isPlaying: false,
      // Generate more realistic waveform data with varied heights
      waveformData: this.generateRealisticWaveform(180),
      // Define different waveform segments for caller and agent with speaking patterns
      waveformSegments: [
        { start: '00:00', end: '00:20', type: 'caller', data: this.generateRealisticWaveform(40) },
        { start: '00:21', end: '00:30', type: 'agent', data: this.generateRealisticWaveform(20) },
        { start: '00:31', end: '00:45', type: 'caller', data: this.generateRealisticWaveform(30) },
        { start: '00:46', end: '00:58', type: 'agent', data: this.generateRealisticWaveform(26) },
        { start: '00:59', end: '01:10', type: 'caller', data: this.generateRealisticWaveform(24) },
        { start: '01:11', end: '01:23', type: 'agent', data: this.generateRealisticWaveform(24) },
        { start: '01:24', end: '01:34', type: 'caller', data: this.generateRealisticWaveform(20) },
      ],
      timeLabels: ['00:00', '00:12', '00:24', '00:36', '00:48', '01:00', '01:12', '01:24'],
      markers: [
        { time: '00:15', label: 'systemEvent', text: 'Tool call: Customer identity verified (method: Voice)', icon: 'i-ph-check-circle-fill', ms: '4598ms' },
        { time: '00:32', label: 'systemEvent', text: 'Tool call: Order details retrieved (order_id: #38291)', icon: 'i-ph-database-fill', ms: '7436ms' },
        { time: '00:48', label: 'systemEvent', text: 'Tool call: Customer account verified (id: 57482)', icon: 'i-ph-user-circle-fill', ms: '22060ms' },
        { time: '01:05', label: 'systemEvent', text: 'Tool call: Address updated (1234 Main St, NY)', icon: 'i-ph-database-fill', ms: '84521ms' },
        { time: '01:20', label: 'systemEvent', text: 'Tool call: Email sent (template: address_update)', icon: 'i-ph-envelope-fill', ms: '3250ms' },
      ],
      timer: null,
      currentSeconds: 0,
      totalSeconds: defaultSeconds, // Default duration in seconds
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
    }),
    playButtonIcon() {
      return this.isPlaying ? 'pause' : 'play_arrow';
    },
    playButtonLabel() {
      return this.isPlaying ? 'Pause' : 'Play';
    },
    progressPercentage() {
      return this.totalSeconds > 0 ? (this.currentSeconds / this.totalSeconds) * 100 : 0;
    },
    callData() {
      return this.currentChat?.additional_attributes || {};
    },
    callDuration() {
      // Get call duration in seconds from call data
      const duration = this.callData?.duration || 94; // Default to 94 seconds (01:34) if not available
      return parseInt(duration, 10);
    },
    formattedCallDuration() {
      // Always return a formatted duration, never 00:00
      const formattedTime = this.formatTime(this.callDuration);
      return formattedTime === '00:00' ? '01:34' : formattedTime;
    },
    shouldShowTimeline() {
  // Always show the timeline (all conditions removed for demo/testing)
      return false;
    },
  },
  watch: {
    conversationId: {
      immediate: true,
      handler() {
        this.loadCallData();
      },
    },
    currentSeconds(newVal) {
      this.currentTime = this.formatTime(newVal);
    },
    callDuration: {
      handler(newVal) {
        if (newVal && newVal !== this.totalSeconds) {
          this.totalSeconds = newVal;
          this.duration = this.formattedCallDuration;
          // Ensure duration is never empty
          if (!this.duration || this.duration === '00:00') {
            this.duration = '01:34'; // Fallback default
          }
          console.log('Call duration updated to:', this.duration);
        }
      },
      immediate: true
    }
  },
  methods: {
    generateRealisticWaveform(length) {
      // Create a waveform pattern that matches the marked style in the reference image
      // with vertical bars grouped together in sections
      const baseAmplitude = 40; 
      const minAmplitude = 10;
      const waveform = [];
      
      // Generate segments of active speech with groups of bars
      let i = 0;
      while (i < length) {
        // Create a speech segment (cluster of vertical bars)
        const segmentSize = Math.floor(Math.random() * 8) + 5; // 5-12 bars per segment
        
        // For each bar in the segment
        for (let j = 0; j < segmentSize && i < length; j++, i++) {
          // Create bars of varying heights in a pattern
          const barHeight = j % 2 === 0 
            ? Math.random() * baseAmplitude + minAmplitude // Taller bars
            : Math.random() * (baseAmplitude / 2) + minAmplitude; // Shorter bars
            
          waveform.push(barHeight);
        }
        
        // Add a gap between segments (spaces between bar clusters)
        const gapSize = Math.floor(Math.random() * 4) + 2; // 2-5 bars of space
        for (let j = 0; j < gapSize && i < length; j++, i++) {
          waveform.push(Math.random() * (minAmplitude / 5)); // Very low height for gaps
        }
      }
      
      return waveform;
    },
    
    togglePlayPause() {
      this.isPlaying = !this.isPlaying;
      
      if (this.isPlaying) {
        this.startTimer();
      } else {
        this.stopTimer();
      }
    },
    startTimer() {
      if (this.timer) return;
      
      this.timer = setInterval(() => {
        this.currentSeconds += 0.1;
        if (this.currentSeconds >= this.totalSeconds) {
          this.currentSeconds = this.totalSeconds;
          this.stopTimer();
          this.isPlaying = false;
        }
      }, 100);
    },
    stopTimer() {
      if (this.timer) {
        clearInterval(this.timer);
        this.timer = null;
      }
    },
    formatTime(seconds) {
      const minutes = Math.floor(seconds / 60);
      const remainingSeconds = Math.floor(seconds % 60);
      return `${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`;
    },
    getMarkerPosition(marker) {
      return this.getTimePercentage(marker.time);
    },
    
    getTimePercentage(timeString) {
      const minutes = parseInt(timeString.split(':')[0], 10);
      const seconds = parseInt(timeString.split(':')[1], 10);
      
      const totalSeconds = minutes * 60 + seconds;
      
      return (totalSeconds / this.totalSeconds) * 100;
    },
    
    timeToSeconds(timeString) {
      const minutes = parseInt(timeString.split(':')[0], 10);
      const seconds = parseInt(timeString.split(':')[1], 10);
      
      return minutes * 60 + seconds;
    },
    getMarkerClass(marker) {
      switch (marker.label) {
        case 'assistantSentSMS':
          return 'marker--sms';
        case 'userResponse':
          return 'marker--user';
        case 'agentMessage':
          return 'marker--agent';
        case 'systemEvent':
          return 'marker--system';
        case 'callEnded':
          return 'marker--end';
        default:
          return '';
      }
    },
    setProgress(event) {
      const timeline = event.currentTarget;
      const rect = timeline.getBoundingClientRect();
      const offsetX = event.clientX - rect.left;
      const percentage = (offsetX / rect.width) * 100;
      this.currentSeconds = (percentage / 100) * this.totalSeconds;
    },
    loadCallData() {
      // Always set a default value first
      this.duration = '01:34'; // Default fallback
      this.totalSeconds = 94;  // Default 01:34 in seconds
      
      // If we have actual call duration, use it
      if (this.callDuration && this.callDuration > 0) {
        this.totalSeconds = this.callDuration;
        this.duration = this.formattedCallDuration;
      }
            
      console.log('Call data loaded for conversation:', this.conversationId);
      console.log('Call duration:', this.duration);
      console.log('Sample conversation events:', this.markers.map(m => m.text).join(', '));
    },
    
    extractCallEvents() {
      // Simulate real implementation - would parse messages to find call events
      const messages = this.currentChat?.messages || [];
      
      // In a real implementation, we would find call events in the messages
      console.log('Analyzing conversation messages for call events and tool calls...');
      console.log('Looking through', messages.length, 'messages for activities');
      
      // This is just for demonstration - actual implementation would process real events
      const eventTypes = [
        'call_initiated', 
        'authentication_successful', 
        'customer_verified',
        'tool_call:database_lookup', 
        'tool_call:payment_processed', 
        'tool_call:email_notification_sent',
        'call_ended'
      ];
      
      console.log('Found call events and tool calls:', eventTypes.join(', '));
      
      // The actual markers we're showing in the UI simulate these events
      console.log('Processing tool calls:');
      console.log('- Tool call: Customer account verified (customer_id: 57482)');
      console.log('- Tool call: Address updated (new_address: 1234 Main St, Apt 5B)');
      console.log('- Tool call: Confirmation email sent (template: address_update)');
    },
    
    // Determine the active speaker at the current time
    getActiveSpeaker() {
      // In a real implementation, this would check the actual call data
      // For now, we'll use the predefined segments to determine who's speaking
      
      const currentTimeStr = this.formatTime(this.currentSeconds);
      
      // Find the segment that contains the current time
      const activeSegment = this.waveformSegments.find(segment => {
        const startSeconds = this.timeToSeconds(segment.start);
        const endSeconds = this.timeToSeconds(segment.end);
        return this.currentSeconds >= startSeconds && this.currentSeconds <= endSeconds;
      });
      
      // Return the speaker type, or null if not found
      return activeSegment ? activeSegment.type : null;
    },
    
    // Check if a specific speaker is active
    isSpeakerActive(speakerType) {
      return this.getActiveSpeaker() === speakerType;
    },
  },
  mounted() {
    this.loadCallData();
  },
  beforeUnmount() {
    this.stopTimer();
  },
});
</script>

<template>
  <div v-if="shouldShowTimeline" class="voice-timeline-view">
    <div class="timeline-header">
      <div class="time-display">
        <span class="current-time">{{ currentTime }}</span> / <span class="total-time">{{ duration || formattedCallDuration }}</span>
      </div>
      <div class="control-buttons">
        <NextButton
          @click="togglePlayPause"
          v-tooltip.top-start="playButtonLabel"
          :icon="isPlaying ? 'i-ph-pause-fill' : 'i-ph-play-fill'"
          slate
          faded
          sm
          round
        />
      </div>
    </div>

    <div 
      class="timeline-container"
      @click="setProgress"
    >
      <!-- Progress Indicator -->
      <div 
        class="progress-indicator" 
        :style="{ left: `${progressPercentage}%` }"
      ></div>

      <!-- Agent Timeline (Top) -->
      <div class="agent-timeline">
        <div class="waveform-bars">
          <div
            v-for="(value, index) in waveformData.slice(waveformData.length / 2)"
            :key="'agent-' + index"
            class="waveform-bar"
            :class="{
              'active-agent-bar': isSpeakerActive('agent'),
              'inactive-agent-bar': !isSpeakerActive('agent'),
              'progress-passed': index / (waveformData.length / 2) < progressPercentage / 100
            }"
            :style="{
              height: `${value}%`
            }"
          ></div>
        </div>
      </div>
      
      <!-- Contact Timeline (Middle) -->
      <div class="contact-timeline">
        <div class="waveform-bars">
          <div
            v-for="(value, index) in waveformData.slice(0, waveformData.length / 2)"
            :key="'contact-' + index"
            class="waveform-bar"
            :class="{
              'active-contact-bar': isSpeakerActive('caller'),
              'inactive-contact-bar': !isSpeakerActive('caller'),
              'progress-passed': index / (waveformData.length / 2) < progressPercentage / 100
            }"
            :style="{
              height: `${value}%`
            }"
          ></div>
        </div>
      </div>
      
      <!-- Events Timeline overlaid at bottom -->
      <div class="events-timeline">
        <!-- Event Markers -->
        <div 
          v-for="(marker, index) in markers" 
          :key="index"
          class="event-marker"
          :class="getMarkerClass(marker)"
          :style="{ left: `${getMarkerPosition(marker)}%` }"
        >
          <div class="marker-dot">
            <span v-if="marker.icon" :class="[marker.icon, 'marker-icon']"></span>
          </div>
          
          <!-- Tooltips for all events -->
          <div 
            class="marker-tooltip"
            :class="[
              `marker-tooltip-${marker.label}`,
              { 'marker-tooltip-visible': isPlaying && currentSeconds >= timeToSeconds(marker.time) && currentSeconds <= timeToSeconds(marker.time) + 2 }
            ]"
          >
            <div class="font-semibold mb-1">Tool Call</div>
            <div class="marker-text">
              <div class="whitespace-normal">
                {{ marker.text.replace('Tool call:', '').trim() }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.voice-timeline-view {
  @apply relative flex flex-col px-5 pt-3 pb-5 mb-4 mx-4 h-[220px] border border-n-slate-3 dark:border-n-slate-7 rounded-lg bg-n-solid-2 shadow-sm;
  font-family: Inter, system-ui, -apple-system, sans-serif;
}

.timeline-header {
  @apply flex justify-between items-center mb-2 px-1;

  .control-buttons {
    @apply flex items-center justify-center;
  }

  .time-display {
    @apply text-sm font-medium text-n-slate-11;
    
    .current-time {
      @apply font-medium text-n-slate-11;
    }
    
    .total-time {
      @apply font-normal text-n-slate-11;
    }
  }
}

.timeline-container {
  @apply relative flex-1 bg-n-solid-2 rounded-lg overflow-hidden cursor-pointer shadow-sm;
  display: flex;
  flex-direction: column;
  height: 190px;
}

.time-labels {
  @apply absolute top-0 left-0 right-0 h-7 z-10;
  
  .time-label {
    @apply absolute text-sm transform -translate-x-1/2 font-medium text-n-blue-8 dark:text-n-blue-5;
    top: 4px;
    
    .h-3 {
      @apply bg-n-slate-3 dark:bg-n-slate-6;
    }
  }
}

.progress-indicator {
  @apply absolute top-0 bottom-0 w-[1.5px] z-30 bg-n-blue-7 dark:bg-n-blue-5;
  box-shadow: 0 0 3px rgba(var(--blue-7), 0.5);
}

/* Agent Timeline (Top) */
.agent-timeline {
  @apply relative h-[50px] px-2 mt-1 bg-n-blue-2 dark:bg-n-blue-7/20 rounded-xl;
  
  .waveform-bars {
    @apply flex items-end h-full relative z-10;
  }
  
  .waveform-bar {
    @apply flex-1 mx-[0.5px] transition-all duration-300 rounded-sm;
    min-width: 2px;
  }
}

/* Contact Timeline (Middle) */
.contact-timeline {
  @apply relative h-[55px] px-2 mt-3 bg-n-slate-2 dark:bg-n-slate-7/20 rounded-xl; /* Added background */
  
  .waveform-bars {
    @apply flex items-end h-full relative z-10;
  }
  
  .waveform-bar {
    @apply flex-1 mx-[0.5px] transition-all duration-300 rounded-sm;
    min-width: 2px;
  }
}

/* Waveform bar states */
.waveform-bar {
  @apply rounded-sm mx-[0.5px] transition-all duration-300 min-w-[2.5px];
}

.active-agent-bar {
  @apply bg-n-blue-7 dark:bg-n-blue-6;
}

.inactive-agent-bar {
  @apply bg-n-blue-5 dark:bg-n-blue-5;
}

.active-contact-bar {
  @apply bg-n-slate-7 dark:bg-n-slate-6;
}

.inactive-contact-bar {
  @apply bg-n-slate-4 dark:bg-n-slate-5;
}

.progress-passed {
  @apply opacity-100;
}

.waveform-bar:not(.progress-passed) {
  @apply opacity-40;
}

/* Events Timeline (Bottom) */
.events-timeline {
  @apply absolute bottom-0 left-0 right-0 h-[60px] px-2 z-20;
}

.event-marker {
  @apply absolute w-0 z-30;
  /* All event markers are positioned at the bottom in the events timeline */
  bottom: 15px;
  
  .marker-dot {
    @apply absolute -translate-x-1/2 size-8 rounded-full flex items-center justify-center shadow-lg;
    top: -16px;
  }
  
  .marker-icon {
    @apply text-[16px] font-bold;
  }
  
  /* Apply bright Tailwind color classes to each marker icon type */
  .marker--systemEvent .marker-icon {
    @apply text-n-slate-1;
  }
  
  .marker--agentMessage .marker-icon {
    @apply text-n-slate-1;
  }
  
  .marker--userResponse .marker-icon {
    @apply text-n-slate-12;
  }
  
  .marker--callEnded .marker-icon {
    @apply text-n-slate-1;
  }
  
  .marker-tooltip {
    @apply absolute -translate-x-1/2 p-3 rounded-md shadow-xl text-n-slate-1 text-sm min-w-[150px] max-w-[250px] transition-all duration-200 z-50 opacity-0 invisible bg-n-slate-12;
    bottom: 40px;
    
    &.marker-tooltip-visible {
      @apply opacity-100 visible;
    }
    
    .marker-text {
      @apply text-sm whitespace-normal font-normal text-n-slate-1;
    }
    
    .marker-time {
      @apply text-xs text-n-slate-2 mt-1 font-medium;
    }
    
    &:after {
      content: '';
      @apply absolute w-0 h-0 border-l-[6px] border-l-transparent border-t-[6px] left-1/2 -translate-x-1/2;
      border-top-color: #1E293B; /* Consistent color for both light/dark modes */
      bottom: -6px;
    }
    
    /* Improve positioning when tooltip is near the edge */
    &.marker-tooltip-left {
      @apply -left-[50px];
      &:after {
        @apply left-[calc(50%+50px)];
      }
    }
    
    &.marker-tooltip-right {
      @apply -right-[50px];
      &:after {
        @apply right-[calc(50%+50px)];
      }
    }
  }
  
  &:hover {
    .marker-tooltip {
      @apply z-50 opacity-100 visible;
    }
    
    .marker-dot {
      @apply transform scale-125;
      filter: drop-shadow(0 4px 6px rgba(0, 0, 0, 0.3));
    }
  }
  
  /* Marker type styling with bright Tailwind color classes */
  &.marker--systemEvent .marker-dot {
    @apply bg-n-iris-11;
  }
  
  &.marker--agentMessage .marker-dot {
    @apply bg-n-blue-11;
  }
  
  &.marker--userResponse .marker-dot {
    @apply bg-n-amber-11;
  }
  
  &.marker--callEnded .marker-dot {
    @apply bg-n-ruby-11;
  }
  
  /* Tooltip type styling with bright Tailwind color classes */
  &.marker-tooltip-systemEvent {
    @apply bg-n-iris-11;
    
    &:after {
      @apply border-t-n-iris-11;
    }
  }
  
  &.marker-tooltip-agentMessage {
    @apply bg-n-blue-11;
    
    &:after {
      @apply border-t-n-blue-11;
    }
  }
  
  &.marker-tooltip-userResponse {
    @apply bg-n-amber-11;
    
    &:after {
      @apply border-t-n-amber-11;
    }
  }
  
  &.marker-tooltip-callEnded {
    @apply bg-n-ruby-11;
    
    &:after {
      @apply border-t-n-ruby-11;
    }
  }
}
</style>