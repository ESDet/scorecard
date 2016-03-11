Filters = function() {
  var _displayFilterPanels = function(radio) {
    if (radio.name == 'school_type' && radio.value == '0') {
      $('#operator-filter').addClass('hide');
      $('#governance-filter').addClass('hide');
      $('#grade-filter').addClass('hide');
      $('#age-group-filter').addClass('hide');
    } else if (radio.value == 'ecs') {
      $('#operator-filter').addClass('hide');
      $('#governance-filter').addClass('hide');
      $('#grade-filter').addClass('hide');
      $('#age-group-filter').removeClass('hide');
    } else {
      $('#operator-filter').removeClass('hide');
      $('#governance-filter').removeClass('hide');
      $('#grade-filter').removeClass('hide');
      $('#age-group-filter').addClass('hide');
    }
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
        fields['age_groups'] = s.data('age_groups')
      } else {
        fields['grades_served'] = s.data('grades_served')
        fields['governance'] = s.data('governance')
        fields['operator'] = s.data('operator')
      }
      return fields;
    });

    var gradeFilter = $('#school-type-filter .radio input:checked')[0];
    if (gradeFilter) {
      gradeFilter = gradeFilter.value;
    }

    if (gradeFilter == '0') {
      $('.school').removeClass('hide');
    } else {
      if (gradeFilter == 'ecs') {
        var grades = $('#age-group-filter .radio input:checked');
        if (grades.length > 0) {
          grades = grades.map(function(i, n) {
            return n.value;
          });
        }
        grades = grades.toArray();

        if (grades.indexOf("0") == -1 && grades.length != 0) {
          var schoolGradeMatch = $(schoolData).map(function(i, n) {
            var isEcs = n.school_type == 'ecs';
            var hasGrade = false;
            if (isEcs) {
              $(grades).each(function(i, g) {
                if (n.age_groups.match(g) != null) {
                  hasGrade = true;
                  return;
                }
              });
              if (hasGrade) return n;
            }
            return null;
          });
          schoolGradeMatch.each(function(i, n) {
            $('.school[data-tid=' + n.tid + ']').removeClass('hide');
          });
        } else {
          $('.school[data-school_type=ecs]').removeClass('hide');
        }
      } else {
        var grades = [];
        $('#grade-filter .radio input:checked').each(function(i, n) {
          grades = grades.concat(n.value.split(","));
        });

        schoolData = $(schoolData).map(function(i, n) {
          var isK8HS = n.school_type == 'k8' || n.school_type == 'hs';
          if (isK8HS) {
            if (grades.length != 0 && grades[0] != "0") {
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
            return n;
          }
          return null;
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

        schoolData.each(function(i, n) {
          if (filterMatch(n)) {
            $('.school[data-tid=' + n.tid + ']').removeClass('hide');
          }
        });
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
