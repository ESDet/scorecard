var Compare = function(w) {
  var _w = w;
  var _nav = $(".top").first();
  var _navPos = _nav.position();

  var _updateNavName = function(windowpos, navPos) {
    if (w.width() < 541) {
      if (windowpos >= navPos.top) {
        var currentSchool = $('.compare > .school').
          not('.hide').first();
        var schoolNameLine = currentSchool.
          find('.group:nth-of-type(1) .line:nth-of-type(1)');
        var newName = schoolNameLine.find('.name');
        var oldName = $('.nav .middle .name');
        if (oldName.length == 0) {
          newName.clone().appendTo('.nav .middle');
        } else if (newName != oldName) {
          oldName.remove();
          newName.clone().appendTo('.nav .middle');
        }
      } else {
        $('.nav .middle .name').remove();
      }
    } else {
      $('.nav .middle .name').remove();
    }
  };

  var _hideSchools = function(index) {
    $('.compare > .school:not(:nth-of-type(' + index + '))').
      addClass('hide');
    $('.scroll > div').removeClass('hide');
  };

  var _hideScroll = function(nextSchool, scrollEl) {
    if (nextSchool.hasClass('school')) {
      scrollEl.removeClass('hide');
      scrollEl.css('display', 'inline-block');
    } else {
      scrollEl.addClass('hide');
      scrollEl.css('display', 'none');
    }
  };

  var _setHidden = function() {
    var schools = $('.compare > .school');
    var width = _w.width();
    if (width > 1271) {
      schools.removeClass('hide').
        css('display', 'inline-block');
    } else if (width < 1272 && width > 801) {
      $(schools[0]).
        removeClass('hide').
        css('display', 'inline-block');
      $(schools[1]).
        removeClass('hide').
        css('display', 'inline-block');
      $(schools[2]).
        removeClass('hide').
        css('display', 'inline-block');
      $(schools[3]).
        addClass('hide').
        css('display', 'none');
    } else if (width < 802 && width > 540) {
      $(schools[0]).
        removeClass('hide').
        css('display', 'inline-block');
      $(schools[1]).
        removeClass('hide').
        css('display', 'inline-block');
      $(schools[2]).
        addClass('hide').
        css('display', 'none');
      $(schools[3]).
        addClass('hide').
        css('display', 'none');
    } else if (width < 541) {
      $(schools[0]).
        removeClass('hide').
        css('display', 'inline-block');
      $(schools[1]).
        addClass('hide').
        css('display', 'none');
      $(schools[2]).
        addClass('hide').
        css('display', 'none');
      $(schools[3]).
        addClass('hide').
        css('display', 'none');
    }
  };

  var _showSchool = function(arg) {
    var swapSchools = function(currentSchool, showSchool) {
      if (showSchool.hasClass('school')) {
        currentSchool.addClass('hide');
        currentSchool.css('display', 'none');
        showSchool.removeClass('hide');
        showSchool.css('display', 'inline-block');
        _updateNavName(_w.scrollTop(), _navPos);
      }
    };

    var visibleSchools = function() {
      return $('.compare > .school').not('.hide');
    };

    var currentSchools = visibleSchools();
    var showSchool, arrowEl;
    var margin = currentSchools.first().css('margin-left');
    if (currentSchools.length > 1) {
      if (arg == 'next') {
        showSchool = currentSchools.last().next();
        if (showSchool.hasClass('school')) {
          swapSchools(currentSchools.first(), showSchool);
        }
      } else if (arg == 'prev') {
        showSchool = currentSchools.first().prev();
        if (showSchool.hasClass('school')) {
          swapSchools(currentSchools.last(), showSchool);
        }
      }
      currentSchools = visibleSchools();
      currentSchools.css('margin-left', '0');
      currentSchools.first().css('margin-left', margin);
      _hideScroll(currentSchools.first().prev(), $('.scroll > .left'));
      _hideScroll(currentSchools.last().next(), $('.scroll > .right'));
    } else {
      var currentSchool = currentSchools.first();
      if (arg == 'next') {
        showSchool = currentSchool.next();
      } else if (arg == 'prev') {
        showSchool = currentSchool.prev();
      }
      swapSchools(currentSchool, showSchool);
      currentSchools = visibleSchools();
      currentSchools.css('margin-left', '0');
      currentSchool = currentSchools.first();
      currentSchool.css('margin-left', margin);
      _hideScroll(currentSchool.prev(), $('.scroll > .left'));
      _hideScroll(currentSchool.next(), $('.scroll > .right'));
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
    setStickyNav: _setStickyNav,
    setHidden: _setHidden
  }
};
