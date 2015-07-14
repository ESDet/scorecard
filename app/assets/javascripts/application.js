//= require jquery
//= require jquery_ujs
//= require d3
//= require bootstrap
//= require leaflet
//= require map
//= require bar_graph
//= require two_bar_graph
//= require three_bar_graph

$(function() {
  var menu = $('.menu').first();
  $('a#hamburger').click(function(e) {
    menu.toggleClass('active');
    return false;
  });
});
