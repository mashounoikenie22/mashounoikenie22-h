function prependFlashAndFadeOut(containerId, flash) {
    $(containerId).prepend(flash)
    flash.delay(2000).fadeOut(1000, function() { flash.remove() })
}

function generateFlashError(options) {
    options['class'] = 'error'
    return generateFlash(options)
}

function generateFlashSuccess(options) {
    options['class'] = 'success'
    return generateFlash(options)
}

function generateFlash(options) {
    return $('<p/>', options)
}
