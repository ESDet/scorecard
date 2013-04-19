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


$(document).ready(function() {

  $('.help').popover({
    placement: 'left',
    delay: { show: 0, hide: 2000 }
  });

  // Demographics pie chart
  var bg = klosed ? colors.lightgrey : colors.light;
  var dem_plot = jQuery.jqplot ('dems', [dem_data], 
    { 
      grid: { background: bg, drawBorder: false, shadow: false }, 
      seriesColors: [ colors.lgreen, colors.dblue, colors.orange, colors.red, colors.yellow ],
      seriesDefaults: {
        renderer: jQuery.jqplot.PieRenderer, 
        shadow: false,
        rendererOptions: {
          showDataLabels: false,
          diameter: 90,
          padding: 0
        }
      }, 
      legend: { show:true, location: 'e', border: '0px', fontSize: '13px', background: bg }
    }
  );     

  if(high && $('#academics').length > 0) {
    // High school academics  
    var hs_academics_plot = jQuery.jqplot ('academics', [high_ac.state.scores, high_ac.school.scores],
      { 
        seriesColors: [ colors.lblue, colors.orange ],
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
          { label:'State', pointLabels: { show: true, labels: high_ac.state.labels } },
          { label:'School', pointLabels: { show: true, labels: high_ac.school.labels } }
        ],              
        legend: { show:true, location: 'e', border: '0px', fontSize: '13px', marginRight: '0px' },
        axes: {
          yaxis: {
            renderer: $.jqplot.CategoryAxisRenderer,
            ticks: high_ac.ticks,
            showTickMarks: false
          },
          xaxis: { min: 0, max: 120, padMin: 1.05, padMax: 1.05, numberTicks: 7 }
        }  
      }
    );
    
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

    
  } else {
    // Elementary school academics - reading 
    var plots = ['reading', 'math', 'third'];
    for(var i in plots) {
      var name = plots[i];
      if(elem_ac[name].school.length == 0 || $('#' + name).length == 0) {
        continue;
      }
      var elem_academics_plot = jQuery.jqplot (name, [elem_ac[name].state.scores, elem_ac[name].school.scores], 
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
            { label:'State', pointLabels: { show: true, labels: elem_ac[name].state.labels }  },
            { label:'School', pointLabels: { show: true, labels: elem_ac[name].school.labels }  }
          ],
          legend: { show:true, location: 'e', border: '0px', fontSize: '13px' },
          axes: {
            yaxis: {
              renderer: $.jqplot.CategoryAxisRenderer,
              ticks: elem_ac[name].ticks,
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
  while(history.length > 0 && history[0].length == 0) {
    history.shift();
    history_series.shift();
  }
  if(history.length > 0) {
    var history_plot = $.jqplot('historical', history,
      { 
        legend: { show:true, location: 'nw', fontSize: '13px', background: '#fff' },
        // Series options are specified as an array of objects, one object for each series.
        series: history_series
      }
    );
  } else {
    $('#historical').parent().hide();
  }
      

});
