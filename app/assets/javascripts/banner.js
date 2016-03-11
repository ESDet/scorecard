$(function() {
  var toggleHoverState = function() {
    $(this).find('.hover-state').toggleClass('hide');
  };

  $('.banner-icon').click(toggleHoverState);
  $('.banner-icon').mouseover(toggleHoverState);
  $('.banner-icon').mouseout(toggleHoverState);
});
