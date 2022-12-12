import Vue from 'vue'
import VueFormulate from '@braid/vue-formulate'
<% if (options.configPath) { %>
import options from '<%= options.configPath %>'
<% } else { %>
const options = {}
<% } %>

Vue.use(VueFormulate, options)
