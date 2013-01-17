class NewPostView extends Poe3.PageView

    initialize: =>
        $('#content').html @el
        @render()

        
        
    render: =>
        @setTitle 'Create a New Poem'
        $(@el).html @template {}
        @attachEvents()
        @updateForm()
        @onRenderComplete '.new-post-view'
        
        

    attachEvents: =>
        self = this

        #Authoring Mode
        $(document).bindNew 'click', '.authoring-mode li', ->
            if not $(@).hasClass 'disabled'                
                $('.authoring-mode li').removeClass 'selected'
                $(this).addClass 'selected'
                self.updateForm()
            false
            
        #Type of post
        $(document).bindNew 'click', '.post-type li', ->
            if not $(@).hasClass 'disabled'                
                $('.post-type li').removeClass 'selected'
                $(this).addClass 'selected'
                self.updateForm()
            false

        #Speech Bubbles
        self.speechBubble = {}
        for _t in ['haiku', 'six-word-story', 'quote', 'free-verse']
            do(_t) ->
                $(document).bindNew 'mouseenter', ".post-type li[data-value=\"#{_t}\"]", ->
                    self.speechBubble[_t] = ->            
                        $(".speech-bubble").hide()    
                        $(".speech-bubble.#{_t}").show()
                    setTimeout (-> self.speechBubble[_t]?()), 1000
                $(document).bindNew 'mouseleave', ".post-type li[data-value=\"#{_t}\"]", ->
                    self.speechBubble[_t] = null
                    setTimeout (-> 
                        if not self.speechBubble[_t]?
                            $(".speech-bubble.#{_t}").hide())
                        , 2000
        
        #Image credits
        $(document).bindNew 'click', '.credits-link', ->
            if $('.picture-credits').hasClass 'hidden'
                $('.picture-credits').removeClass 'hidden'
                $('.credits-link').html 'Remove image credits'
            else
                $('.picture-credits').addClass 'hidden'
                $('.image-credits-name').val ''
                $('.image-credits-website').val ''
                $('.credits-link').html 'Add image credits'
            
          
        #Select attachment      
        $(document).bindNew 'click', '.attachment-type li', ->
            if not $(@).hasClass 'disabled'                
                $('.attachment-type li').removeClass 'selected'
                $(this).addClass 'selected'
                self.updateForm()
            false
               

        #Upload when file is selected
        $(document).bindNew 'change', '.file-input', @onFileSelect
        
        #Change image src, when url changes
        $(document).bindNew 'paste', '.image-url', =>
            @onImageUrlChange()
        $(document).bindNew 'blur', '.image-url', =>
            @onImageUrlChange()
                    
        #Upload/link
        $(document).bindNew 'click', '.show-upload-box', =>
            $('.image-url').val('')
            $('.with-url').hide()
            $('.with-upload').show()            
            false
            
        $(document).bindNew 'click', '.show-image-url', =>
            $('.image-url').val('')
            $('.with-upload').hide()            
            $('.with-url').show()
            false            
        
        #Change Picture
        $(document).bindNew 'click', 'a.change-picture', @onResetPicture
        
        #Image filters
        $(document).bindNew 'click', 'a.image-effect', ->                        
            self.applyImageFilter @

        #Publish      
        $(document).bindNew 'click', 'button.create', () =>
            @createPost()
            

    
    onResetPicture: =>
        $('.create-post-section .background').hide()
        $('.new-post-view .image-url').val ''
        $('.new-post-view .file-input').replaceWith '<input type="file" class="file-input" name="file" />'
        $('.new-post-view .file-input').bindNew 'change', @onFileSelect #Rebind the event handler, since this is a new element.
        $('.new-post-view .upload-box').show()
        false            

            

    onImageUrlChange: =>
        $('.picture-section .message').hide()
        url = $('.image-url').val().trim()
        if url isnt ''
            ext = url.split('/').pop().split('.').pop().toLowerCase()
            if ext is 'png' or ext is 'jpg' or ext is 'jpeg' or ext is 'gif' or ext is 'bmp'  
                #Upload box..              
                $('.upload-box').hide()

                #Hide picture options until picture is loaded.
                $('.create-post-section .background .picture-options').hide()        
                
                $('.create-post-section .background').show()
                #show a loading picture until conversion is complete.
                $('.create-post-section .background .pic-container').html '
                    <img src="/images/loading.gif" class="loading" alt="loading" /> 
                    <span class="text">Loading...</span> 
                    <a class="text cancel" href="#">cancel</a>'
                
                $(document).bindNew 'click', '.create-post-section .background .cancel', =>
                    $('.create-post-section .background .pic-container').html ''
                    @onResetPicture()

                #Get the image source...                
                $.ajax {
                    url: Poe3.apiUrl("files/processurl"),
                    data: { url },
                    type: 'GET',
                    success: (resp) =>
                        #Check if the loading icon is still there.
                        #If the user cancelled, we would have taken it off. If so, do nothing.
                        if $('.create-post-section .background img.loading').length
                            @setPicture resp.attachment, resp.attachmentThumbnail
                }                                
            else                
                msg = "Url should end with .jpg, .jpeg or .png. Alternatively, you could upload it."
                $('.picture-section .message').html "<i class=\"icon-remove-sign\"></i>#{msg}"
                $('.picture-section .message').show()

            
    
    setPicture: (url, thumbnailUrl, options = { clearFilterSelection: true }) =>
        $('.create-post-section .background').show()
        $('.create-post-section .background .picture-options').show()
        $('.create-post-section .background .pic-container').html "<img src=\"#{url}\" data-filter=\"none\" data-src=\"#{url}\" data-thumbnail-src=\"#{thumbnailUrl}\" class=\"picture\" />"
        if options.clearFilterSelection
            $('a.image-effect').removeClass 'selected'
            $('a.image-effect').first().addClass 'selected'        
            
    
    
    applyImageFilter: (elem) =>
        elem = $(elem)
        $('a.image-effect').removeClass 'selected'
        elem.addClass 'selected'

        attachment = $('.new-post-view .picture-section .background img.picture').data('src')
        attachmentThumbnail = $('.new-post-view .picture-section .background img.picture').data('thumbnail-src')
        pic = $('.new-post-view .picture-section .background img.picture')
        
        fnApply = =>
            pic.data('filter', filter)          
            $('.new-post-view .picture-section .background .effects .text').html if filter is 'none' then 'faithful' else filter
            switch filter
                when 'none'                
                    @setPicture attachment, attachmentThumbnail
                when 'vintage'                
                    pic.vintage { preset: 'default' }
                when 'grayscale'
                    pic.vintage { preset: 'grayscale' }
                when 'sepia'
                    pic.vintage { preset: 'sepia' }
        
        
        filter = elem.data 'filter'        
        currentFilter = pic.data 'filter'
        #if currentFilter and filter isn't none, reset the image.
        #If filter is none, this is going to get reset anyway.
        if filter isnt 'none' and currentFilter isnt 'none'
            @setPicture attachment, attachmentThumbnail, { clearFilterSelection: false }
            pic = $('.new-post-view .picture-section .background img.picture')
            setTimeout fnApply, 200
        else
            fnApply()
        false
        

            
    onFileSelect: =>
        form = $('.upload-form')
        form.attr 'action', Poe3.apiUrl("files", { passkey: app.passkey })
        frame = $('#upload-frame')
        frame.bindNew 'load', () =>
            attachment = JSON.parse($(frame[0].contentWindow.document).text()).attachment
            attachmentThumbnail = JSON.parse($(frame[0].contentWindow.document).text()).attachmentThumbnail
            $('.upload-box').hide()
            @setPicture attachment, attachmentThumbnail
        form.submit()



    getAuthoringMode: =>
        $('.authoring-mode li.selected').data('value')

    getPostType: =>
        $('.post-type li.selected').data('value')

    getAttachmentType: =>
        $('.attachment-type li.selected').data('value')


    
    updateForm: =>
        mode = @getAuthoringMode()
        postType = @getPostType()
        attachmentType = @getAttachmentType()

        #Quote is not available in collaborative mode.
        #1. So we have to reset it to haiku, if this combo is selected. Not so great, I know.
        if mode is 'collaborative' and postType is 'quote'
            $('.post-type li').removeClass 'selected'
            $('.post-type li[data-value="haiku"]').addClass 'selected'
            return @updateForm()
        #2. If collaborative, disable the quote option.
        $('.radio li[data-value="quote"]')[if mode is 'collaborative' then 'addClass' else 'removeClass'] 'disabled'

        if attachmentType is 'image'
            $('.picture-section').show()    
        else
            $('.picture-section').hide()
            
        @setCreatePostHeading()
        
        $('.post-type-form').hide()        
        $(".#{postType}-form .#{mode}").show()
        $(".#{postType}-form .#{@otherMode mode}").hide()        
        $(".#{postType}-form").show()        
        
        #Copy content if any.
        if @currentContent?.val()
            $(".#{postType}-form .#{mode} .content").val @currentContent.val()
        
        #Assign new current Content
        @currentContent = $(".#{postType}-form .#{mode} .content")
        
        $('button.create').html '<i class="icon-ok"></i>' + if mode is 'solo' then 'Publish' else 'Create'
        


    otherMode: (mode) =>
        if mode is 'solo' then 'collaborative' else 'solo'
        
    
    
    setCreatePostHeading: =>
        attachmentType = @getAttachmentType()
        postType = @getPostType()        
        hasPic = attachmentType is 'image'
        $('.create-post-section h2').html switch postType
            when 'haiku'
                 if hasPic then 'Upload a Picture and Write some Haiku' else 'Write some Haiku'    
            when 'free-verse'
                if hasPic then 'Upload a Picture and Write Free-Style Poetry' else 'Write Free-Style Poetry'    
            when 'six-word-story'
                if hasPic then 'Upload a Picture and Write a Six-Word Story' else 'Write a Six-Word Story'
            when 'quote'
                if hasPic then 'Upload a Picture and Write a Quote' else 'Write a Quote'



    validateContent: (text) =>
        mode = @getAuthoringMode()
        postType = @getPostType()
        
        text = @sanitize text     
        
        if not text           
            @showContentError "You haven't written anything."
            return false
        if mode is 'collaborative'
            if postType is 'haiku' and @countLines(text) >= 3
                @showContentError 'In a collaborative Haiku, you cannot write more than two lines.'
                return false
            else if postType is 'six-word-story' and @countWords(text) >= 6
                @showContentError 'In a collaborative Six Word Story, you cannot write more than five words.'
                return false
        else
            if postType is 'haiku' and @countLines(text) isnt 3
                @showContentError 'There should be three lines in a Haiku.'
                return false
            else if postType is 'six-word-story' and @countWords(text) isnt 6
                @showContentError 'There should be six words in a Six Word Story.'
                return false
        
        @hideContentError()
        return true        


            
    showContentError: (error) =>
        $('.content-error').html '<i class="icon-remove-sign"></i> ' + error
        $('.content-error').show()

        

    hideContentError: () =>
        $('.content-error').hide()



    createPost: =>
        if not @saving
            postType = @getPostType()
            content = @currentContent.val()

            if @validateContent content

                params = { 
                    type: postType,
                    tags: $('input.tags').val(),
                    attachmentType: @getAttachmentType(),
                    content: content,
                    authoringMode: @getAuthoringMode()
                }
                
                if postType is 'free-verse' and $(".free-verse-form .title").val()
                    params.title = $(".free-verse-form .title").val()
                
                imgElem = $('.create-post-section .background img.picture')
                imageSrc = imgElem.attr('src')           
                if params.attachmentType and imageSrc                
                    params.attachment = imageSrc
                    params.attachmentSourceFormat = if imgElem.data('filter') is 'none' then 'url' else 'binary'                                    
                    params.attachmentThumbnail = if imgElem.data('filter') is 'none' then imgElem.data('thumbnail-src')
                    if $('.image-credits-name').val()
                        params.attachmentCreditsName = $('.image-credits-name').val()
                        if $('.image-credits-website').val()
                            params.attachmentCreditsWebsite = $('.image-credits-website').val()
                else
                    params.attachmentType = ''

                @saving = true
                post = new Poe3.Post params
                post.save {}, {
                    success: (model, resp) =>
                        new Poe3.PostView resp.uid, { returnUrl: "/#{app.getUser().domain}/#{app.getUser().username}" }
                        app.navigate "/#{resp.uid}", false
                }
            
window.Poe3.NewPostView = NewPostView
