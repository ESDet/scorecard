$(function() {
  var drawPie = function(element, data) {
    var w = 115,
      h = 115,
      radius = w / 2,
      color = d3.scale.category20(),
      pie = d3.scale.linear().
        domain([0, 50]).
        range([0, 2 * Math.PI]),
      arc = d3.svg.arc()
        .innerRadius(0)
        .outerRadius(radius)
        .startAngle(function(d) { return pie(d.start); })
        .endAngle(function(d) { return pie(d.end); });

    var vis = d3.select(element)
      .append("svg:svg")
      .attr("width", w)
      .attr("height", h);

    var arcs = vis.selectAll("path")
      .data(data)
      .enter()
      .append("path")
      .attr("d", arc)
      .style("fill", function(d) { return d.color; })
      .attr("transform", "translate(" + radius + "," + radius + ")");

    //arcs.append("path")
    //  .attr("d", d3.svg.arc().innerRadius(0).outerRadius(radius + 10).startAngle(0).endAngle(100))
    //  .style("fill", "white")
    //  .attr("transform", "translate(" + radius + "," + radius + ")");

    vis.selectAll("text")
      .data(data)
      .enter()
      .append("text")
      .attr("font-size", "12px")
      .attr("transform", function(d) {
        return "translate(" + (60 + 50) +  ")";
      })
      .text(function(d) { return d.label; });
  };

  var pieOpts = function(label, color, start, end) {
    return {
      label: label,
      color: color,
      start: start,
      end: end
    };
  };

  var pie = $('#pie');
  var aa = parseFloat(pie.data('aa')),
      a  = parseFloat(pie.data('a')),
      h  = parseFloat(pie.data('h')),
      w  = parseFloat(pie.data('w')),
      o  = parseFloat(pie.data('o'));

  drawPie("#pie", [
    pieOpts(
      "African American: " + aa + "%",
      "#2e5b8c", 0, aa || 0
    ),
    pieOpts(
      "Asian: " + a + "%",
      "#7cc45c", aa, aa + a
    ),
    pieOpts(
      "Hispanic: " + h + "%",
      "#2b9fc7", aa + a, aa + a + h
    ),
    pieOpts(
      "White: " + w + "%",
      "#f8ae16", aa + a + h, aa + a + h + w
    ),
    pieOpts(
      "Other: " + o + "%",
      "#ff690f", aa + a + h + w, aa + a + h + w + o
    )
  ]);
});
