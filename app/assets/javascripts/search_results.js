$(function() {
  var spinner = new Spinner();
  $('#load-more-results').
    bind('ajax:beforeSend', function() {
      spinner.spin();
      $('.more-results').append(spinner.el)
      $('#load-more-results').addClass('hide');
    });
  $(document).ajaxSuccess(function(e, xhr, settings) {
    if (settings.url.indexOf('offset') != -1) {
      $('#load-more-results').removeClass('hide');
      spinner.stop();
    }
  });
});
