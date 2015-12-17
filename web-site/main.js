var add_amenity_to_menu = function(line) {
  var line_list = line.split('|');
  if (line_list.length != 3) return;
  var am_name = line_list[0];
  var am_count = line_list[1];
  /* var am_rank = line_list[2]; // not used */
  var new_html = '<li targetimage="' + am_name + '">' + am_name + ' (' + am_count + ')</li>';
  $('ul').append(new_html);
};

var process_am_data = function(file_content) {
  file_content.split("\n").forEach(add_amenity_to_menu);

  $('li').each(function(element) {
    var tagname = $(this).attr('targetimage')
    $(this).click(function(e) {
      $('li').removeClass('active');
      $(this).addClass('active');
      $('img').attr('src', 'images/osm-' + tagname + '.svg');
    });
    if (tagname === 'bench') {
      $(this).addClass('active');
      $(this).click();
    }
  });
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
