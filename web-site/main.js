var add_amenity_to_menu = function(line) {
  var line_list = line.split('|');
  if (line_list.length != 3) return;
  var am_name = line_list[0];
  var am_count = line_list[1];
  /* var am_rank = line_list[2]; // not used */
  var new_html = '<li tag="' + am_name + '">' + am_name + ' (' + am_count + ')</li>';
  $('ul').append(new_html);
};

function get_url_parameter(key, default_value) {
  var args = location.search.split('?').splice(1);
  for (var i in args) {
    var isplit = args[i].split('=');
    if (isplit[0] == key) return isplit[1];
  }
  return default_value;
}

var process_am_data = function(file_content) {
  file_content.split("\n").forEach(add_amenity_to_menu);

  $('li').each(function(element) {
    var tagname = $(this).attr('tag')
    $(this).click(function(e) {
      $('li').removeClass('active');
      $(this).addClass('active');
      window.history.pushState("", "", 'index.html?amenity=' + tagname);
      $('#selectedimage').attr('src', 'images/osm-' + tagname + '.svg');
    });
  });

  var url_tag = get_url_parameter('amenity', 'bench');
  $('li[tag=' + url_tag + ']').click();

  /* scroll left menu to selected tag */
  var pxDistance = Math.max($('li[tag=' + url_tag + ']').offset().top, 0);
  if ($(window).height() > pxDistance) return;
  var offset = pxDistance - $(window).height() * 0.5;
  var aniTime = Math.min(0.25 * offset, 500);
  $('#left-menu').animate({ scrollTop: offset }, aniTime);
};

var request = new XMLHttpRequest();
request.open('GET', 'am_data.txt', /* async = */ true);
request.responseType = 'text';
request.onreadystatechange = function() {
  if (request.readyState == 4 && request.status == 200) {
    process_am_data(request.response);
  }
};

request.send(null);
