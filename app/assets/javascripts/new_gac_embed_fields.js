Blacklight.onLoad(function() { 
  $('form').on('click', '.add_fields', function(e) {
    e.preventDefault();
    var regexp, time;
    time = new Date().getTime();
    regexp = new RegExp($(this).data('id'), 'g');
    $(this).before($(this).data('fields').replace(regexp, time))
  });
});
