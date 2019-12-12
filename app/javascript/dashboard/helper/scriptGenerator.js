export const createWebsiteWidgetScript = websiteToken => `
<script>
(function(d,t) {
  var BASE_URL = '${window.location.origin}';
  var g=d.createElement(t),s=d.getElementsByTagName(t)[0];
  g.src= BASE_URL + "/packs/js/sdk.js";
  s.parentNode.insertBefore(g,s);
  g.onload=function(){
    window.chatwootSDK.run({
      websiteToken: '${websiteToken}',
      baseUrl: BASE_URL
    })
  }
})(document,"script");
</script>
`;

export const createMessengerScript = pageId => `
<script>
  window.fbAsyncInit = function() {
    FB.init({
      appId: "${window.chatwootConfig.fbAppId}",
      xfbml: true,
      version: "v4.0"
    });
  };
  (function(d, s, id){
      var js, fjs = d.getElementsByTagName(s)[0];
      if (d.getElementById(id)) { return; }
      js = d.createElement(s); js.id = id;
      js.src = "//connect.facebook.net/en_US/sdk.js";
      fjs.parentNode.insertBefore(js, fjs);
  }(document, 'script', 'facebook-jssdk'));

</script>
<div class="fb-messengermessageus"
  messenger_app_id="${window.chatwootConfig.fbAppId}"
  page_id="${pageId}"
  color="blue"
  size="standard" >
</div>
`;
