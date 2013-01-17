class PostView extends Poe3.ModalView

    constructor: (params, options) ->
        
        @tagPrefix = options?.tagPrefix ? '/posts'

        if typeof params is 'string' or typeof params is 'number'
            @uid = params
            if app.activeView?.getPostByUID? and (post = app.activeView.getPostByUID parseInt @uid)
                super { model: post }
                @model.bind 'change', @render, @
                @render()
            else
                super { model: new Poe3.Post { uid: @uid } }
                @model.bind 'change', @render, @
                @model.fetch()

        else #This is a gallery.
            @gallery = params.data
            post = @gallery.posts[0]            
            super { model: post }
            @model.bind 'change', @render, @
            @render()

        if options?.returnUrl
            @modalConfig.returnUrl = options.returnUrl
    
                
    render: =>
        @setTitle @model.getPostName(50)
    
        post = @model.toTemplateParam()
        
        @createModalContainer "post-view-container"

        authors = {}        
        for part in post.selectedParts
            authors[part.createdBy.id] = part.createdBy

        params = {}
        params.post = post
        params.authors = for k,v of authors 
            v
            
        params.formattedParts = @model.format()        
        params.partEditor = @model.getPartEditor()
        postedAt = @model.get('publishedAt') ? @model.get('timestamp')
        params.postedAt = moment(new Date(postedAt)).fromNow()
        params.notes = @model.formatNotes()
        params.hasLikes = @model.get('likes').length > 0
        params.tagPrefix = @tagPrefix
        params.isComplete = post.state is 'complete'
        
        if @model.get('attachmentType') is 'image'
            params.displayClass = 'with-image'
            params.attachmentIsImage = true
            if @model.get('attachmentCreditsName')
                if @model.get('attachmentCreditsWebsite')
                    params.attachmentCredits = "<p class=\"attachment-credits\"><i class=\"icon-picture\"></i> <a href=\"#{@model.get('attachmentCreditsWebsite')}\">#{@model.get('attachmentCreditsName')}</a></p>"
                else
                    params.attachmentCredits = "<p class=\"attachment-credits\"><i class=\"icon-picture\"></i> #{@model.get('attachmentCreditsName')}</p>"
        else
            params.displayClass = 'just-text'        
        
        if @gallery
            params.isGallery = true
        
        $(@el).html @template params
        $('.post-view-container').html @el
        
        $('.social-share .social-action').html if @model.get('state') is 'complete' then 'Share on' else 'Invite contributors' 
        #If there are no images, we don't need to show pinterest
        if @model.get('attachmentType') is 'image'
            $('.social-share .pinterest').show()
        else
            $('.social-share .pinterest').hide()
            
        @addComments()                
        @addCompletionMessage()    
        @addLikeButton()     
        @addSettingsButton()
        
        if @gallery     
            @addGalleryNavigation()
            
        @attachEvents()
        
        onModalReady = =>
            modalSize = @getModalSize()
            
            fontSize = @model.getFontSize(modalSize)
            $('.post-view-container .parts').css 'font-size', "#{fontSize}px"
            
            lineHeight = if fontSize <= 18 then "1.3" else "1.2"
            $('.post-view-container .parts').css 'line-height', "#{lineHeight}"
            
            @setupModal modalSize
            $('.post-view .notes, .post-view .post-details').show()
            $('.post-view .notes, .post-view .social-share').show()
            $('.post-view .notes, .post-view .comments-container').show()
            
        if @model.get('attachmentType') is 'image'
            $('.post-view .post-box .background').imagesLoaded onModalReady
        else
            onModalReady()
       
        @onRenderComplete '.post-view-container'



    addComments: =>
        comments = new Poe3.Comments
        comments.bind 'reset', @displayComments, @
        comments.postid = @model.id
        comments.fetch()
        

    displayComments: (commentsModel) =>
        $('.post-view .comments-container').html @commentsTemplate { comments: commentsModel.toJSON() }
            
    

    addCompletionMessage: =>
        completionMessage = @model.getCompletionMessage()
        if completionMessage
            @showMessage completionMessage.text, completionMessage.type        
        

    
    addLikeButton: =>
        likeButton = $('.post-view .post-buttons i.like-button')
        likeButton.removeClass 'icon-heart'
        likeButton.removeClass 'icon-heart-empty'
        yourLikes = (like for like in @model.get('likes') when like.id is app.getUser().id)
        if yourLikes.length
            likeButton.addClass 'icon-heart'
        else
            likeButton.addClass 'icon-heart-empty'
        

    
    addSettingsButton: =>
        if @model.get('createdBy').id is app.getUser().id
            $('.post-view .post-buttons .settings-button').show()
        

    
    addGalleryNavigation: =>
        self = @
    
        if not @galleryCursor
            @galleryCursor = 0
            
        $(document).bindNew 'click', '.gallery-nav .left-cursor', @galleryPrevious        
        $(document).bindNew 'click', '.gallery-nav .right-cursor', @galleryNext   
        $(document).bind 'keyup', 'left', @galleryPrevious
        $(document).bind 'keyup', 'right', @galleryNext        
                 
        $('.post-view .gallery').html '
            <div class="container">
                <ul></ul>
            </div>
            <div class="overlay"></div>'
        list = $('.post-view .gallery').find 'ul'
        
        i = 0
        while i < @gallery.posts.length 
            post = @gallery.posts[i]
            li = $('<li></li>')
            li.html post.formatAsIcon()
            li.data('post', post)
            li.data('cursor', i)
            li.appendTo list
            li.click ->                
                self.model = $(@).data('post')
                self.galleryCursor = $(@).data('cursor')
                self.render()
            if @galleryCursor is i
                li.addClass 'selected'                
            i++
       
                
    
    galleryPrevious: =>
        if @cancelKeyPress
            return
        @cancelKeyPress = true
        setTimeout (=>
            @cancelKeyPress = false
            if @galleryCursor > 0
                @galleryCursor--
                @model = @gallery.posts[@galleryCursor]
                @render()), 100
        
    galleryNext: =>
        if @cancelKeyPress
            return
        @cancelKeyPress = true
        setTimeout (=>
            @cancelKeyPress = false
            if @galleryCursor < (@gallery.posts.length - 1)
                @galleryCursor++
                @model = @gallery.posts[@galleryCursor]
                @render()), 100        


    attachEvents: =>        
        
        $(document).bindNew 'click', '.post-view .part-select-item', @onSelectPartClick() #returns fn

        $(document).bindNew 'click', '.post-view .parts .remove-part', @onRemovePartClick() #returns fn

        $(document).bindNew 'click', '.post-view button.publish', @onPublishClick

        $(document).bindNew 'click', '.post-view button.submit', @onSubmitPartClick
        
        $(document).bindNew 'click', '.post-view .post-buttons i.like-button', @onLikeClick

        $(document).bindNew 'click', '.post-view .post-buttons i.settings-button', @onSettingsClick
         
        $(document).bindNew 'mouseenter', '.post-view .parts .last span.remove-part', ->
            $(@).parent().addClass 'selected'
            
        $(document).bindNew 'mouseleave', '.post-view .parts .last span.remove-part', ->
            $(@).parent().removeClass 'selected'
        
        $(document).bindNew 'click', '.post-view .authors li', ->
            app.navigate "/#{$(@).data('domain')}/#{$(@).data('username')}", true            

        $(document).bindNew 'click', '.post-view .write-part-link', =>
            $('.part-select-container').hide()
            $('.add-part').show()
            false
            
        $(document).bindNew 'click', '.post-view .select-contrib-link', =>
            $('.add-part').hide()        
            $('.part-select-container').show()
            false
            
        $(document).bindNew 'click', '.post-view .comments a.new-comment', =>
            if app.isAuthenticated()
                $('.post-view .comments .comment-form').show()
                $('.post-view .comments .comment-form textarea').focus()
                $('.post-view .comments .add-comment-link').hide()
                @_hack_overlayHeightRefresh()
            else                    
                loginView = new Poe3.LoginView            
            false

        $(document).bindNew 'click', '.post-view .comments button.save', @onSaveComment            

        $(document).bindNew 'click', '.post-view .social-share .facebook img, .post-view .social-share .facebook a', @onFacebookShare
        $(document).bindNew 'click', '.post-view .social-share .twitter img, .post-view .social-share .twitter a', @onTweet
        $(document).bindNew 'click', '.post-view .social-share .pinterest img, .post-view .social-share .pinterest a', @onPin
        
        
    onFacebookShare: =>            
        if @model.get('state') is 'complete'            
            collaborative = if @model.get('authoringMode') is 'collaborative' then 'collaborative ' else ''
            postUrl = app.pathToUrl(@model.get 'uid')

            if app.isAuthenticated() and app.getUser().domain is 'fb'
                message = "#{postUrl}\n\n#{@model.summarizeContent('full')}"
                picture = if (@model.get 'attachment') then app.pathToUrl(@model.get 'attachment')
                new Poe3.FacebookSharePostView message, picture, @model.id, (-> $('.post-view .social-share .facebook').html '<i class="icon-ok"><i> Shared on Facebook.')                
                false       
            else            
                params = {
                    method: 'feed',
                    name: @model.getPostName(),
                    picture: app.pathToUrl(@model.get 'attachment') ? @model.get('createdBy').picture,
                    link: app.pathToUrl(@model.get 'uid'),
                    description: @model.summarizeContent("short")
                }
                FB.ui params, (resp) =>
                    published = resp and resp.post_id
                    if published
                        $('.post-view .social-share .facebook').html '<i class="icon-ok"></i> Shared on Facebook.'
                false
        else
            postName = @model.getPostName(100).substring(0,50)            
            postName += '...' if not /\.$/.test postName
                
            url = window.location.hostname + "/#{@model.get('uid')}"
            FB.ui {
                    method: 'apprequests',
                    display: "popup",
                    message: "Complete the #{@model.formatType()} (#{postName}) at #{url}",
                    data: "redirect_to_post:#{@model.get('uid')}"
                }, (resp) =>
                        if resp
                            $.ajax {
                                url: Poe3.apiUrl("tokens"),
                                data: { type: 'facebook-app-request', key: resp.request, value: @model.get('uid') },
                                type: 'post',
                                success: (token) =>
                            }
            false
        
        
        
    onTweet: (e) =>    
        text = @model.summarizeContent('full')#.replace('\n', ' ')
        if text.length > 92
            text = text.slice(0, 92) + '...'
        text = encodeURIComponent(text) + '\n  '
        text += window.location.hostname + "/#{@model.get('uid')}"
        hashtag = switch @model.get('type')
            when 'haiku'
                'haiku'
            when 'quote'
                'quote'
            when 'free-verse'
                'poetry'
            when 'six-word-story'
                'sixwordstory'
        newwindow = window.open "https://twitter.com/share?url=''&text=#{text}&hashtags=#{hashtag}", 'name', 'height=250,width=400'
        if window.focus
            newwindow.focus()        
        false
        

    
    onPin: (e) =>
        url = "url=" + encodeURIComponent(window.location.href)
        if @model.get('attachmentType') is 'image' 
            img = @model.get('attachment')
            if /^\//.test img
                img = "http://#{window.location.hostname}#{img}"
            media = "&media=#{encodeURIComponent(img)}" 
        else
            media = ""
        summary = @model.summarizeContent('full')
        if summary.length > 200
            summary = summary.slice(0, 200) + "..."
        summary += "\n" + window.location.href
        description = "&description=#{encodeURIComponent summary}"
        loc = "http://pinterest.com/pin/create/button/?#{url}#{media}#{description}"        
        window.open(loc, 'pinterest_popup', 'width=580,height=280')
        false
        
        
        
    onSaveComment: =>
        $.ajax {
            url: Poe3.apiUrl("posts/#{@model.id}/comments"),
            data: { content: $('.post-view .comments textarea').val() },
            type: 'post',
            success: (comment) =>
                @addComments()
        }
            
        false
        

    onPublishClick: =>
        $.ajax {
            url: Poe3.apiUrl("posts/#{@model.id}/state"),
            data: { value: 'complete' },
            type: 'PUT',
            success: (post) =>
                @updateParentPost new Poe3.Post post
                @model.set post
                @showMessage '<p class="text"><i class="icon-ok"></i> Congratulations. You have published it.</p>', 'success'
        }
    

    onSubmitPartClick: =>
        content = $('.post-view textarea.content').val()
        validation = @model.validateNewPart content
        if validation.isValid
            @hideContentError()
            $.post Poe3.apiUrl("posts/#{@model.id}/parts"), { content }, (post) =>                
                @updateParentPost new Poe3.Post post
                @model.set post
        else
            @showContentError validation.error
            

    onRemovePartClick: =>
        self = @
        ->
            $.ajax {
                url: Poe3.apiUrl("posts/#{self.model.id}/selectedparts/#{$(@).data('partid')}"),
                type: 'DELETE',
                success: (post) =>
                    self.updateParentPost new Poe3.Post post
                    self.model.set post
            }                  
            

    onSelectPartClick: =>
        self = @
        ->
            $.post (Poe3.apiUrl "posts/#{self.model.id}/selectedparts"), { id: $(@).data('partid') }, (post) =>
                self.updateParentPost new Poe3.Post post
                self.model.set post
    
            
    onLikeClick: =>
        if app.isAuthenticated()        
            likeButton = $('.post-view .post-buttons i.like-button')
            if likeButton.hasClass 'icon-heart'
                $.ajax {
                    url: Poe3.apiUrl "posts/#{@model.id}/like"
                    type: 'DELETE',
                    success: (post) =>
                        likeButton.removeClass 'icon-heart'
                        likeButton.removeClass 'icon-heart-empty'
                        likeButton.addClass 'icon-heart-empty'
                        _post = new Poe3.Post post
                        @updateParentPost _post
                }
            else
                $.ajax {
                    url: Poe3.apiUrl "posts/#{@model.id}/like"
                    type: 'PUT',
                    success: (post) =>
                        likeButton.removeClass 'icon-heart'
                        likeButton.removeClass 'icon-heart-empty'
                        likeButton.addClass 'icon-heart'
                        _post = new Poe3.Post post
                        @updateParentPost _post
                }
        else                    
            loginView = new Poe3.LoginView
    


    onSettingsClick: =>
        formContent = ''

        formContent += '
            <p>
                Tags: <br />
                <input type="text" placeholder="eg: nature,rains" class="tags" value="' + @model.get('tags').join(',') + '" />
            </p>
            <p>
                Notes: <br />
                <textarea class="notes">' + (@model.get('notes') ? '') + '</textarea>                        
            </p>'
            
        imageUrl = @model.get('attachment') ? ''
        formContent += '
            <p class="show-image-edit-form">
                Do you want to <a href="#">change the image</a>?
            </p>
            <div class="image-edit-form hidden">
                <p>
                    Image (optional): <br />
                    <input type="text" class="image-url" value="' + imageUrl + '" />
                </p>
                <p>
                    Image Credits (optional):<br />
                    <input type="text" class="credits-name" placeholder="eg: John Doe" value="' + (@model.get('attachmentCreditsName') ? '') + '" /> 
                    <input type="text" class="credits-website" placeholder="eg: http://www.website.com" value="' + (@model.get('attachmentCreditsWebsite') ? '') + '" />
                </p>
            </div>'

        form = '
            <form class="post-settings">' + 
                formContent + '
                <p>
                    <button class="save"><i class="icon-ok"></i>Save</button> or <a class="cancel" href="#">cancel</a>
                </p>
            </form>'

        if @model.get('state') is 'complete'
            deleteOrUnpublish = '
                <div class="delete-unpublish">
                    <p>
                        Do you want to <a class="unpublish-post" href="#">unpublish</a> or <a class="delete-post" href="#">delete</a> this post?
                    </p>
                    <p class="unpublish-post-option" style="display:none">
                        <button class="unpublish-post"><i class="icon-ban-circle"></i>Unpublish</button>
                    </p>                        
                    <p class="delete-post-option" style="display:none">
                        <button class="delete-post"><i class="icon-remove"></i>Delete forever</button>
                    </p>
                </div>'
        else
            deleteOrUnpublish = '
                <div class="delete-unpublish">
                    <p>
                        Do you want to <a class="delete-post" href="#">delete</a> this post?
                    </p>
                    <p class="delete-post-option" style="display:none">
                        <button class="delete-post"><i class="icon-remove"></i>Delete forever</button>
                    </p>
                </div>'
                
        @displayModalModal $('.post-view .post-box'), form + deleteOrUnpublish

        $settings = $('.post-view .modal-modal .post-settings')
        
        $(document).bindNew 'click', '.post-view .modal-modal .post-settings .show-image-edit-form a', =>            
            $settings.find('.show-image-edit-form').hide()
            $settings.find('.image-edit-form').show()                
            
        $(document).bindNew 'click', '.post-settings button.save', =>
            data = { 
                tags: $settings.find('input.tags').val(),
                notes: $settings.find('textarea.notes').val()
            }
            
            #Image.
            attachmentUrl = $settings.find('input.image-url').val()
            if attachmentUrl
                ext = attachmentUrl.split('/').pop().split('.').pop().toLowerCase()
                if ext is 'png' or ext is 'jpg' or ext is 'jpeg' or ext is 'gif' or ext is 'bmp'                        
                    data.attachmentType = 'image'
                    data.attachment = attachmentUrl
                    
                    if $settings.find('input.credits-name').val()
                        data.attachmentCreditsName = $settings.find('input.credits-name').val()
                        
                        if $settings.find('input.credits-website').val()
                            data.attachmentCreditsWebsite = $settings.find('input.credits-website').val()
                else
                    alert 'Image url should end with .jpg, .jpeg or .png.'
                    return
            else
                data.attachmentType = ''

            $.ajax {
                url: Poe3.apiUrl("posts/#{@model.id}"),
                data,                        
                type: 'PUT',
                success: (post) =>
                    @closeModalModal()
                    @updateParentPost new Poe3.Post post
                    @model.set post
                    @showMessage '<p class="text"><i class="icon-ok"></i> Saved.</p>', 'success'
            }
            

        $(document).bindNew 'click', '.post-view .modal-modal .post-settings a.cancel', =>
            @closeModalModal()


        $(document).bindNew 'click', '.post-view .modal-modal .delete-unpublish button.delete-post', =>
            $.ajax {
                url: Poe3.apiUrl("posts/#{@model.id}"),
                type: 'DELETE',
                success: =>
                    @closeModalModal()
                    @deleteParentPost @model
                    @showMessage '<p class="text"><i class="icon-ok"></i> Deleted. You will never see it again.</p>', 'alert'
            }                


        $(document).bindNew 'click', '.post-view .modal-modal .delete-unpublish button.unpublish-post', =>
            $.ajax {
                url: Poe3.apiUrl("posts/#{@model.id}/state"),
                data: { value: 'open' },
                type: 'PUT',
                success: (post) =>
                    @closeModalModal()
                    @updateParentPost new Poe3.Post post
                    @model.set post
                    @showMessage '<p class="text"><i class="icon-ok"></i> You have unpublished it.</p>', 'alert'
            }

        $(document).bindNew 'click', '.post-view .post-box .unpublish-post', =>
            $('.post-view .post-box .delete-post-option').hide()
            $('.post-view .post-box .unpublish-post-option').show()
            false


        $(document).bindNew 'click', '.post-view .post-box .delete-post', =>
            $('.post-view .post-box .unpublish-post-option').hide()
            $('.post-view .post-box .delete-post-option').show()
            false


    
    #Errors
    showContentError: (error) =>
        $('.content-error').html '<i class="icon-remove-sign"></i> ' + error
        $('.content-error').show()
        

    hideContentError: () =>
        $('.content-error').hide()


            
    updateParentPost: (post) =>
        app.activeView?.updatePost? post
        
        #replace the corresponding post in gallery, if there is a gallery.
        if @gallery?.posts.length
            index = (index for p, index in @gallery.posts when p.id is post.id)[0]
            @gallery.posts.splice index, 1, post
        
        

    deleteParentPost: (post) =>
        app.activeView?.deletePost? post



    setupModal: (size) =>
        $('.post-view .post-frame').css 'width', "#{size}px"
        $('.post-view .post-box').css 'width', "#{size}px"
        $('.post-view .post-box').show()        
        $('.post-view .post-details').css 'width', "#{size-16}px" #-16 since the details element has 16 pixels of padding
        $('.post-view .post-details').show()            
        $('.post-view .gallery').show()                         
        $('.post-view .gallery-nav').show()
        @displayModal()
        
        
    
    getModalSize: =>
        minWidth = 480
        maxWidth = if @gallery then 800 else 920

        if @model.get('attachmentType') is 'image' 
            height = $('.post-view .post-box').height()
            #width = $('.post-view .post-box').width()
            width = $('.post-view .post-box .background img')[0].naturalWidth
            windowHeight = $(window).height() - 160
            scaledWidth = parseInt width * (windowHeight/height)        

            if width < scaledWidth # Scaled width cannot be larger than actual width
                scaledWidth = width
            if scaledWidth > maxWidth
                scaledWidth = maxWidth
            if scaledWidth < minWidth 
                scaledWidth = minWidth

            scaledWidth
        else
            520


window.Poe3.PostView = PostView
