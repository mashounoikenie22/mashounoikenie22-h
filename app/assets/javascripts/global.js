$(document).ready(function() {
    // setup twitter feed
    $(".tweet").tweet();

    // scroll body to 0px on click
    $('#back-to-top a').click(function () {
	    $('body,html').animate({
		    scrollTop: 0
	    }, 800);
	    return false;
    });
});

