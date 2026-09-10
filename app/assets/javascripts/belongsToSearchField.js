const initializeBelongsToSearchFields = () => {
  document
    .querySelectorAll('select.js-belongs-to-search-field')
    .forEach(element => {
      if (element.selectize) return;

      const $element = window.jQuery(element);
      $element.selectize({
        valueField: 'id',
        labelField: 'dashboard_display_name',
        searchField: 'dashboard_display_name',
        create: false,
        load(query, callback) {
          if (!query.length) {
            callback();
            return;
          }

          window.jQuery.ajax({
            url: `${element.dataset.url}?search=${encodeURIComponent(query)}`,
            type: 'GET',
            error: () => callback(),
            success: response => callback(response.resources),
          });
        },
      });
    });
};

document.addEventListener('DOMContentLoaded', initializeBelongsToSearchFields);
document.addEventListener('turbo:load', initializeBelongsToSearchFields);
document.addEventListener('turbo:before-cache', () => {
  document
    .querySelectorAll('select.js-belongs-to-search-field')
    .forEach(element => {
      element.selectize?.destroy();
    });
});
