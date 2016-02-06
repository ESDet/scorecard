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
  $('.bar-graph').each(function(i, n) {
    var school = $(n).find('.fill');
    school.css('width', parseFloat(school.data('num')) + '%');

    var markers = $(n).find('.line-marker');
    var mar;
    markers.each(function(i, n) {
      var el = $(n);
      var num = el.data('num');
      el.css('margin-left', num + '%');
    });
    var markerText = $(n).find('.line-marker-text');
    markerText.each(function(i, n) {
      var el = $(n);
      var num = el.data('num');
      if (el.hasClass('detroit')) {
        el.css('left', (num - 10)+ '%');
      } else {
        el.css('left', (num - 6)+ '%');
      }
    });
    var markerOne = $(markerText[0]);
    var markerTwo = $(markerText[1]);
    var marginOne = parseInt(markerOne.css('left').replace('%', ''));
    var marginTwo = parseInt(markerTwo.css('left').replace('%', ''));

    var left, right, diff;
    if (marginTwo > marginOne) {
      diff = marginTwo - marginOne;
      if (diff < 10) {
        left = marginOne - 13;
        right = marginTwo + 13;
      } else if (diff > 9 && diff < 20) {
        left = marginOne - 7;
        right = marginTwo + 18;
      }
    } else {
      diff = marginOne - marginTwo;
      if (diff < 10) {
        right = marginTwo - 10;
        left = marginOne + 10;
      } else if (diff > 9 && diff < 20) {
        right = marginTwo - 7;
        left = marginOne + 8;
      }
    }

    markerOne.css('left', left + '%');
    markerTwo.css('left', right + '%');
  });
});
