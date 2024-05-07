<template>
  <div>
    <div 
      v-if="showSmartActions"
      v-on-clickaway="hideSmartAction"
      class="smart-actions-panel left-3 rtl:left-auto rtl:right-3 bottom-16 w-64 absolute z-30 rounded-md shadow-xl bg-white dark:bg-slate-800 py-5 px-5 border border-slate-25 dark:border-slate-700"
      :class="{ 'block visible': showSmartActions }"
      >
      <woot-button
        size="tiny"
        variant="clear"
        color-scheme="secondary"
        icon="dismiss"
        @click="hideSmartAction"
        class="float-right"
      />
      <div v-if="smartActions.length" class="mt-8">
        <h1 class="text-xl break-words overflow-hidden whitespace-nowrap font-medium text-ellipsis text-black-900 dark:text-slate-100 mb-0">
          {{ smartActions.length }} smart actions detected from conversation
        </h1>
        <p class="text-slate-400 dark:text-slate-300">Proceed with each action and let AI do the rest e.g auto fill form</p>
      </div>
      <div v-else>
        <p class="text-slate-400 dark:text-slate-300">No smart actions found.</p>
      </div>
      <div class="mt-3 action-holder">
        <div v-for="action in smartActions" v-bind:key="action.index" class="smart-action-item bg-slate-25 dark:bg-slate-900 m-0 h-full min-h-0">
          <div class="capitalize float-right rounded-full bg-green-100 text-xs px-3 py-2 dark:text-slate-300 text-slate-700">{{ action.intent_type }}</div>
          <h1 class="text-black-900 dark:text-slate-400 text-2xl font-medum mb-2">{{ action.name }}</h1>
          <p class="text-slate-400 dark:text-slate-300 mb-3">{{ action.description }}</p>
          <div class="text-slate-800 dark:text-slate-300 action-from-to mb-3">
            <span class="mr-2">{{ action.from }}</span>
            <span class="mr-2"> → </span>
            <span class="mr-2">{{ action.to }}</span>
          </div>
          <div>
            <woot-button
                size="tiny"
                class="smart-action-button"
                @click="toggleBookingPanel"
              >
              {{ action.label }}
              <fluent-icon 
                size="16"
                class="-mt-0.5 align-middle text-slate-600 dark:text-slate-300 inline-block"
                icon="arrow-up-right"
                >
              </fluent-icon>
            </woot-button>
          </div>
        </div>
      </div>
      <div class="absolute bottom-0 w-11/12">
        <woot-button
          size="medium"
          variant="clear"
          color-scheme="secondary"
          icon="settings"
          @click="openSetting"
          class="float-right"
        />
        <div class="flex smart-help-chevron text-slate-400 dark:text-slate-300 text-xs py-2" @click="toggleHelp">
          <fluent-icon v-if="openHelp" size="10" icon="chevron-down" class="mt-1 mr-2"/>
          <fluent-icon v-else size="10" icon="chevron-right" type="solid" class="mt-1 mr-2"/>
          Learn what is mart action and how it works
        </div>
        <p class="text-sm text-slate-800 dark:text-slate-300" v-if="openHelp">
          Smart action is an AI-powered feature designed to assist support agents in real-time conversation
          analysis. With this new tool, agents can seamlessly detect key actions and cues during ongoing conversations,
          empowering them to provide faster, more accurate assistance to customers.
        </p>
      </div>
    </div>
    <div v-if="showBookingPanel"
      v-on-clickaway="hideBookingPanel"
      class="booking-panel left-3 rtl:left-auto rtl:right-3 bottom-16 w-64 absolute z-30 rounded-md shadow-xl bg-white dark:bg-slate-800 py-2 px-2 border border-slate-25 dark:border-slate-700"
      :class="{ 'block visible': showBookingPanel }"
      >
      <iframe id="booking-iframe" src=""></iframe>
    </div>
  </div>
</template>
<script>
import WootButton from '../../ui/WootButton.vue'
import { mixin as clickaway } from 'vue-clickaway';
import { mapGetters } from 'vuex';

export default {
  components: { WootButton },
  mixins: [clickaway],
  data() {
    return {
      showBookingPanel: false,
      openHelp: false,
    }
  },
  computed: {
    ...mapGetters({
      showSmartActions: 'showSmartActions',
      smartActions: 'getSmartActions'
    })
  },
  
  methods: {
    toggleBookingPanel() {
      this.showBookingPanel = !this.showBookingPane;

      setTimeout(function(){
        const iframe = document.getElementById('booking-iframe');
        // TODO: url from smart action
        iframe.src = 'https://www.digitaltolk.se/bokning';
      }, 500)
    },
    hideBookingPanel(){
      this.showBookingPanel = false;
    },
    toggleHelp(){
      this.openHelp = !this.openHelp;
    },
    openSetting(){
      console.log('open settings')
    },
    hideSmartAction(){
      if (!this.showBookingPanel) {
        this.$store.dispatch('showSmartActions', false)
      }
    }
  }
}

</script>
<style scoped lang="scss">
  .smart-actions-panel{
    position: fixed;
    bottom: 0;
    z-index: 99;
    left: 20px;
    width: 96%;
    max-width: 600px;
    color: white;
    height: 600px;
    border-radius: 5px;
  }
  .action-holder{
    max-height: 350px;
    overflow-y: auto;
  }
  .smart-action-item{
    padding: 15px;
    border-radius: 5px;
    margin-bottom: 10px;
    border: 1px solid #f1f2f4;
  }
  .action-from-to{
    font-size: var(--font-size-mini);
  }
  .smart-action-button{
    background: #343132;  
  }
  .smart-action-button:hover{
    background: #3a393a;
  }
  .smart-help-chevron{
    cursor: pointer;
  }
  .booking-panel{
    position: fixed;
    bottom: 0;
    left: 0;
    z-index: 100;
    width: 100%;
    max-width: 700px;
    height: 100vh;
  }
  #booking-iframe{
    width: 100%;
    height: 100vh;
  }
</style>