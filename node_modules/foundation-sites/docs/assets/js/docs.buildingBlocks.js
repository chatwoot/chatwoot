// Adds links to Building Blocks from the ZURB library to each component page

!function() {

$.ajax({
  url: 'https://zurb.com/library/api/building_blocks/type/buttons',
  dataType: 'jsonp',
  success: addBuildingBlocks
});

function addBuildingBlocks(data) {
  var html = '';

  $.each(data, function() {
    html += '<div class="docs-bb"><div class="docs-bb-thumb"><a href="https://zurb.com/building-blocks/'+this.slug+'"><img src="'+this.image_url+'"/></a></div><div class="docs-bb-main"><h3><a href="https://zurb.com/building-blocks/'+this.slug+'">'+this.name+'</a></h3><p>Lorem ipsum dolor sit amet, consectetur adipisicing elit. Dolor, amet incidunt sint esse nihil eum repellendus necessitatibus officiis iusto reprehenderit, alias laudantium veniam ad. Soluta repellat nemo quaerat quis laboriosam.</p></div></div>';
  });

  $('[data-building-blocks]').each(function() {
    $(this).html(html);
  });

  if ($('[data-building-blocks] .docs-bb').length === 0) {
    $('.docs-building-blocks').hide(0);
  }
}

}()
