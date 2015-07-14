$(function() {
  $('.graph.growth[data-subject]').each(function(i, n) {
    var graph = $(n);
    var schoolGrowth = graph.data('school-growth');
    var detroitGrowth = graph.data('detroit-growth');
    var scale = graph.data('scale');
    var halfScale = scale / 2.0;

    if (schoolGrowth != "" && schoolGrowth <= halfScale) {
      schoolGrowth = parseFloat(schoolGrowth);
      var schoolNum, schoolDiff, schoolColor;
      if (schoolGrowth < 0) {
        schoolNum = (halfScale + schoolGrowth) / halfScale * 100 / 2.0;
        schoolDiff = 50 - schoolNum;
        schoolColor = '#c73458';
      } else {
        schoolNum = 50;
        schoolDiff = schoolGrowth / halfScale * 100 / 2.0;
        schoolColor = '#7cc45c';
      }

      if (schoolDiff > 50) { schoolDiff = 49; }
      if (schoolNum < 10) {
        schoolNum = 0.5;
        schoolDiff = 49.5;
      }
      var schoolEl = graph.find('> .bar.school');
      schoolEl.find('> .number').
        css('width', schoolNum + '%').
        css('background-color', schoolColor);
      schoolEl.find('> .difference').
        css('width', schoolDiff + '%').
        removeClass('hide');
      schoolEl.find('> .text').
        text(schoolGrowth).
        css('color', schoolColor);
    }

    if (detroitGrowth != "" && detroitGrowth < halfScale) {
      detroitGrowth = parseFloat(detroitGrowth);
      var detroitNum, detroitDiff, detroitColor;
      if (detroitGrowth < 0) {
        detroitNum = (halfScale + detroitGrowth) / halfScale * 100 / 2.0;
        detroitDiff = 50 - detroitNum;
        detroitColor = '#c73458';
      } else {
        detroitNum = 50;
        detroitDiff = detroitGrowth / halfScale * 100 / 2.0;
        detroitColor = '#7cc45c';
      }

      if (detroitDiff > 50) { detroitDiff = 49; }
      if (detroitNum < 10) {
        detroitNum = 0.5;
        detroitDiff = 49.5;
      }
      var detroitEl = graph.find('> .bar.detroit');
      detroitEl.find('> .number').
        css('width', detroitNum + '%').
        css('background-color', detroitColor);
      detroitEl.find('> .difference').
        css('width', detroitDiff + '%').
        removeClass('hide');
      detroitEl.find('> .text').
        text(detroitGrowth).
        css('color', detroitColor);
    }
  });
});
