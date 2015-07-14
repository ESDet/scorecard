$(function() {
  $('.bar .graph > .number > .width').each(function(i, n) {
    var el  = $(n),
        num = el.data('num');
    if (num != "") {
      num = parseFloat(num);
      el.css('width', num + '%');
    } else {
      el.css('width', '0px');
    }
  });
});
