class FacebookSharePostView extends Poe3.ModalView

    constructor: (@message, @picture, @postid, @onSuccessCb)->
        super()
        @render()
        @modalConfig.urlLess = true


    render: =>  
        @setTitle 'Share on Facebook'
        @createModalContainer "facebook-share-post-view"

        numLines = @message.split('\n').length
        picHtml = if @picture then "<p><img src=\"#{@picture}\" /></p>" else ''
            
            
        $('.facebook-share-post-view').html "
            <div class=\"main-section\">
                <h3>Share on Facebook:</h3>
                <textarea>#{@message}</textarea>
                #{picHtml}
                <p>
                    <button class=\"share\"><i class=\"icon-share\"></i>Share on FB</button> or <a class=\"cancel\" href=\"#\">cancel</a>
                </p>
            </div>"
        
        $('.facebook-share-post-view textarea').css 'height', "#{numLines * 18}px"
                    
        @attachEvents()
        @displayModal()
        
        
        
    attachEvents: =>
        $(document).bindNew 'click', '.facebook-share-post-view button.share', =>
            $.ajax {            
                url: Poe3.apiUrl("posts/#{@postid}/fb/shares"),
                data: { message: $('.facebook-share-post-view textarea').val() },
                type: 'post',
                success: (resp) =>                    
                    #TODO: check if it succeeded.
                    $('.social-share .facebook').html '<i class="icon-ok"></i> Shared on Facebook.'
                    @closeModal()
            }
            false
        
        $(document).bindNew 'click', '.facebook-share-post-view a.cancel', =>
            @closeModal()
            false
            
    
window.Poe3.FacebookSharePostView = FacebookSharePostView
