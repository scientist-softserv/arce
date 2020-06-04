$(document).ready(function() {
  $(".menu-item-about").hover(
      function() {
          $('ul.drop-about').stop(true, true).slideDown('medium');
      },
      function() {
          $('ul.drop-about').stop(true, true).slideUp('medium');
      }
  );
    $(".menu-item-discover").hover(
      function() {
          $('ul.drop-discover').stop(true, true).slideDown('medium');
      },
      function() {
          $('ul.drop-discover').stop(true, true).slideUp('medium');
      }
  );
  $(".menu-item-events").hover(
    function() {
        $('ul.drop-events').stop(true, true).slideDown('medium');
    },
    function() {
        $('ul.drop-events').stop(true, true).slideUp('medium');
    }
  );
  $(".menu-item-cultural-heritage").hover(
    function() {
        $('ul.drop-cultural-heritage').stop(true, true).slideDown('medium');
    },
    function() {
        $('ul.drop-cultural-heritage').stop(true, true).slideUp('medium');
    }
  );
  $(".menu-item-research").hover(
    function() {
        $('ul.drop-research').stop(true, true).slideDown('medium');
    },
    function() {
        $('ul.drop-research').stop(true, true).slideUp('medium');
    }
  );
  $(".menu-item-membership").hover(
    function() {
        $('ul.drop-membership').stop(true, true).slideDown('medium');
    },
    function() {
        $('ul.drop-membership').stop(true, true).slideUp('medium');
    }
  );
});