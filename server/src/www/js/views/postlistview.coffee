class PostListView extends Poe3.BaseView
    
    constructor: (@renderTo, @tagPrefix, @posts) ->
        super { model: @model }
    
    
    
    initialize: =>
        @containerPrefix = "e_#{Poe3.uniqueId()}"
        $(@renderTo).html @el            
    
    
    
    render: =>        
        $(@el).html @template { }

        style = @defaultLayoutStyle()
        style.marginLeft = 0
        
        attachContribAlert = (_post, fn) =>
            (html) =>
                fn html
                currentParts = (part for part in _post.get('parts') when part.sequence is _post.get('selectedParts').length) 
                numContribs = currentParts.length
                if numContribs > 0
                    $("#{@containerPrefix}-#postid-#{_post.id}").prepend "
                        <div class=\"contrib-alert\">
                            <span class=\"icon\">
                                <i class=\"icon-file\"></i> #{numContribs} 
                            </span>
                            <span class=\"subtext\">
                                from #{(part.createdBy.name for part in currentParts).join(', ')}
                            </span>
                            <div style=\"clear:both\"></div>
                        </div>"                        
        
        layoutHelper = new Poe3.LayoutHelper @posts,
            style,
            ".post-list-view .viewport",
            ".post-list-view .items",
            (post) => "##{@containerPrefix}-postid-#{post.id}",
            (post) => post.isLoadedAsync(),
            ((post, fnAppend, fnOnAsyncWidgetLoad, fnOnSyncWidgetLoad) =>
                new Poe3.PostListViewItem post, @containerPrefix, @tagPrefix, attachContribAlert(post, fnAppend), fnOnAsyncWidgetLoad, fnOnSyncWidgetLoad),
            (->)

        layoutHelper.doLayout()    
            
                
    
    getPostByUID: (uid) =>
        (post for post in @posts when post.get('uid') == uid)[0]
       
       
       
    updatePost: (post) =>
        @posts = (p for p in @posts when p.get('uid') isnt post.get('uid'))
        @posts.push post            
        
                
window.Poe3.PostListView = PostListView
