$(function() {
  $('.scatter-plot-graph .graph-point').each(function(i, n) {
    var el = $(n);

    var scatterWidth = $(document).width() * $('.middle').width() / 100;
    var scatterHeight = $('.scatter-plot-graph').height();

    var proficiency = parseFloat(el.data('proficiency-location'));
    var growth = parseFloat(el.data('growth-location'));

    if (proficiency != 0) {
      proficiency = proficiency - (el.width() / scatterWidth * 50);
      if (proficiency < 0) {
        proficiency = 0;
      }
    }

    if (growth != 100) {
      growth = growth - (el.height() / scatterHeight * 50);
    } else {
      growth = 100 - (el.height() / scatterHeight * 50);
    }

    if (growth > 95) {
      growth = 95;
    }

    el.css('left', proficiency + '%');
    el.css('top', growth + '%');
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
