$(function() {
  $('.scatter-plot-graph .graph-points').each(function(i, n) {
    var el = $(n);

    var school = el.find('.school');
    var detroit = el.find('.detroit');

    var schoolProficiency = parseFloat(school.data('proficiency'));
    var schoolGrowth = parseFloat(school.data('growth'));

    var detroitProficiency =  -4 || parseFloat(detroit.data('proficiency'));
    var detroitGrowth = -4 || parseFloat(detroit.data('growth'));

    var setPointPosition = function(el, axis, data) {
      if (data < 0) {
        el.css(axis, 50 + ((data * -1) / 5.0) + '%');
      } else {
        el.css(axis, 50 - (data / 5.0) + '%');
      }
    };

    setPointPosition(school, 'top', schoolProficiency);
    setPointPosition(school, 'right', schoolGrowth);

    setPointPosition(detroit, 'top', detroitProficiency);
    setPointPosition(detroit, 'right', detroitGrowth);
  });

  $('.scatter-plot-nav .subject').click(function() {
    var el = $(this);
    $('.scatter-plot-nav .subject').removeClass('active');
    el.addClass('active');
    $('.graph-points').addClass('hide');
    $('.graph-points.' + el.data('target')).removeClass('hide');
  });

  $('.graph-point').hover(function() {
    var el = $(this);
    var popup = el.find('.point-popup');
    popup.css('margin-left', el.width() + 'px');
    popup.css('margin-top', '-' + el.height() + 'px');
    popup.removeClass('hide');
    popup.css('display', 'inline-block');
  }, function() {
    var popup = $(this).find('.point-popup')
    popup.addClass('hide');
    popup.css('display', 'none');
  });
});
