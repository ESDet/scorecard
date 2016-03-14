$(function() {
  $('.scatter-plot-graph .graph-points').each(function(i, n) {
    var el = $(n);

    var school = el.find('.graph-point.school');
    var detroit = el.find('.graph-point.detroit');

    var schoolProficiency = parseFloat(school.data('proficiency-location'));
    var schoolGrowth = parseFloat(school.data('growth-location'));

    var detroitProficiency =  parseFloat(detroit.data('proficiency-location'));
    var detroitGrowth = parseFloat(detroit.data('growth-location'));

    var scatterPlotGraph = $('.scatter-plot-graph');
    school.css('left', schoolProficiency - (scatterPlotGraph.width() / school.width() / 1.3) + '%');
    school.css('top', schoolGrowth - (scatterPlotGraph.height() / school.height() / 1.9) + '%');

    detroit.css('left', detroitProficiency - (scatterPlotGraph.width() / detroit.width() / 5) + '%');
    detroit.css('top', detroitGrowth - (scatterPlotGraph.height() / school.height() / 3) + '%');
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
