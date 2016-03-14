//= require jquery
//= require jquery_ujs
//= require js.cookie
//= require d3
//= require bootstrap/dropdown
//= require bootstrap/collapse
//= require bootstrap/modal
//= require leaflet
//= require map
//= require banner
//= require search_results
//= require favorites
//= require filters
//= require bar_graph
//= require two_bar_graph
//= require three_bar_graph
//= require pie
//= require five_essentials
//= require compare
//= require scatter_plot
//= require spin
//= require froogaloop

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

  var grade = $('.rounded-square .grade');
  if (grade.text().trim() == 'NEW') {
    grade.css('font-size', '31px').
      css('padding-top', '11px');
  }
});
