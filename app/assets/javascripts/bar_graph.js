$(function() {
  $('.graph > .number').each(function(i, n) {
    var el = $(n);
    var num = $(n).data('num');
    if (num > 0 && num < 1) { num = 1; }
    if (num == "") {
      num = 0;
      el.find('.text').
        css('color', 'grey').
        css('text-shadow', 'none');
    }
    el.css('width', num + "%");
  });
  $('.line-graph').each(function(i, n) {
    var markers = $(n).find('.line-marker');
    var mar;
    markers.each(function(i, n) {
      var el = $(n);
      var num = el.data('num');
      if (mar) {
        if (mar > num) {
          el.css('margin-left',
            (mar - num - 1) + '%');
        } else {
          el.css('margin-left',
            (num - mar - 1) + '%');
        }
      } else {
        mar = num;
        el.css('margin-left', (mar - 1) + '%');
      }
    });
    var marginOne = $(markers[0]).position().left,
        marginTwo = $(markers[1]).position().left;
    if (marginOne < 0) { marginOne *= -1; }
    if (marginTwo < 0) { marginTwo *= -1; }
    if (marginTwo - marginOne < 20) {
      $(markers[0]).find('.wrapper').
        css('text-align', 'right').
        css('margin-left', '-35px');
    } else {
      $(markers[0]).find('.wrapper').
        css('margin-left', '-20px');
      $(markers[1]).find('.wrapper').
        css('margin-left', '-10px');
    }
  });
});
