export const SDK_CSS = `
.woot-widget-holder {
  z-index: 2147483000!important;
  position: fixed!important;
  bottom: 104px;
  right: 20px;
  height: calc(85% - 64px - 20px);
  width: 370px!important;
  min-height: 250px!important;
  max-height: 590px!important;
  -moz-box-shadow: 0 5px 40px rgba(0,0,0,.16)!important;
  -o-box-shadow: 0 5px 40px rgba(0,0,0,.16)!important;
  -webkit-box-shadow: 0 5px 40px rgba(0,0,0,.16)!important;
  box-shadow: 0 5px 40px rgba(0,0,0,.16)!important;
  -o-border-radius: 8px!important;
  -moz-border-radius: 8px!important;
  -webkit-border-radius: 8px!important;
  border-radius: 8px!important;
  overflow: hidden!important;
  opacity: 1!important;
}

.woot-widget-holder iframe { width: 100% !important; height: 100% !important; border: 0; }

.woot-widget-bubble {
  z-index: 2147483000!important;
  -moz-box-shadow: 0 8px 24px rgba(0,0,0,.16)!important;
  -o-box-shadow: 0 8px 24px rgba(0,0,0,.16)!important;
  -webkit-box-shadow: 0 8px 24px rgba(0,0,0,.16)!important;
  box-shadow: 0 8px 24px rgba(0,0,0,.16)!important;
  -o-border-radius: 100px!important;
  -moz-border-radius: 100px!important;
  -webkit-border-radius: 100px!important;
  border-radius: 100px!important;
  background: #1f93ff;
  position: fixed;
  cursor: pointer;
  right: 20px;
  bottom: 20px;
  width: 64px!important;
  height: 64px!important;
}

  .woot-widget-bubble:hover {
  background: #1f93ff;
  -moz-box-shadow: 0 8px 32px rgba(0,0,0,.4)!important;
  -o-box-shadow: 0 8px 32px rgba(0,0,0,.4)!important;
  -webkit-box-shadow: 0 8px 32px rgba(0,0,0,.4)!important;
  box-shadow: 0 8px 32px rgba(0,0,0,.4)!important;
}

.woot-widget-bubble img {
  width: 24px;
  height: 24px;
  margin: 20px;
}

.woot-widget-bubble.woot--close img {
  width: 16px;
  height: 16px;
  margin: 24px;
}

.woot--hide {
  display: none !important;
}
`;
