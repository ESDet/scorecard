Filters = function() {
  var _displayFilterPanels = function(radio) {
    if (radio.name == 'school_type' && radio.value == '0') {
      $('#operator-filter').addClass('hide');
      $('#governance-filter').addClass('hide');
      $('#grade-filter').addClass('hide');
      $('#ec-age-group-filter').addClass('hide');
    } else if (radio.value == 'ecs') {
      $('.school-filter').addClass('hide');
      $('.ec-filter').removeClass('hide');
    } else {
      $('.ec-filter').addClass('hide');
      $('.school-filter').removeClass('hide');
    }
  }

  var arraysEqual = function(a, b) {
    if (a === b) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    a.sort();
    b.sort();

    for (var i = 0; i < a.length; ++i) {
      if (a[i] !== b[i]) return false;
    }
    return true;
  }

  var _filterResults = function() {
    if (this.name == 'school_type') {
      _displayFilterPanels(this);
    }

    var schools = $('.school');

    schools.addClass('hide');

    var schoolData = schools.map(function(i, school) {
      var s = $(school);
      var fields = {
        tid: s.data('tid'),
        school_type: s.data('school_type')
      };
      if (fields['school_type'] == 'ecs') {
        fields['age_groups'] = s.data('age_groups').toString().split(",");
        fields['special_needs'] = s.data('special_ed_experience').toString().split(",");
        fields['specialty'] = s.data('specialty').toString().split(",");
      } else {
        fields['grades_served'] = s.data('grades_served');
        fields['governance'] = s.data('governance');
        fields['operator'] = s.data('operator');
        fields['special_ed'] = s.data('special_ed');
      }
      return fields;
    });

    var gradeFilter = $('#school-type-filter .radio input:checked')[0];
    if (gradeFilter) {
      gradeFilter = gradeFilter.value;
    }

    var filterEC = function() {
      var grades = $('#ec-age-group-filter .radio input:checked').
        map(function(i, n) { return n.value; }).toArray();

      var specialNeeds = $('#ec-special-filter .radio input:checked').
        map(function(i, n) { return n.value; }).toArray();

      var specialty = $('#ec-specialty-filter .radio input:checked').
        map(function(i, n) { return n.value; }).toArray();

      schoolData = $(schoolData).map(function(i, n) {
        var isEcs = n.school_type == 'ecs';
        var gradesMatch = false,
          specialMatch = false,
          specialtyMatch = false;
        if (isEcs) {
          if (grades.length > 0) {
            $(grades).each(function(i, g) {
              if (n.age_groups.indexOf(g) != -1) {
                gradesMatch = true;
                return;
              }
            });
          }
          if (specialNeeds.length > 0) {
            specialMatch = specialNeeds.filter(function(g) {
              return n.special_needs.indexOf(g) != -1;
            });
          }
          if (specialty.length > 0) {
            specialtyMatch = specialty.filter(function(g) {
              return n.specialty.indexOf(g) != -1;
            });
          }
          if (grades.length > 0 && gradesMatch &&
              (specialNeeds.length == 0 || arraysEqual(specialMatch, specialNeeds)) &&
              (specialty.length == 0 || arraysEqual(specialtyMatch, specialty))) {
            return n;
          }
        }
        return null;
      });

      mapSchools = [];
      schoolData.each(function(i, n) {
        $('.school[data-tid=' + n.tid + ']').removeClass('hide');
        mapSchools.push(n.tid);
      });
      schoolsMap.showMarkers(mapSchools);
    };

    var filterSchools = function() {
      var grades = [];
      $('#grade-filter .radio input:checked').each(function(i, n) {
        grades = grades.concat(n.value.split(","));
      });

      schoolData = $(schoolData).map(function(i, n) {
        var isK8HS = n.school_type == 'k8' || n.school_type == 'hs';
        if (isK8HS) {
          var hasGrade = false;
          $(grades).each(function(i, g) {
            if (n.grades_served.split(",").indexOf(g) != -1) {
              hasGrade = true;
              return;
            }
          });
          if (hasGrade) return n;
          return null;
        }
        return null;
      });

      var special = []
      $('#special-ed-filter .radio input:checked').each(function(i, n) {
        special = special.concat(n.value.split(","));
      });

      schoolData = $(schoolData).map(function(i, n) {
        if (special.length != 0 && special[0] != "0") {
          var hasSpecialEd = false;
          $(special).each(function(i, s) {
            if (n.special_ed.split(",").indexOf(s) != -1) {
              hasSpecialEd = true;
              return;
            }
          });
          if (hasSpecialEd) return n;
          return null;
        }
        return n;
      });

      var operator = $('#operator-filter .radio input:checked')[0].value;
      var governances = $('#governance-filter .radio input:checked')[0].value.split(",");

      var filterMatch = function(school) {
        var schoolOperator = school.operator.toString();
        var schoolGovernance = school.governance.toString();
        return ((operator != "0" && schoolOperator != "0" && schoolOperator == operator) &&
          (governances[0] != "0" && schoolGovernance != "0" && governances.indexOf(schoolGovernance) != -1)) ||
          (operator == "0" && schoolGovernance != "0" && governances.indexOf(schoolGovernance) != -1) ||
          (governances[0] == "0" && schoolOperator != "0" && schoolOperator == operator) ||
          (governances[0] == "0" && operator == "0")
      };

      mapSchools = [];
      schoolData.each(function(i, n) {
        if (filterMatch(n)) {
          $('.school[data-tid=' + n.tid + ']').removeClass('hide');
          mapSchools.push(n.tid);
        }
      });

      schoolsMap.showMarkers(mapSchools);
    };

    if (gradeFilter == '0') {
      var schools = $('.school');
      schools.removeClass('hide');
      schoolsMap.showMarkers(schools.map(function(i, n) { return $(n).data('tid') }).toArray());
    } else {
      if (gradeFilter == 'ecs' || $('.filter-panel').not('.hide').first().hasClass('ec-filter')) {
        filterEC();
      } else {
        filterSchools();
      }
    }
  };

  return {
    filterResults: _filterResults
  }
}();

$(function() {
  $('.radio input').change(Filters.filterResults);

  $('.dropdown .trigger').click(function() {
    $(this).parent().toggleClass('open');
  });

  $('.panel-heading').click(function() {
    $(this).parent().find('.panel-collapse').toggleClass('collapse');
  });
});
