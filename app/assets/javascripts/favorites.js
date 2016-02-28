$(function() {
  var favorites = Cookies.get('favorites');
  if (favorites != undefined) {
    favorites = favorites.split(",");
    $(favorites).each(function(i, n) {
      var link = $('a[data-id="' + n + '"]');
        link.html('&#9733;').css('color', '#efc928');
        link.parent().parent().attr('data-favorited', '');
    });
  }

  $('.search-results .school .rating .favorite').click(function() {
    var favorites;
    if ((favorites = Cookies.get('favorites')) != undefined) {
      favorites = favorites.split(",");
      var id = $(this).data('id').toString();
      var idIndex = favorites.indexOf(id);
      if (idIndex == -1) {
        favorites.push(id);
        $(this).html('&#9733;').css('color', '#efc928');
        $(this).parent().parent().
          attr('data-favorited', true);
      } else {
        favorites.splice(idIndex, 1);
        $(this).html('&#9734;').css('color', '#bcbcbc');
        $(this).parent().parent().
          removeAttr('data-favorited');
      }
      if (favorites.length == 1) {
        Cookies.set('favorites', favorites[0]);
      } else if (favorites.length > 1) {
        Cookies.set('favorites', favorites.join(","));
      } else {
        Cookies.remove('favorites');
      }
    } else {
      Cookies.set('favorites', $(this).data('id').toString());
      $(this).html('&#9733;').
        css('color', '#efc928');
      $(this).parent().parent().
        attr('data-favorited', true)
    }
    return false;
  });

  $('#favorites-link').click(function() {
    var el = $(this);
    if (el.attr('on') != undefined) {
      $('.search-results .school-list .school').removeClass('hide');
      el.find('.star').html('&#9734;');
      el.removeAttr('on')
    } else {
      var favorites = $('.search-results .school-list .school').
        not('[data-favorited]').addClass('hide');
      el.find('.star').html('&#9733;');
      el.attr('on', true);
    }
    return false;
  });
});
