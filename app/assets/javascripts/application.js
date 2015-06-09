//= require jquery
//= require jquery_ujs
//= require d3
//= require bootstrap
//= require leaflet
//= require map

$(function() {
  $('a#hamburger').click(function(e) {
    $('.menu').toggleClass('active');
    return false;
  });
});
