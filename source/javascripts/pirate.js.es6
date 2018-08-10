
// alert('welcome to pirate island!');

jQuery(function(){

    jQuery(window).on('resize', function() {

        var innerContainer = $('.pirate-island'),
            height = $('.ui-page-active').outerHeight() - $('.ui-header').outerHeight(),
            width = $('.pirate-island-container').outerWidth();
        // setup the container height
        $('.pirate-island-container').height(height);
        // setup the correct scaling factor

        var scaleX = width / innerContainer.width(),
            scaleY = height / innerContainer.height(),
            scaleFactor = Math.min(scaleX, scaleY),
            top = 0,
            left = 0;
            if(scaleFactor == scaleX) {
                // scaling up down
                top = (height - (innerContainer.height()*scaleX)) / 2;
            }
            if(scaleFactor == scaleY) {
                // scaling left right
                left = (width - (innerContainer.width()*scaleY)) / 2;
            }
        innerContainer.css({
            transform: `scale(${scaleFactor})`,
            top: top,
            left: left
        });
    }).trigger('resize');

    // jquery(window).off('resize') // when leaving this page
});