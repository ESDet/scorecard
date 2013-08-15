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
  math: 320,
  reading: 340,
  science: 140,
  act: 350
};

var labels = {
  act: 'ACT Readiness',
  math: 'Math',
  reading: 'Reading',
  science: 'Science',
};

$(document).ready(function() {
  
  $('.help').popover({
    placement: 'left',
    delay: { show: 0, hide: 2000 }
  });

  // Demographics pie chart
  var bg = '#ffffff'; //klosed ? colors.lightgrey : colors.light;
  var dem_plot = jQuery.jqplot ('dems', [dem_data], 
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
  ); 
  
  $('.graph').each(function(idx, e) {
    var id = $(e).attr('id');
    var subject = $(e).data('subject');
    var grades = $(e).data('grades');
    var tab = $(e).data('tab');
    var ticks = _.keys(grades);
    var values = _.values(grades);
    if(values.length > 0) {
      var chart = jQuery.jqplot (id, [values],
        { 
          title: labels[subject] || subject,
          width: widths[subject],
          seriesDefaults: {
            renderer: jQuery.jqplot.BarRenderer, 
            color: '#00aff0',
            shadow: false,
            pointLabels: { show: true, location: 'n' },
            rendererOptions: {
              barDirection: 'vertical',
              barWidth: 35
            }
          }, 
          grid: { background: '#ffffff', drawGridlines: false, drawBorder: false, shadow: true, shadowWidth: 3, shadowDepth: 1, shadowAlpha: 0.2 }, 
          legend: { show:false },
          axes: {
            xaxis: {
              renderer: $.jqplot.CategoryAxisRenderer,
              ticks: ticks
            },
            yaxis: {
              tickOptions: { formatString: '%d%%' },
              min: 0,
              max: 115,
              ticks: [0, 25, 50, 75, 100, 115]
            }
          }  
        }
      );
      
      $(tab).on('shown', (function(ch) {
        return function(e) {
          ch.replot();
        };
      })(chart));
    }
  });
  
  $('.history').each(function(idx, e) {
    var id = $(e).attr('id');
    var grade = $(e).data('grade');
    var scores = $(e).data('scores'); // scores is { reading: { 2009 => 50, 2010 => 65.. }... }
    var tab = $(e).data('tab');
    var scores2 = _.map(scores, function(years, subj) { return _.values(years); });
    scores2 = _.filter(scores2, function(s) { return s.length > 0; });
    var subjects = _.keys(scores);
    var ticks = [2009, 2010, 2011, 2012];
    if(scores2.length > 0) {
      var chart = jQuery.jqplot (id, scores2,
        { 
          title: "Grade " + grade,
          width: 400,
          seriesDefaults: {
            renderer: jQuery.jqplot.BarRenderer, 
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
              max: 115,
              ticks: [0, 25, 50, 75, 100, 115]
            }
          }  
        }
      );
      
      $(tab).on('shown', (function(ch) {
        return function(e) {
          ch.replot();
        };
      })(chart));
    }
  });  
  
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
      

  return;
  
  if(high && $('#academics').length > 0) {
    // High school academics  
    
    var hs_act_plot = jQuery.jqplot ('act', [high_act.state, high_act.school],
      { 
        seriesColors: [ colors.light, colors.orange ],
        seriesDefaults: {
          renderer: jQuery.jqplot.BarRenderer, 
          shadow: false,
          pointLabels: { show: true, location: 'e', edgeTolerance: -15 },
          rendererOptions: {
            barDirection: 'horizontal',
            barWidth: 16,
            barPadding: 3
          }
        }, 
        grid: { background: '#ffffff', drawGridlines: false, drawBorder: false, shadow: false }, 
        series: [
          { label:'State' },
          { label:'School' }
        ],              
        legend: { show:true, location: 'e', border: '0px', fontSize: '13px' },
        axes: {
          yaxis: {
            renderer: $.jqplot.CategoryAxisRenderer,
            ticks: high_act.ticks,
            showTickMarks: false
          },
          xaxis: { min: 0, max: 42, pad: 1.05, numberTicks: 8 }
        }  
      }
    );
    if($('#grad').length > 0) {
      var hs_grad_plot = jQuery.jqplot ('grad', [high_grad.state, high_grad.school],
        { 
          seriesColors: [ colors.light, colors.orange ],
          seriesDefaults: {
            renderer: jQuery.jqplot.BarRenderer, 
            shadow: false,
            pointLabels: { show: true, location: 'e', edgeTolerance: -15 },
            rendererOptions: {
              barDirection: 'horizontal',
              barWidth: 16,
              barPadding: 3
            }
          }, 
          grid: { background: '#ffffff', drawGridlines: false, drawBorder: false, shadow: false }, 
          series: [
            { label:'State' },
            { label:'School' }
          ],              
          legend: { show:true, location: 'e', border: '0px', fontSize: '13px' },
          axes: {
            yaxis: {
              renderer: $.jqplot.CategoryAxisRenderer,
              ticks: high_grad.ticks,
              showTickMarks: false
            },
            xaxis: { min: 0, max: 120, pad: 1.05, numberTicks: 7 }
          }  
        }
      );      
    }
    
  }
  
  
  // Historical trends
  var history_series = [ 
    {
      label: history_labels[0],
      color: colors.red,
      lineWidth:3
    }, 
    { 
      label: history_labels[1],
      color: colors.dblue,
      lineWidth: 3
    }, 
    {
      label: history_labels[2],
      color: colors.lgreen,
      lineWidth:3
    }
  ];
  var options = { 
    axes: {
      xaxis: {
        ticks: [2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013],
        tickOptions: { formatString: '%d' }
      },
      yaxis: {
        ticks: [0, 20, 40, 60, 80, 100],
        tickOptions: { formatString: '%d' }
      }
    },
    legend: { show:true, location: 'nw', fontSize: '13px', background: '#fff' },
    // Series options are specified as an array of objects, one object for each series.
    series: history_series,
    
    highlighter: {
      show: true,
      //showTooltip: true,
      tooltipAxes: 'y',
      formatString:'%d%%'
    }        
  };

  if(high) {
    options.legend.show = false;
    if(history[1].length > 1) {
      options.series = [history_series[1]];
      var history_grad = $.jqplot('historical_grad', [history[1]], options);
    } else {
      $('#historical_grad').parent().hide();
    }
    if(history[0].length > 1) {
      options.series = [history_series[0]];
      options.axes.yaxis.ticks = [0, 6, 12, 18, 24, 30, 36];
      options.highlighter.formatString = '%d';
      var history_act = $.jqplot('historical_act', [history[0]], options);
    } else {
      $('#historical_act').parent().hide();
    }
    if(history[0].length < 2 && history[1].length < 2) {
      $('#historical_act').parent().parent().hide();
    }
    
  } else {
    // Elementary schools
    if(history.length > 0) {
      while(history.length > 0 && history[0].length == 0) {
        history.shift();
        history_series.shift();
      }
      options.series = history_series;
      var history_plot = $.jqplot('historical', history, options);
    } else {
      $('#historical').parent().hide();
    }
  }

      

});
