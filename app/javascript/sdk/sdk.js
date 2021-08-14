export const SDK_CSS = `.woot-widget-holder {
  box-shadow: 0 5px 40px rgba(0, 0, 0, .16) !important;
  opacity: 1;
  will-change: transform, opacity;
  transform: translateY(0);
  overflow: hidden !important;
  position: fixed !important;
  transition: opacity 0.2s linear, transform 0.25s linear;
  z-index: 2147483000 !important;
}

.woot-widget-holder iframe {
  border: 0;
  height: 100% !important;
  width: 100% !important;
  max-height: 100vh !important;
}

.woot-widget-holder.has-unread-view {
  border-radius: 0 !important;
  bottom: 94px;
  box-shadow: none !important;
}

.woot-widget-bubble {
  background: #1f93ff;
  border-radius: 100px !important;
  bottom: 20px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, .16) !important;
  cursor: pointer;
  height: 64px !important;
  position: fixed;
  width: 64px !important;
  z-index: 2147483000 !important;
  user-select: none;
}

.woot-widget-bubble.woot-widget--expanded {
  bottom: 24px;
  display: flex;
  height: 48px !important;
  width: auto !important;
}

.woot-widget-bubble.woot-widget--expanded div {
  align-items: center;
  color: #fff;
  display: flex;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Oxygen-Sans, Ubuntu, Cantarell, Helvetica Neue, Arial, sans-serif;
  font-size: 16px;
  font-weight: 500;
  justify-content: center;
  padding-right: 20px;
  width: auto !important;
}

.woot-widget-bubble.woot-widget--expanded img {
  height: 20px;
  margin: 14px 8px 14px 16px;
  width: 20px;
}

.woot-widget-bubble.woot-elements--left {
  left: 20px;
}

.woot-widget-bubble.woot-elements--right {
  right: 20px;
}

.woot-widget-bubble:hover {
  background: #1f93ff;
  box-shadow: 0 8px 32px rgba(0, 0, 0, .4) !important;
}

.woot-widget-bubble img {
  all: revert;
  height: 24px;
  margin: 20px;
  width: 24px;
}

@media only screen and (min-width: 667px) {
  .woot-widget-holder.woot-elements--left {
    left: 20px;
 }
  .woot-widget-holder.woot-elements--right {
    right: 20px;
 }
}

.woot--close:hover {
  opacity: 1;
}

.woot--close::before, .woot--close::after {
  background-color: #fff;
  content: ' ';
  height: 24px;
  left: 32px;
  position: absolute;
  top: 20px;
  width: 2px;
}

.woot--close::before {
  transform: rotate(45deg);
}

.woot--close::after {
  transform: rotate(-45deg);
}

.woot--hide {
  bottom: -100vh;
  transform: translateY(40px);
  top: unset !important;
  opacity: 0;
  visibility: hidden !important;
  z-index: -1 !important;
}

.woot-widget--without-bubble {
  bottom: 20px !important;
}

@media only screen and (max-width: 667px) {
  .woot-widget-holder {
    height: 100%;
    right: 0;
    top: 0;
    width: 100%;
 }

 .woot-widget-holder iframe {
    min-height: 100% !important;
  }


 .woot-widget-holder.has-unread-view {
    height: auto;
    right: 0;
    width: auto;
    bottom: 0;
    top: auto;
    max-height: 100vh;
    padding: 0 8px;
  }
 
  .woot-widget-holder.has-unread-view iframe {
    min-height: unset !important;
  }

 .woot-widget-holder.has-unread-view.woot-elements--left {
    left: 0;
  }
  
  .woot-widget-bubble.woot--close {
    bottom: 60px;
    opacity: 0;
    visibility: hidden !important;
    z-index: -1 !important;
  }
}

@media only screen and (min-width: 667px) {
  .woot-widget-holder {
    border-radius: 16px !important;
    bottom: 104px;
    height: calc(85% - 64px - 20px);
    max-height: 590px !important;
    min-height: 250px !important;
    width: 400px !important;
 }
}
`;
