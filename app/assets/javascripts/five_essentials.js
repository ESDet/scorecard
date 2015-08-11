$(function() {
  $('.graph[data-rating]').each(function(i, el) {
    var ratingEl = $(el);
    var rating = parseInt(ratingEl.data('rating'));
    var text = ratingEl.find('> .text');
    if (rating == 0) {
      text.html("<br/>");
      text.css('background-color', 'grey');
    } else if (rating == 1) {
      ratingEl.css('background-color', '#c32947');
      text.text('NOT YET ORGANIZED');
    } else if (rating == 2) {
      ratingEl.css('background-color', '#ff690f');
      text.text('PARTIALLY ORGANIZED');
    } else if (rating == 3) {
      ratingEl.css('background-color', '#ffc700');
      text.text('MODERATELY ORGANIZED');
    } else if (rating == 4) {
      ratingEl.css('background-color', '#a2c100');
      text.text('ORGANIZED');
    } else if (rating == 5) {
      ratingEl.css('background-color', '#319400');
      text.text('WELL ORGANIZED');
    }
  });

  $('.fivee-category').each(function(i, el) {
    var n = $(el);
    var num = n.data('num');
    if (num > 0 && num < 20) {
      n.css('background-color', '#c32947');
    } else if (num > 19 && num < 40) {
      n.css('background-color', '#ff690f');
    } else if (num > 39 && num < 60) {
      n.css('background-color', '#ffc700');
    } else if (num > 59 && num < 80) {
      n.css('background-color', '#a2c100');
    } else if (num > 79 && num < 101) {
      n.css('background-color', '#319400');
    }
  });
});
