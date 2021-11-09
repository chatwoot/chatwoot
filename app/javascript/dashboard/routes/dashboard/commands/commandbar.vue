<template>
  <ninja-keys
    ref="ninjakeys"
    no-auto-loadicons
    :placeholder="placeholder"
    @selected="selected"
    @change="change"
  />
</template>

<script>
import 'ninja-keys';
import { frontendURL } from '../../../helper/URLHelper';

export default {
  data() {
    return {
      placeholder: 'Search or jump to',
      hotkeys: [
        {
          id: 'Home',
          title: 'Open Home',
          hotkey: 'cmd+h',
          icon: `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" role="img" class="ninja-icon ninja-icon--fluent" width="18" height="18" preserveAspectRatio="xMidYMid meet" viewBox="0 0 24 24"><g fill="none"><path d="M10.55 2.532a2.25 2.25 0 0 1 2.9 0l6.75 5.692c.507.428.8 1.057.8 1.72v9.803a1.75 1.75 0 0 1-1.75 1.75h-3.5a1.75 1.75 0 0 1-1.75-1.75v-5.5a.25.25 0 0 0-.25-.25h-3.5a.25.25 0 0 0-.25.25v5.5a1.75 1.75 0 0 1-1.75 1.75h-3.5A1.75 1.75 0 0 1 3 19.747V9.944c0-.663.293-1.292.8-1.72l6.75-5.692zm1.933 1.147a.75.75 0 0 0-.966 0L4.767 9.37a.75.75 0 0 0-.267.573v9.803c0 .138.112.25.25.25h3.5a.25.25 0 0 0 .25-.25v-5.5c0-.967.784-1.75 1.75-1.75h3.5c.966 0 1.75.783 1.75 1.75v5.5c0 .138.112.25.25.25h3.5a.25.25 0 0 0 .25-.25V9.944a.75.75 0 0 0-.267-.573l-6.75-5.692z" fill="currentColor"></path></g></svg>`,
          handler: () => {
            this.$router.push(
              frontendURL(`accounts/${this.accountId}/dashboard`)
            );
          },
        },
        {
          id: 'Contacts',
          title: 'Open Contacts',
          hotkey: 'cmd+p',
          icon: `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" role="img" class="ninja-icon ninja-icon--fluent" width="18" height="18" preserveAspectRatio="xMidYMid meet" viewBox="0 0 24 24"><g fill="none"><path d="M17.754 14a2.249 2.249 0 0 1 2.25 2.249v.575c0 .894-.32 1.76-.902 2.438c-1.57 1.834-3.957 2.739-7.102 2.739c-3.146 0-5.532-.905-7.098-2.74a3.75 3.75 0 0 1-.898-2.435v-.577a2.249 2.249 0 0 1 2.249-2.25h11.501zm0 1.5H6.253a.749.749 0 0 0-.75.749v.577c0 .536.192 1.054.54 1.461c1.253 1.468 3.219 2.214 5.957 2.214s4.706-.746 5.962-2.214a2.25 2.25 0 0 0 .541-1.463v-.575a.749.749 0 0 0-.749-.75zM12 2.004a5 5 0 1 1 0 10a5 5 0 0 1 0-10zm0 1.5a3.5 3.5 0 1 0 0 7a3.5 3.5 0 0 0 0-7z" fill="currentColor"></path></g></svg>`,
          handler: () => {
            this.$router.push(
              frontendURL(`accounts/${this.accountId}/contacts`)
            );
          },
        },
        {
          id: 'Reports',
          title: 'Open Reports',
          icon: `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" role="img" class="ninja-icon ninja-icon--fluent" width="18" height="18" preserveAspectRatio="xMidYMid meet" viewBox="0 0 24 24"><g fill="none"><path d="M16.749 2h4.554l.1.014l.099.028l.06.026c.08.034.153.085.219.15l.04.044l.044.057l.054.09l.039.09l.019.064l.014.064l.009.095v4.532a.75.75 0 0 1-1.493.102l-.007-.102V4.559l-6.44 6.44a.75.75 0 0 1-.976.073L13 11L9.97 8.09l-5.69 5.689a.75.75 0 0 1-1.133-.977l.073-.084l6.22-6.22a.75.75 0 0 1 .976-.072l.084.072l3.03 2.91L19.438 3.5h-2.69a.75.75 0 0 1-.742-.648l-.007-.102a.75.75 0 0 1 .648-.743L16.75 2zM3.75 17a.75.75 0 0 1 .75.75v3.5a.75.75 0 0 1-1.5 0v-3.5a.75.75 0 0 1 .75-.75zm5.75-3.25a.75.75 0 0 0-1.5 0v7.5a.75.75 0 0 0 1.5 0v-7.5zM13.75 15a.75.75 0 0 1 .75.75v5.5a.75.75 0 0 1-1.5 0v-5.5a.75.75 0 0 1 .75-.75zm5.75-4.25a.75.75 0 0 0-1.5 0v10.5a.75.75 0 0 0 1.5 0v-10.5z" fill="currentColor"></path></g></svg>`,
          children: [
            {
              id: 'Overview',
              title: 'Reports Overview',
              icon: `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" role="img" class="ninja-icon ninja-icon--fluent" width="18" height="18" preserveAspectRatio="xMidYMid meet" viewBox="0 0 24 24"><g fill="none"><path d="M16.749 2h4.554l.1.014l.099.028l.06.026c.08.034.153.085.219.15l.04.044l.044.057l.054.09l.039.09l.019.064l.014.064l.009.095v4.532a.75.75 0 0 1-1.493.102l-.007-.102V4.559l-6.44 6.44a.75.75 0 0 1-.976.073L13 11L9.97 8.09l-5.69 5.689a.75.75 0 0 1-1.133-.977l.073-.084l6.22-6.22a.75.75 0 0 1 .976-.072l.084.072l3.03 2.91L19.438 3.5h-2.69a.75.75 0 0 1-.742-.648l-.007-.102a.75.75 0 0 1 .648-.743L16.75 2zM3.75 17a.75.75 0 0 1 .75.75v3.5a.75.75 0 0 1-1.5 0v-3.5a.75.75 0 0 1 .75-.75zm5.75-3.25a.75.75 0 0 0-1.5 0v7.5a.75.75 0 0 0 1.5 0v-7.5zM13.75 15a.75.75 0 0 1 .75.75v5.5a.75.75 0 0 1-1.5 0v-5.5a.75.75 0 0 1 .75-.75zm5.75-4.25a.75.75 0 0 0-1.5 0v10.5a.75.75 0 0 0 1.5 0v-10.5z" fill="currentColor"></path></g></svg>`,
              handler: () => {
                this.$router.push(
                  frontendURL(`accounts/${this.accountId}/reports/overview`)
                );
              },
            },
            {
              id: 'Agent',
              title: 'Agent Reports',
              icon: `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" role="img" class="ninja-icon ninja-icon--fluent" width="18" height="18" preserveAspectRatio="xMidYMid meet" viewBox="0 0 24 24"><g fill="none"><path d="M4 13.999L13 14a2 2 0 0 1 1.995 1.85L15 16v1.5C14.999 21 11.284 22 8.5 22c-2.722 0-6.335-.956-6.495-4.27L2 17.5v-1.501c0-1.054.816-1.918 1.85-1.995L4 14zM15.22 14H20c1.054 0 1.918.816 1.994 1.85L22 16v1c-.001 3.062-2.858 4-5 4a7.16 7.16 0 0 1-2.14-.322c.336-.386.607-.827.802-1.327A6.19 6.19 0 0 0 17 19.5l.267-.006c.985-.043 3.086-.363 3.226-2.289L20.5 17v-1a.501.501 0 0 0-.41-.492L20 15.5h-4.051a2.957 2.957 0 0 0-.595-1.34L15.22 14H20h-4.78zM4 15.499l-.1.01a.51.51 0 0 0-.254.136a.506.506 0 0 0-.136.253l-.01.101V17.5c0 1.009.45 1.722 1.417 2.242c.826.445 2.003.714 3.266.753l.317.005l.317-.005c1.263-.039 2.439-.308 3.266-.753c.906-.488 1.359-1.145 1.412-2.057l.005-.186V16a.501.501 0 0 0-.41-.492L13 15.5l-9-.001zM8.5 3a4.5 4.5 0 1 1 0 9a4.5 4.5 0 0 1 0-9zm9 2a3.5 3.5 0 1 1 0 7a3.5 3.5 0 0 1 0-7zm-9-.5c-1.654 0-3 1.346-3 3s1.346 3 3 3s3-1.346 3-3s-1.346-3-3-3zm9 2c-1.103 0-2 .897-2 2s.897 2 2 2s2-.897 2-2s-.897-2-2-2z" fill="currentColor"></path></g></svg>`,
              handler: () => {
                this.$router.push(
                  frontendURL(`accounts/${this.accountId}/reports/agent`)
                );
              },
            },
            {
              id: 'Label',
              title: 'Label Reports',
              icon: `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" role="img" class="ninja-icon ninja-icon--fluent" width="18" height="18" preserveAspectRatio="xMidYMid meet" viewBox="0 0 24 24"><g fill="none"><path d="M19.75 2A2.25 2.25 0 0 1 22 4.25v5.462a3.25 3.25 0 0 1-.952 2.298l-8.5 8.503a3.255 3.255 0 0 1-4.597.001L3.489 16.06a3.25 3.25 0 0 1-.003-4.596l8.5-8.51A3.25 3.25 0 0 1 14.284 2h5.465zm0 1.5h-5.465c-.465 0-.91.185-1.239.513l-8.512 8.523a1.75 1.75 0 0 0 .015 2.462l4.461 4.454a1.755 1.755 0 0 0 2.477 0l8.5-8.503a1.75 1.75 0 0 0 .513-1.237V4.25a.75.75 0 0 0-.75-.75zM17 5.502a1.5 1.5 0 1 1 0 3a1.5 1.5 0 0 1 0-3z" fill="currentColor"></path></g></svg>`,
              keywords: 'lol',
              handler: () => {
                this.$router.push(
                  frontendURL(`accounts/${this.accountId}/reports/label`)
                );
              },
            },
            {
              id: 'Inbox',
              title: 'Inbox Reports',
              icon: `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" role="img" class="ninja-icon ninja-icon--fluent" width="18" height="18" preserveAspectRatio="xMidYMid meet" viewBox="0 0 24 24"><g fill="none"><path d="M6.25 3h11.5a3.25 3.25 0 0 1 3.245 3.066L21 6.25v11.5a3.25 3.25 0 0 1-3.066 3.245L17.75 21H6.25a3.25 3.25 0 0 1-3.245-3.066L3 17.75V6.25a3.25 3.25 0 0 1 3.066-3.245L6.25 3h11.5h-11.5zM4.5 14.5v3.25a1.75 1.75 0 0 0 1.606 1.744l.144.006h11.5a1.75 1.75 0 0 0 1.744-1.607l.006-.143V14.5h-3.825a3.752 3.752 0 0 1-3.475 2.995l-.2.005a3.752 3.752 0 0 1-3.632-2.812l-.043-.188H4.5v3.25v-3.25zm13.25-10H6.25a1.75 1.75 0 0 0-1.744 1.606L4.5 6.25V13H9a.75.75 0 0 1 .743.648l.007.102a2.25 2.25 0 0 0 4.495.154l.005-.154a.75.75 0 0 1 .648-.743L15 13h4.5V6.25a1.75 1.75 0 0 0-1.607-1.744L17.75 4.5z" fill="currentColor"></path></g></svg>`,
              keywords: 'lol',
              handler: () => {
                this.$router.push(
                  frontendURL(`accounts/${this.accountId}/reports/inboxes`)
                );
              },
            },
            {
              id: 'Team',
              title: 'Team Reports',
              icon: `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" role="img" class="ninja-icon ninja-icon--fluent" width="18" height="18" preserveAspectRatio="xMidYMid meet" viewBox="0 0 24 24"><g fill="none"><path d="M14.75 15c.966 0 1.75.784 1.75 1.75l-.001.962c.117 2.19-1.511 3.297-4.432 3.297c-2.91 0-4.567-1.09-4.567-3.259v-1c0-.966.784-1.75 1.75-1.75h5.5zm0 1.5h-5.5a.25.25 0 0 0-.25.25v1c0 1.176.887 1.759 3.067 1.759c2.168 0 2.995-.564 2.933-1.757V16.75a.25.25 0 0 0-.25-.25zm-11-6.5h4.376a4.007 4.007 0 0 0-.095 1.5H3.75a.25.25 0 0 0-.25.25v1c0 1.176.887 1.759 3.067 1.759c.462 0 .863-.026 1.207-.077a2.743 2.743 0 0 0-1.173 1.576l-.034.001C3.657 16.009 2 14.919 2 12.75v-1c0-.966.784-1.75 1.75-1.75zm16.5 0c.966 0 1.75.784 1.75 1.75l-.001.962c.117 2.19-1.511 3.297-4.432 3.297l-.169-.002a2.755 2.755 0 0 0-1.218-1.606c.387.072.847.108 1.387.108c2.168 0 2.995-.564 2.933-1.757V11.75a.25.25 0 0 0-.25-.25h-4.28a4.05 4.05 0 0 0-.096-1.5h4.376zM12 8a3 3 0 1 1 0 6a3 3 0 0 1 0-6zm0 1.5a1.5 1.5 0 1 0 0 3a1.5 1.5 0 0 0 0-3zM6.5 3a3 3 0 1 1 0 6a3 3 0 0 1 0-6zm11 0a3 3 0 1 1 0 6a3 3 0 0 1 0-6zm-11 1.5a1.5 1.5 0 1 0 0 3a1.5 1.5 0 0 0 0-3zm11 0a1.5 1.5 0 1 0 0 3a1.5 1.5 0 0 0 0-3z" fill="currentColor"></path></g></svg>`,
              handler: () => {
                frontendURL(`accounts/${this.accountId}/reports/teams`);
              },
            },
          ],
        },
      ],
    };
  },
  computed: {
    accountId() {
      return this.$store.getters.getCurrentAccountId;
    },
  },
  mounted() {
    this.$refs.ninjakeys.data = this.hotkeys;
  },
  methods: {
    selected(event) {
      console.log('selected', event.detail);
    },
    change(event) {
      console.log('change', event.detail);
    },
  },
};
</script>

<style>
ninja-keys {
  --ninja-accent-color: var(--w-500);
}
</style>
