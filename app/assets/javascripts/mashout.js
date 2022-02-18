$(function() {
    $('#mashout-target-container .ui-autocomplete-input').css('width','300px');
    $('#mashout-media-container .ui-autocomplete-input').css('width','300px');
    $('#mashout-comment-container .ui-autocomplete-input').css('width','300px');

    decorateMashoutTrendAutoCompleteSelect();

    $("#mashout-chars-left").keypress(function() {
        return false;
    });

    $("#out-preview").keyup(function(){
        calculateCharsLeft();
    });

    // setup ready to mashout floating step
    if($('#sidebar').offset() != null) {
        var top = $('#sidebar #ready-to-mashout .content').offset().top - parseFloat($('#sidebar #ready-to-mashout .content').css('top').replace(/auto/, 0));

        $(window).scroll(function (event) {
            // what the y position of the scroll is
            var y = $(this).scrollTop();

            // whether that's below the form
            if (y >= top) {
                // if so, ad the fixed class
                $('#sidebar #ready-to-mashout .content').addClass('fixed');
            } else {
                // otherwise remove it
                $('#sidebar #ready-to-mashout .content').removeClass('fixed');
            }
        });
    }
});

function generateOutFragment(value, targetId, add) {
    var target  = $(targetId);
    var current = target.val();

    if(add) {
        if(current.length == 0) {
            target.val(value);
        } else {
            target.val(current + ' ' + value);
        }
    } else {
        var regex = new RegExp('\\s*' + value, 'gi');

        if(current.search(regex) == 0) {
            target.val(current.replace(new RegExp(value + '\\s*', 'gi'), ''));
        } else {
            target.val(current.replace(regex, ''));
        }
    }
}

function generateDynamicOutPreview(outPreviewId) {
    var media     = $('#hidden-media').val();
    var targets   = $('#hidden-targets').val();
    var tsTargets = $('#hidden-trendspottr-targets').val() || '';
    var rtTargets = $('input[name^="hidden-retweet-targets"]');
    var hashtags  = $('#hidden-hashtags').val();
    var trends    = $('#hidden-trends').val();
    var tsTrends  = $('#hidden-trendspottr-trends').val() || '';
    var comment   = $('#hidden-comment').val();
    var video     = $('#hidden-video').val();
    var content   = ''

    var needsPadding  = function() { return ; }
    var addContent    = function(fragment) {
        if(content.length > 0) {
            content += ' ';
        }

        content += fragment;
        if(content.length > 140) {
            $('#mashout-chars-left').addClass('negative-char-count');
        } else {
            $('#mashout-chars-left').removeClass('negative-char-count');
        }
    }

    $.each([media, targets, tsTargets, hashtags, trends, tsTrends, comment, video], function() {
        if(this.length > 0) {
            addContent(this);
        }
    });

    var rtTargetsArray = $.map(rtTargets, function(target, index) {
        var value = $(target).val();

        if(value.length > 0)
        {
            return value;
        }
    });

    rtTargetsArray = $.unique(rtTargetsArray);

    $.each(rtTargetsArray, function(index, target) {
        if(target.length > 0)
        {
            addContent(target);
        }
    });

    $(outPreviewId).val(content);
    calculateCharsLeft();
}

function handleDynamicPreviewCheckboxChange(checkboxId, hiddenCheckboxId, outPreviewId) {
    var value     = unescape($(checkboxId).val());
    var isChecked = $(checkboxId).prop('checked');

    generateOutFragment(value, hiddenCheckboxId, isChecked);
    generateDynamicOutPreview(outPreviewId);
}

function bindDynamicPreviewTargetChange(checkboxId, hiddenCheckboxId, outPreviewId, checkboxClass) {
    $(checkboxId).change(function() {
        var value       = $(this).val();
        var hiddenValue = $(hiddenCheckboxId).val();
        var isChecking  = $(checkboxId).prop('checked') // the current state of the checkbox

        if(hiddenValue.search(value) < 0) {
            // if the value is not present then add it
            handleDynamicPreviewCheckboxChange(checkboxId, hiddenCheckboxId, outPreviewId);
        } else if(hiddenValue.search(value) >= 0 && !isChecking) {
            // if the value is present and the checkbox is not being checked then remove it
            generateOutFragment(value, hiddenCheckboxId, false);
            generateDynamicOutPreview(outPreviewId);
        }
        // otherwise do nothing

        // Update the parent checkbox
        var allChecked = $('.' + checkboxClass + ':checked').length == $('.' + checkboxClass).length
        $('#' + checkboxClass).prop('checked', allChecked)
    });
}

function bindDynamicPreviewAutoCompleteSelectAndHandleTarget(wrapperId, selectId, hiddenFieldId, outPreviewId) {
    bindAutoCompleteSelect(wrapperId, selectId, function(oldValue, newValue) {
        var current = $(hiddenFieldId).val();
        var isNone  = newValue == 'NONE';

        generateOutFragment(current, hiddenFieldId, false);
        generateDynamicOutPreview(outPreviewId);
    });
}

function bindDynamicPreviewAutoCompleteSelectAndHandle(wrapperId, selectId, hiddenFieldId, outPreviewId) {
    bindAutoCompleteSelect(wrapperId, selectId, function(oldValue, newValue) {
        var current = $(hiddenFieldId).val();
        var isNone  = newValue == 'NONE';

        generateOutFragment(current, hiddenFieldId, false);
        generateOutFragment(isNone ? oldValue : unescape(newValue), hiddenFieldId, !isNone);
        generateDynamicOutPreview(outPreviewId);
    });
}

function bindDynamicPreviewVideoRadioClick(radioId, sourceId, hiddenRadioId, outPreviewId) {
    $(radioId).click(function() {
        var newValue = unescape($(sourceId).val());
        var oldValue = unescape($(hiddenRadioId).val());

        generateOutFragment(oldValue, hiddenRadioId, false);
        generateOutFragment(newValue, hiddenRadioId, true);
        generateDynamicOutPreview(outPreviewId);
    });
}

function bindDynamicPreviewCheckboxClick(checkboxId, hiddenCheckboxId, outPreviewId) {
    $(checkboxId).click(function() {
        handleDynamicPreviewCheckboxChange(checkboxId, hiddenCheckboxId, outPreviewId);
    });
}

function calculateCharsLeft() {
    $("#mashout-chars-left").text(140 - $('#out-preview').val().length);
}

function decorateMashoutTrendAutoCompleteSelect() {
    $('#mashout-trend-container .ui-autocomplete-input').css('width','300px');
    $('#mashout-location-container .ui-autocomplete-input').css('width','300px');
    $('#mashout-google-container .ui-autocomplete-input').css('width','300px');
    $('#mashout-region-container .ui-autocomplete-input').css('width','300px');
    $('#mashout-trendspottr-container .ui-autocomplete-input').css('width','300px');
}

function bindAutoCompleteSelect(wrapperId, selectId, callback) {
    $(wrapperId).bind('autocompleteselect', function (event, ui) {
        var oldValue = $(selectId).val();
        var newValue = ui.item.option.value;

        $(selectId).val(newValue);
        $(selectId).change();

        if(callback !== undefined) {
          callback(oldValue, newValue);
        }
    });
}

function bindTrendAutoCompleteSelectAndHandle(wrapperId, selectId, path) {
    bindAutoCompleteSelect(wrapperId, selectId, function(oldValue, newValue) { handleTrendAutoCompleteSelection(path); });
}

function bindTargetAutoCompleteSelectAndHandle(wrapperId, selectId, path) {
    bindAutoCompleteSelect(wrapperId, selectId, function(oldValue, newValue) { handleTargetAutoCompleteSelection(path); });
}

function elementExists(id) {
    return $(id).length > 0;
}

function selectAutocomplete(wrapperId, selectId, value) {
    if(elementExists(wrapperId) && value !== undefined) {
        $(selectId).next().val($(selectId + " option[value='" + value + "']").text()).blur();
    }
}

function handleTargetAutoCompleteSelection(path) {
    var params          = {}
    var trendSelection  = $('#mashout-target-selection').val();
    var tweopleExists   = $('#mashout-target-tweople-source-selection').length > 0;

    params['mashout-target'] = trendSelection;

    if(tweopleExists) {
        params['mashout-tweople-source'] = $('#mashout-target-tweople-source-selection').val();
    }

    $.ajax({url: path,
            data: params,
            success: function(data) { $('#mashout-target-container').replaceWith(data); },
            async: false});

    createAutocompleteComboboxes(function() {
        $('#mashout-target-container .ui-autocomplete-input').css('width','300px');
    });

    selectAutocomplete('#mashout-target-container', '#mashout-target-selection', trendSelection);

    if(tweopleExists) {
        selectAutocomplete('#mashout-target-tweople-container', '#mashout-target-tweople-source-selection', params['mashout-tweople-source']);
    }
}

function handleTrendAutoCompleteSelection(path) {
    var params            = {};
    var trendExists       = $('#mashout-trend-container').length > 0;
    var locationExists    = $('#mashout-location-container').length > 0;
    var regionExists      = $('#mashout-region-container').length > 0;
    var trendSpottrExists = $('#mashout-location-container #mashout-trendspottr-selection').length > 0;

    if(trendExists) {
        params.trend_source = $('#mashout-trend-selection').val();
    }

    if(locationExists) {
        params.trend_location = $('#mashout-location-selection').val();
    }

    if(regionExists) {
        params.trend_region = $('#mashout-region-selection').val();
    }

    if(trendSpottrExists) {
        params.trendspottr_location = $('#mashout-trendspottr-selection').val();
    }

    $.ajax({url: path,
            data: params,
            success: function(data) { $('#mashout-trend').replaceWith(data); },
            async: false});

    createAutocompleteComboboxes(function() {
        decorateMashoutTrendAutoCompleteSelect();
    });

    if(trendExists) {
        selectAutocomplete('#mashout-trend-container', '#mashout-trend-selection', params.trend_source);
    }

    if(locationExists) {
        selectAutocomplete('#mashout-location-container', '#mashout-location-selection', params.trend_location);
    }

    if(trendSpottrExists) {
        selectAutocomplete('#mashout-location-container', '#mashout-trendspottr-selection', params.trendspottr_location);
    }

    $('#hidden-trends').val('');
    generateDynamicOutPreview('#out-preview');
}

function bindCaptureOutPreviewVideoLink(sourceId, outPreviewId, targetId) {
  $(sourceId).click(function() {
      var content = $(outPreviewId).val();
      var link    = content.match(/http:\/\/out.am\/\w+/, 'gi');

      $(targetId).val(link === undefined ? '' : link);
  });
}

function bindMashoutClearPreviewClick() {
    $('#preview-clear-out').click(function() {
        // clear the visible checkboxes
        $('#mashout-form input[type=checkbox]').each(function() {
            $(this).prop("checked", false);
        });

        // turn off all media icons
        $('#media-icons li').each(function() {
            $(this).removeClass('on');
        })

        // clear the hidden checkbox fields
        $('#mashout-form #hidden-hashtags').val('');
        $('#mashout-form #hidden-trends').val('');
        $('#mashout-form #hidden-trendspottr-trends').val('');
        $('#mashout-form #hidden-trendspottr-targets').val('');

        // clear the drop-downs, except target orientated ones
        selectAutocomplete('#mashout-comment-container', '#mashout-comment', 'NONE');
        selectAutocomplete('#mashout-media-container', '#mashout-media', 'NONE');

        // clear the hidden drop-down fields
        $('#mashout-form #hidden-comment').val('');
        $('#mashout-form #hidden-media').val('');
        $('#mashout-form #hidden-targets').val('');

        // clear the video radio buttons and radio hidden field
        var videoRadioButton = $("#mashout-form input[name='mashout-video']");
        if(videoRadioButton.length > 0) {
            videoRadioButton.prop("checked", false);
            $('#mashout-form #hidden-video').val('');
        }

        // clear the data field from the Trendspottr search box
        if($('#trendspottr-query') && $('#trendspottr-query').data('searchList')) {
            $('#trendspottr-query').data('searchList', []);
            updateDynamicTrendspottrSearch('#trendspottr-query');
        }

        // clear any flash messages on the page from building outs
        clearFlashMessages();

        $('#out-preview').val('');
        calculateCharsLeft();
        return false;
    });
}

function bindMashoutTargetToReply(targetId, replyId) {
    $(targetId).click(function() { $(replyId).prop("checked", ($(this).prop("checked"))); });
}

function bindMashoutMasterTargetToChildTargets(masterTargetId) {
    $("#" + masterTargetId).change(function() {
        $("." + masterTargetId).prop("checked", ($(this).prop("checked")));
        $("." + masterTargetId).change();
    });
}

function bindMashoutShowMoreTweets(sourceId, targetId) {
    $(sourceId).click(function() {
        $(targetId).toggle();
        return false;
    });
}

function updateDynamicTrendspottrSearch(queryTargetId) {
    var searchTerms = $(queryTargetId).data('searchList')

    if(searchTerms) {
        $(queryTargetId).val(searchTerms.join(' '))
    } else {
        $(queryTargetId).val()
    }
}

function bindDynamicTrendSpottrCheckboxClick(checkboxName, targetId) {
    $('input[name="' + checkboxName + '"]').click(function() {
        var value     = $(this).val()
        var isChecked = $(this).prop('checked')

        if (!$(targetId).data('searchList')) {
            $(targetId).data('searchList', [])
        }

        if (isChecked) {
            $(targetId).data('searchList').push(value)
        } else {
            var index = $(targetId).data('searchList').indexOf(value)

            if (index != -1) {
                $(targetId).data('searchList').splice(index, 1)
            }
        }

        updateDynamicTrendspottrSearch(targetId)
    })
}

function handleTrendSpottrSearchSubmission(buttonId, targetId, path) {
    var params = {}

    params.trend_location = $('#mashout-trendspottr-selection').val()
    params.trend_search   = $('#trendspottr-query').val()

    if ($(window).scrollTop() > $('#trendspottr-query').offset().top) {
        $('html, body').animate({
             scrollTop: $("#trendspottr-query").offset().top
         }, 400, function() { $(targetId).hide() })
    }
    else
    {
        $(targetId).hide()
    }

    $.ajax({url: path,
            data: params,
            success: function(data) {
                $(targetId).html(data)
            },
            error: function() {
                $(targetId).html('<hr class="space" /><strong><em>Search Results</em></strong><hr class="space" />No results.')
            },
            complete: function() {
                $(targetId).show()
                $('#mashout-trendspottr-container img.spinner').remove()
                $(buttonId).prop('disabled', false)
                $('html, body').animate({
                    scrollTop: $(targetId).offset().top
                }, 400)
            },
            timeout: 15000
    })

    return false
}

function bindTrendSpottrSearchButton(buttonId, targetId, path) {
    $(buttonId).click(function() {
        if ($.trim($('#trendspottr-query').val()) == '')
        {
            $('#trendspottr-query').focus()
            return false
        }

        $(buttonId).prop('disabled', true)
        $('#mashout-trendspottr-container').append('<img class="spinner left" src="/assets/spinner.gif" />')
        handleTrendSpottrSearchSubmission(buttonId, targetId, path)

        return false
    })
}

function hideElements($elements) {
    $.map($elements, function(element) {
        element.hide()
    })
}

function showElements($elements) {
    $.map($elements, function(element) {
        element.show()
    })
}

function makeHashtagEditable(hashtagId) {
    hideElements([$(hashtagId + '-label'), $(hashtagId + '-edit')])
    showElements([$(hashtagId + '-text'), $(hashtagId + '-confirm'), $(hashtagId + '-cancel')])
}

function makeHashtagFixed(hashtagId) {
    var error = $(hashtagId + '-container > p')

    if(error) {
        error.remove()
    }

    hideElements([$(hashtagId + '-cancel'), $(hashtagId + '-text'), $(hashtagId + '-confirm')])
    showElements([$(hashtagId + '-label'), $(hashtagId + '-edit')])
}

function inlineEdit(hashtagId, editPath) {
    $(hashtagId + '-edit').click(function(e) {
        e.preventDefault()
        makeHashtagEditable(hashtagId)
    })
    $(hashtagId + '-cancel').click(function(e) {
        e.preventDefault()
        $(hashtagId + '-text').val($(hashtagId).val())
        makeHashtagFixed(hashtagId)
    })
    $(hashtagId + '-delete').click(function(e) {
        e.preventDefault()

        var hashtag = $(hashtagId).val()

        $.ajax({
            url: $(this).attr('href'),
            type: "DELETE",
            success: function(data) {
                $(hashtagId + '-container').fadeOut('slow', function() {
                    $(this).remove()
                    generateOutFragment(hashtag, '#hidden-hashtags', false)
                    generateDynamicOutPreview('#out-preview')
                })
            }
        })
    })
    $(hashtagId + '-confirm').click(function(e) {
        e.preventDefault();

        var oldHashtag   = $(hashtagId).val()
        var newHashtag   = $(hashtagId + '-text').val()
        var newHashtagId = '#mashout-' + newHashtag.replace('#', '').replace(/[^\w]/, '') + '-hashtag'
        var wasChecked   = $(hashtagId).prop('checked')

        if ($.trim(oldHashtag) == $.trim(newHashtag)) {
            $(hashtagId + '-cancel').click()
            return false
        }

        $.ajax({
            url: editPath,
            type: "PUT",
            data: {user_hashtag: {tag: $(hashtagId + '-text').val() }, checked: wasChecked},
            dataType: 'html',
            success: function(data) {
                if(wasChecked)
                {
                    generateOutFragment(oldHashtag, '#hidden-hashtags', false)
                }
                $(hashtagId + '-container').replaceWith(data)
            }
        })
    })
    $(hashtagId + '-text').keypress(function(e) {
        if(e.which == 13)
        {
            $(hashtagId + '-confirm').click()
        }
    })
}

function initializeNewHashtagListeners(newHashtagPath, createHashtagPath) {
    $('#new-mashout-hashtag-cancel').live('click', function(e) {
        e.preventDefault()
        $('#new-mashout-hashtag-container').remove()
    })
    $('#new-mashout-hashtag-confirm').live('click', function(e) {
        e.preventDefault()
        $.ajax({
            url: createHashtagPath,
            type: "POST",
            dataType: 'html',
            data: { user_hashtag: { tag: $('#new-mashout-hashtag-text').val() } },
            success: function(data) {
                $('#new-mashout-hashtag-container').replaceWith(data)
            }
        })
    })
    $('#new-mashout-hashtag-text').live('keypress', function(e) {
        if(e.which == 13) {
            $('#new-mashout-hashtag-confirm').click()
        }
    })
    $('#new-hashtag').click(function(e) {
        e.preventDefault()

        if($('#new-mashout-hashtag-container').length > 0) {
            return false
        }

        // Add the new hashtag above the new hashtag link
        $.ajax({
            url: newHashtagPath,
            type: 'GET',
            dataType: 'html',
            success: function(data) {
                $('#new-hashtag').before(data)
            }
        })
    })
}

function pagePeekerImageURL(src) {
    return 'http://pagepeeker.com/thumbs.php?size=l&url=' + src
}

function bindTrendspottrLinkToTarget(linkClass, targetId) {
    $('.' + linkClass).click(function(e) {
        e.preventDefault()
        var src    = pagePeekerImageURL($(this).attr('href'))
        var iframe = $('<iframe/>', { id: targetId + '-iframe', src: src})
        $('#' + targetId).html(iframe)
    })
}

function bindTrendSpotButtonForCheckbox(checkboxId) {
    $(checkboxId + '-submit').click(function(e) {
        e.preventDefault();

        var checkbox        = $(checkboxId);
        var checkboxName    = checkbox.attr('name');
        var search          = $('#trendspottr-query');
        var checkedTopics   = $('input[name="mashout-trendspottr-topics[]"]:checked');
        var checkedSearches = $('input[name="mashout-trendspottr-searches[]"]:checked');

        $.each([checkedTopics, checkedSearches], function(index, checkboxes) {
            checkboxes.each(function(idx) {
                $(this).prop('checked', false);
            });
        });

        if(checkboxName.match(/topics/) || checkboxName.match(/searches/)) {
            checkbox.prop('checked', true);
            search.data('searchList', [unescape(checkbox.val())])
        }
        else
        {
            search.data('searchList', []);
        }

        search.val(unescape(checkbox.val()));

        $('#trendspottr-search').click();
    });
}

function bindAjaxSubmitAndFlash(formId, buttonId, targetId) {
    var form      = $(formId);
    var spinnerId = form.attr('id') + '-spinner'

    form.submit(function(e) {
        e.preventDefault();

        $(buttonId).before($('<img/>', { id: spinnerId, src: '/assets/spinner.gif'}));
        $(buttonId).prop('disabled', true);

        $.ajax({
            url: form.attr('action'),
            type: form.attr('method'),
            data: form.serialize(),
            success: function(data) {
                clearFlashMessages();
                $(targetId).before(data);
            },
            error: function(xhr, textStatus, errorThrown) {
                clearFlashMessages();
                $(targetId).before($('<p/>', { 'class': 'error', text: errorThrown + '. Please try again later.' }));
            },
            complete: function() {
                $('#' + spinnerId).remove();
                $(buttonId).prop('disabled', false);
            }
        });
    });
}

function clearFlashMessages() {
    $('p.error, p.success').remove();
}
