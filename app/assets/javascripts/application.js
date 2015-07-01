//= require jquery
//= require jquery_ujs
//= require d3
//= require bootstrap
//= require leaflet
//= require map

$(function() {
  var menu = $('.menu').first();
  $('a#hamburger').click(function(e) {
    menu.toggleClass('active');
    return false;
  });
});
