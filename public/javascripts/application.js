$(document).ready(function(e) {
  
  // Skip to the tab if you have a fragment
  if(window.location.hash) {
    var id = window.location.hash.substring(0).replace('-tab', '');
    var $tab = $('ul.nav a[href="' + id + '"]');
    if($tab.length > 0) {
      $tab.tab('show');
      $('html, body').animate({scrollTop: $tab.offset().top}, 900)
    }
  }

  $('ul.nav a[data-toggle="tab"]').on('shown', function (e) {
    var tgt = $(this).attr('href');
    // We need to slightly modify the anchor so the browser doesn't override and skip to the element
    window.location.hash = tgt + '-tab';
    return true;
  });

  $('.help').popover({
    html: true,
    container: 'body'
  });
  
  $('body').on('click', '.popover .close', function(e) {
    var tgt = $(this).attr('data-target');
    $('i.help[data-id=' + tgt + ']').popover('hide');
    return false;
  });
  
});