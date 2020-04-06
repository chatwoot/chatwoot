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
