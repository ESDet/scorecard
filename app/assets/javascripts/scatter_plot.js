$(function() {
  $('.scatter-plot-graph .graph-points').each(function(i, n) {
    var el = $(n);

    var school = el.find('.school');
    var detroit = el.find('.detroit');

    var schoolProficiency = parseFloat(school.data('proficiency'));
    var schoolGrowth = parseFloat(school.data('growth'));

    var detroitProficiency = parseFloat(detroit.data('proficiency'));
    var detroitGrowth = parseFloat(detroit.data('growth'));

    var setPointPosition = function(el, directions, data) {
      if (data < 0) {
        el.css(directions[0], 50 - ((data * -1) / 5.0) + '%');
      } else {
        el.css(directions[1], 50 - (data / 5.0) + '%');
      }
    };

    setPointPosition(school, ['bottom', 'top'], schoolProficiency);
    setPointPosition(school, ['left', 'right'], schoolGrowth);

    setPointPosition(detroit, ['bottom', 'top'], detroitProficiency);
    setPointPosition(detroit, ['left', 'right'], detroitGrowth);
  });

  $('.scatter-plot-nav .subject').click(function() {
    var el = $(this);
    $('.scatter-plot-nav .subject').removeClass('active');
    el.addClass('active');
    $('.graph-points').addClass('hide');
    $('.graph-points.' + el.data('target')).removeClass('hide');
  });
});
