//= require jquery
//= require jquery_ujs
//= require d3
//= require bootstrap
//= require leaflet
//= require map
//= require bar_graph
//= require two_bar_graph
//= require three_bar_graph
//= require pie

$(function() {
  var menu = $('.menu').first();
  $('a#hamburger').click(function(e) {
    menu.toggleClass('active');
    return false;
  });

  $('.what-this-means').click(function() {
    var text = $(this).find('> .text');
    if (text.hasClass('hide')) {
      text.removeClass('hide');
    } else {
      text.addClass('hide');
    }
  });

  $('.compare').mouseover(function() {
    $(this).text('COMING SOON');
  }).mouseout(function() {
    $(this).text('COMPARE TO OTHER SCHOOLS');
  });

  var grade = $('.rounded-square .grade');
  if (grade.text().trim() == 'NEW') {
    grade.css('font-size', '31px').
      css('padding-top', '11px');
  }
});
