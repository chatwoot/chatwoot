<template>
  <div class="secondary--sidebar">
    <div class="main-nav">
      <transition-group name="menu-list" tag="ul" class="menu vertical">
        <sidebar-item
          v-for="item in accessibleMenuItems"
          :key="item.toState"
          :menu-item="item"
        />
        <sidebar-item
          v-if="shouldShowTeams"
          :key="teamSection.toState"
          :menu-item="teamSection"
        />
        <sidebar-item
          v-if="shouldShowSidebarItem"
          :key="inboxSection.toState"
          :menu-item="inboxSection"
        />
        <sidebar-item
          v-if="shouldShowSidebarItem"
          :key="labelSection.toState"
          :menu-item="labelSection"
        />

        <sidebar-item
          v-if="showShowContactSideMenu"
          :key="contactLabelSection.key"
          :menu-item="contactLabelSection"
          @add-label="showAddLabelPopup"
        />
      </transition-group>
    </div>
  </div>
</template>
