var colors = {
  light:      '#eef',
  lightgrey:  '#e8e8e8',
  dblue:      '#004270',
  orange:     '#f79421',
  lblue:      '#85d5e3',
  yellow:     '#ffcc4e',
  lgreen:     '#8dc63f',
  red:        '#953734',
  greyish:    '#556677'
};

var widths = {
  math: 300,
  reading: 300,
  science: 140,
  act: 300
};

var labels = {
  act:      'ACT Readiness',
  math:     'Math',
  reading:  'Reading',
  english:  'English',
  science:  'Science',
  allsub:   'All Subjects'
};

var state_avg = {
  grd4math: 0.449491684235184,
  grd5math: 0.45725703803534,
  grd6math: 0.40152655148032,
  grd7Math: 0.38387487099185,
  grd8math: 0.325276515015929,
  grd3reading: 0.665312708657912,	
  grd4reading: 0.680764615282857,	
  grd5reading: 0.703891310692866,	
  grd6reading: 0.682231246926845,	
  grd7reading: 0.620312277199487,	
  grd8reading: 0.657135181122106,	
  grd5science: 0.158616942974309,	
  grd8science: 0.158616942974309
};

$(document).ready(function() {
  
  $('.help').popover({
    placement: 'left',
    delay: { show: 0, hide: 2000 }
  });

  // Demographics pie chart
  var bg = '#ffffff'; //klosed ? colors.lightgrey : colors.light;
  /*var dem_plot = jQuery.jqplot ('dems', [dem_data], 
    { 
      grid: { background: bg, drawBorder: false, shadow: false }, 
      seriesColors: [ colors.lgreen, colors.dblue, colors.orange, colors.red, colors.yellow ],
      seriesDefaults: {
        renderer: jQuery.jqplot.PieRenderer, 
        shadow: false,
        rendererOptions: {
          showDataLabels: false,
          diameter: 140,
          padding: 0
        }
      }, 
      legend: { show:true, location: 'e', border: '0px', fontSize: '13px', background: bg }
    }
  );*/ 
  
  $('.graph').each(function(idx, e) {
    var id = $(e).attr('id');
    var subject = $(e).data('subject');
    var grades = $(e).data('grades');
    var tab = $(e).data('tab');
    var ticks = _.keys(grades);
    var values = _.values(grades);
    var title = labels[subject] || subject;
    var direction = $(e).data('direction') || 'vertical';
    if(subject == 'reading' || subject == 'math' || subject == 'science') {
      title += " by Grade";
    } else if(subject == 'act') {
      ticks = _.map(ticks, function(i) { return labels[i] || i; });
    }
    
    if(values.length > 0) {
      opts = {
        title: title,
        width: widths[subject],
        seriesDefaults: {
          renderer: jQuery.jqplot.BarRenderer, 
          shadow: false,
          pointLabels: { show: true, location: 'n' },
          rendererOptions: {
            barDirection: direction,
            barWidth: 35
          }
        }, 
        grid: { background: '#ffffff', drawGridlines: false, drawBorder: false, shadow: true, shadowWidth: 3, shadowDepth: 1, shadowAlpha: 0.2 }, 
        legend: { show:false },
        axes: {
          
        }  
      };
      opts.axes[direction == 'vertical' ? 'xaxis' : 'yaxis'] = {
        renderer: $.jqplot.CategoryAxisRenderer,
        ticks: ticks
      };
      opts.axes[direction == 'vertical' ? 'yaxis' : 'xaxis'] = {
        tickOptions: { formatString: '%d%%' },
        min: 0,
        max: 100,
        ticks: [0, 25, 50, 75, 100]
      };
      
      var chart = jQuery.jqplot (id, [values], opts);
      
      $(tab).on('shown', (function(ch) {
        return function(e) {
          ch.replot();
        };
      })(chart));
    } else {
      $('#' + id).hide();
    }
  });
  
  var notAllNulls = function(arr) {
    return _.some(arr, function(i) { return i !== null; });
    //var chk = _.reject(arr, function(i) { return i === null; });
  };
  
  $('.history').each(function(idx, e) {
    var id = $(e).attr('id');
    var grade = $(e).data('grade');
    var scores = $(e).data('scores'); // scores is { reading: { 2009 => 50, 2010 => 65.. }... }
    var tab = $(e).data('tab');
    var scores2 = _.map(scores, function(years, subj) { return _.values(years); });
    scores2 = _.filter(scores2, function(s) { return notAllNulls(s); });
    var subjects = _.keys(scores);
    var ticks = [2010, 2011, 2012, 2013];
    if(scores2.length > 0) {
      var chart = jQuery.jqplot (id, scores2,
        { 
          title: "Grade " + grade,
          width: 300,
          seriesDefaults: {
            renderer: jQuery.jqplot.LineRenderer, 
            //color: '#00aff0',
            shadow: false,
            pointLabels: { show: true, location: 'n' },
            rendererOptions: {
              barDirection: 'vertical'
            }
          }, 
          grid: { background: '#ffffff', drawGridlines: false, drawBorder: false, shadow: true, shadowWidth: 3, shadowDepth: 1, shadowAlpha: 0.2 }, 
          legend: { show: true },
          series: _.map(subjects, function(s) { return { label: labels[s] } }),
          axes: {
            xaxis: {
              renderer: $.jqplot.CategoryAxisRenderer,
              ticks: ticks
            },
            yaxis: {
              tickOptions: { formatString: '%d%%' },
              min: 0,
              max: 100,
              ticks: [0, 25, 50, 75, 100]
            }
          }  
        }
      );
      
      $(tab).on('shown', (function(ch) {
        return function(e) {
          ch.replot();
        };
      })(chart));
    } else {
      $('#' + id).hide();
    }
  });  
  
  if($('#enroll').length > 0) {
    var enroll_plot = jQuery.jqplot ('enroll', [enroll],
      { 
        title: 'Enrollment by Grade',
        seriesDefaults: {
          renderer: jQuery.jqplot.BarRenderer, 
          shadow: false,
          pointLabels: { show: true, location: 'n' },
          rendererOptions: {
            barDirection: 'vertical',
            barWidth: 18,
            barPadding: 3
          }
        }, 
        grid: { background: '#ffffff', drawGridlines: false, drawBorder: false, shadow: false }, 
        legend: { show:false },
        axes: {
          xaxis: {
            renderer: $.jqplot.CategoryAxisRenderer,
            ticks: enroll_ticks,
          },
          yaxis: {
            tickOptions: { formatString: '%d' }
          }
        }  
      }
    );
  }


});
