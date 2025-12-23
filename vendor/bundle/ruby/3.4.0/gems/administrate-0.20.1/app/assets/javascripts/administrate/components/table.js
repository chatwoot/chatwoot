$(function() {
  var keycodes = { space: 32, enter: 13 };

  var visitDataUrl = function(event) {
    if (event.type == "click" ||
        event.keyCode == keycodes.space ||
        event.keyCode == keycodes.enter) {

      if (event.target.href) {
        return;
      }

      var dataUrl = $(event.target).closest("tr").data("url");
      var selection = window.getSelection().toString();
      if (selection.length === 0 && dataUrl) {
        window.location = window.location.protocol + '//' + window.location.host + dataUrl;
      }
    }
  };

  $("table").on("click", ".js-table-row", visitDataUrl);
  $("table").on("keydown", ".js-table-row", visitDataUrl);
});
