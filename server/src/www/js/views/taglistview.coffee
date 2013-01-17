class TagListView extends Poe3.BaseView
    
    constructor: (@renderTo, @posts) ->
        super { model: @posts }      
    
    
    
    initialize: =>
        @containerPrefix = "e_#{Poe3.uniqueId()}"
        $(@renderTo).html @el            
    
    
    
    render: =>        
        $(@el).html @template { }

        #Arrange posts by tag
        tagDict = {}
        for post in @posts
            if post.get('tags')?.length
                for tag in post.get('tags')
                    if not tagDict[tag]    
                        tagDict[tag] = []
                    tagDict[tag].push post
        
        postsList = []
        for tag, posts of tagDict
            postsList.push { tag, posts, count: posts.length }

        #Get the cover post, to show with the tag. Like a cover photo.     
        #We try to show a unique post for each tag. But only of possible.       
        coverPosts = []

        isInCoverPosts = (p) =>
            (_p for _p in coverPosts when _p is p).length > 0

        getCoverPost = (posts) =>
            notCovered = (p for p in posts when not isInCoverPosts p)
            cover = if notCovered.length
                        (post for post in notCovered when post.get('attachmentType') is 'image')[0] ? notCovered[0]
                    else
                        posts[0]
            coverPosts.push cover
            cover            
        
        style = @defaultLayoutStyle()
        style.marginLeft = 0
        style.marginRight = 90
        style.colWidth = 228
        layoutHelper = new Poe3.LayoutHelper postsList,
            style,
            ".tag-list-view .viewport",
            ".tag-list-view .items",
            (item) => "##{@containerPrefix}-posts-by-tag-#{item.tag}",
            (item) => item.posts[0].isLoadedAsync(),
            ((item, fnAppend, fnOnAsyncWidgetLoad, fnOnSyncWidgetLoad) =>
                new Poe3.TagListViewItem item, @containerPrefix, fnAppend, fnOnAsyncWidgetLoad, fnOnSyncWidgetLoad, getCoverPost),
            (->)
                
        layoutHelper.doLayout()   

                
window.Poe3.TagListView = TagListView
