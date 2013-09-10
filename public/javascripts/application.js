$(document).ready(function(e) {
  
  // Skip to the tab if you have a fragment
  if(window.location.hash) {
    var id = window.location.hash.substring(0).replace('-tab', '');
    var $tab = $('ul.nav a[href="' + id + '"]');
    $tab.tab('show');
    $('html, body').animate({scrollTop: $tab.offset().top}, 900)
  }

  $('ul.nav a[data-toggle="tab"]').on('shown', function (e) {
    var tgt = $(this).attr('href');
    window.location.hash = tgt + '-tab';
    return true;
  });

  
});