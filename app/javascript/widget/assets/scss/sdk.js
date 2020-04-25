export const SDK_CSS = ` .woot-widget-holder {
  z-index: 2147483000 !important;
  position: fixed !important;
  -moz-box-shadow: 0 5px 40px rgba(0, 0, 0, .16) !important;
  -o-box-shadow: 0 5px 40px rgba(0, 0, 0, .16) !important;
  -webkit-box-shadow: 0 5px 40px rgba(0, 0, 0, .16) !important;
  box-shadow: 0 5px 40px rgba(0, 0, 0, .16) !important;
  overflow: hidden !important;
  opacity: 1;
  transition-property: opacity, bottom;
  transition-duration: 0.5s, 0.5s;
}

.woot-widget-holder iframe {
  width: 100% !important;
  height: 100% !important;
  border: 0;
}

.woot-widget-bubble {
  z-index: 2147483000 !important;
  -moz-box-shadow: 0 8px 24px rgba(0, 0, 0, .16) !important;
  -o-box-shadow: 0 8px 24px rgba(0, 0, 0, .16) !important;
  -webkit-box-shadow: 0 8px 24px rgba(0, 0, 0, .16) !important;
  box-shadow: 0 8px 24px rgba(0, 0, 0, .16) !important;
  -o-border-radius: 100px !important;
  -moz-border-radius: 100px !important;
  -webkit-border-radius: 100px !important;
  border-radius: 100px !important;
  background: #1f93ff;
  position: fixed;
  cursor: pointer;
  bottom: 20px;
  width: 64px !important;
  height: 64px !important;
}

.woot-widget-bubble.woot-elements--left {
  left: 20px;
}

.woot-widget-bubble.woot-elements--right {
  right: 20px;
}

@media only screen and (min-width: 667px) {
  .woot-widget-holder.woot-elements--left {
    left: 20px;
  }

  .woot-widget-holder.woot-elements--right {
    right: 20px;
  }
}

.woot-widget-bubble:hover {
  background: #1f93ff;
  -moz-box-shadow: 0 8px 32px rgba(0, 0, 0, .4) !important;
  -o-box-shadow: 0 8px 32px rgba(0, 0, 0, .4) !important;
  -webkit-box-shadow: 0 8px 32px rgba(0, 0, 0, .4) !important;
  box-shadow: 0 8px 32px rgba(0, 0, 0, .4) !important;
}

.woot-widget-bubble img {
  width: 24px;
  height: 24px;
  margin: 20px;
}

.woot--close:hover {
  opacity: 1;
}

.woot--close:before, .woot--close:after {
  position: absolute;
  left: 32px;
  top: 20px;
  content: ' ';
  height: 24px;
  width: 2px;
  background-color: white;
}

.woot--close:before {
  transform: rotate(45deg);
}

.woot--close:after {
  transform: rotate(-45deg);
}


.woot--hide {
  visibility: hidden !important;
  z-index: -1 !important;
  opacity: 0;
  bottom: 60px;
}

@media only screen and (max-width: 667px) {
  .woot-widget-holder {
    top: 0;
    right: 0;
    height: 100%;
    width: 100%;
  }

  .woot-widget-bubble.woot--close {
    visibility: hidden !important;
    z-index: -1 !important;
    opacity: 0;
    bottom: 60px;
  }
}

@media only screen and (min-width: 667px) {
  .woot-widget-holder {
    bottom: 104px;
    height: calc(85% - 64px - 20px);
    width: 400px !important;
    min-height: 250px !important;
    max-height: 590px !important;
    -o-border-radius: 16px !important;
    -moz-border-radius: 16px !important;
    -webkit-border-radius: 16px !important;
    border-radius: 16px !important;
  }
}
`;
