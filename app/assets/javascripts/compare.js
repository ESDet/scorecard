var Compare = function(w) {
  var _w = w;
  var _nav = $(".top").first();
  var _navPos = _nav.position();

  var _updateNavName = function(windowpos, navPos) {
    if (_w.width() < 701) {
      var currentSchool = $('.compare > .school').not('.hide').first();
      var schoolNameLine = currentSchool.find('.group:nth-of-type(1) .line:nth-of-type(1)');
      if (windowpos >= navPos.top) {
        var newName = schoolNameLine.find('.name');
        var oldName = $('.nav .name');
        if (oldName.length == 0) {
          newName.clone().appendTo('.nav');
        } else if (newName != oldName) {
          oldName.remove();
          newName.clone().appendTo('.nav');
        }
      } else {
        $('.nav .name').remove();
      }
    }
  };

  var _hideSchools = function(index) {
    $('.compare > .school:not(:nth-of-type(' + index + '))').
      addClass('hide');
    $('.scroll > div').removeClass('hide');
  };

  var _hideScroll = function(nextSchool, scrollEl) {
    if (!nextSchool.hasClass('school')) {
      scrollEl.addClass('hide');
    } else {
      $('.scroll > div').removeClass('hide');
    }
  };

  var _showSchool = function(arg) {
    var currentSchool = $('.compare > .school').
      not('.hide').first();

    var showSchool, arrowEl;
    if (arg == 'next') {
      showSchool = currentSchool.next();
      _hideScroll(showSchool.next(), $('.scroll > .right'));
    } else if (arg == 'prev') {
      showSchool = currentSchool.prev();
      _hideScroll(showSchool.prev(), $('.scroll > .left'));
    }

    if (showSchool.hasClass('school')) {
      currentSchool.addClass('hide');
      showSchool.removeClass('hide');
      _updateNavName(_w.scrollTop(), _navPos);
    }
    return false;
  };

  var _setStickyNav = function() {
    var windowpos = _w.scrollTop();
    if (windowpos >= _navPos.top) {
      _nav.addClass("stick");
    } else {
      _nav.removeClass("stick");
    }
    _updateNavName(windowpos, _navPos);
  }

  return {
    updateNavName: _updateNavName,
    hideScroll: _hideScroll,
    hideSchools: _hideSchools,
    showSchool: _showSchool,
    setStickyNav: _setStickyNav
  }
};
