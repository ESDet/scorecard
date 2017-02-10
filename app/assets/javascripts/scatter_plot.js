$(function() {
  $('.scatter-plot-graph .graph-point').each(function(i, n) {
    var el = $(n);

    var scatterWidth = $(document).width() * $('.middle').width() / 100;
    var scatterHeight = $('.scatter-plot-graph').height();

    var proficiency = parseFloat(el.data('proficiency-location'));
    var growth = parseFloat(el.data('growth-location'));

    if (proficiency != 0) {
      proficiency = proficiency - (el.width() / scatterWidth * 50) + 0.1;
      if (proficiency < 0) {
        proficiency = 0;
      }
    }

    if (growth != 100) {
      growth = growth - (el.height() / scatterHeight * 50);
    } else {
      growth = 100 - (el.height() / scatterHeight * 50);
    }

    growth = growth + 0.1;

    if (growth > 95) {
      growth = 95;
    }

    el.css('left', proficiency + '%');
    el.css('top', growth + '%');
  });

  $('.scatter-plot-nav .subject').click(function() {
    var el = $(this);
    var year = $(".scatter-plot-graph .years .year.active").data("target");

    $('.scatter-plot-nav .subject').removeClass('active');
    el.addClass('active');
    $('.graph-points').addClass('hide');
    if (year != undefined) {
      $('.graph-points.' + el.data('target') + '.' + year).removeClass('hide');
    } else {
      $('.graph-points.' + el.data('target')).removeClass('hide');
    }
  });

  $('.scatter-plot-graph .years .year').click(function() {
    var el = $(this);
    var subject = $('.scatter-plot-nav .subject.active').data("target");

    $('.scatter-plot-graph .years .year').removeClass('active');
    el.addClass('active');
    $('.graph-points').addClass('hide');
    $('.graph-points.' + el.data('target') + '.' + subject).removeClass('hide');
  });

  $('.graph-point').hover(function() {
    var el = $(this);
    var popup = el.find('.point-popup');
    popup.css('margin-left', '-' + ((popup.width() / 2) - 11) + 'px');
    popup.css('margin-top', el.height() + 'px');
    popup.removeClass('hide');
    popup.css('display', 'inline-block');
  }, function() {
    var popup = $(this).find('.point-popup')
    popup.addClass('hide');
    popup.css('display', 'none');
  });
});
