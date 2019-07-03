$(function() {
        $('#mobile-menu').sidebar('setting', {
          transition: 'push'
        });
        $('#mobile-menu').sidebar('attach events', '#mobile-menu-toggle');
      
        $(window).scroll(function(e) {
          if($(this).scrollTop()>150){
            $('.back-to-top').fadeIn(1000); // Fading in the button on scroll after 150px
          }
          else {
            $('.back-to-top').fadeOut(500); // Fading out the button on scroll if less than 150px
          }
        });
      
        $('.back-to-top').click(function(e) {
          $('body, html').animate({scrollTop:0}, 800);
        });
      });
