Blacklight.onLoad(function() { 
  $('form').on('click', '.add_fields', function(e) {
    e.preventDefault();
    var fields = e.target.dataset.fields;
    var regexp, time;
    time = new Date().getTime();
    regexp = new RegExp($(this).data('id'), 'g');
    $('.new_fields').append(fields)
  });
});
