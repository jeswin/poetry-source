class PostsView extends Poe3.PageView
    
    constructor: (@params = {}) ->
        @params.category ?= 'all'
        
        #posts/haiku, ...
        if ['haiku', 'six-word-story', 'quote', 'free-verse'].indexOf(@params.category) > -1
            @params.type = @params.category
            @params.category = 'all'
            
        #posts/text
        if @params.category is 'text'
            @params.attachmentType = ''
            @params.category = 'all'
        
        #posts/open/haiku, posts/popular/text
        if ['all', 'open', 'popular'].indexOf(@params.category) > -1
            if @params.subCategory
                if ['haiku', 'six-word-story', 'quote', 'free-verse'].indexOf(@params.subCategory) > -1
                    @params.type = @params.subCategory
                if @params.subCategory is 'text'
                    @params.attachmentType = ''        
        
        @tagPrefix = if @params.category is 'open' then "/posts/open" else "/posts"
        @pageNumber = 1
        @pageSize = 50

        super { model: new Poe3.Posts }
        
        
        
    initialize: =>        
        $('#content').html @el
        $(@el).html @template { }
        
        if @params.type
            $('.posts-view .filter .active .prefix').html '<span class="anchor cancel-filter"><i class="icon-circle-arrow-left"></i></span>'
            $('.posts-view .filter .active i.icon-filter').hide()
            $('.posts-view .filter .active a.type').html @params.type
        else if @params.attachmentType?
            $('.posts-view .filter .active .prefix').html '<span class="anchor cancel-filter"><i class="icon-circle-arrow-left"></i></span>'
            $('.posts-view .filter .active i.icon-filter').hide()
            $('.posts-view .filter .active a.type').html 'text'

        @attachEvents()
        @onRenderComplete '#content'        
        @loadCategory()
        


    render: (posts) =>
        switch @params.category
            when 'all'
                @setTitle "All poems"
            when 'open'
                @setTitle "Open poems"
            when 'popular'
                @setTitle "Popular poems"

        posts = posts.toArray()        
        @postListView = new Poe3.PostListView '#content .page-content', @tagPrefix, posts
        @postListView.render()
        


    loadCategory: =>
        $('.posts-view .std-menu ul span.tag').remove()        
        $('.posts-view .std-menu li a').removeClass 'selected'

        if @params.tag
            $(".posts-view .std-menu li span.#{@params.category}").append '<span class="tag selected"> #' + @params.tag + '</span>'

        $(".posts-view .std-menu li span.#{@params.category} a").addClass 'selected'
        
        @fetch {}, {}, (posts) =>
           if posts.length > @pageSize
               @setupPaging()
               @switchPage posts, 1, 'forward'
           else
               @render posts



    setupPaging: =>
        $('.posts-view .paginator').html '
            <ul>
                <li class="prev">
                    <i class="icon-chevron-left"></i>
                    <a href="#">Prev</a>
                </li>
                <li class="page-number">
                    Page 1
                </li>
                <li class="next">
                    <a href="#">Next</a>
                    <i class="icon-chevron-right"></i>
                </li>
            </ul>'
            
        $(document).bindNew 'click', '.posts-view .paginator .prev, .paginator .prev a', =>
            @onPreviousPage()
            
        $(document).bindNew 'click', '.posts-view .paginator .next, .paginator .next a', =>
            @onNextPage()
        
        $('.posts-view .paginator.top').fadeIn 1000
        setTimeout (->
            $(".paginator-border-bottom").css 'border-top', '1px solid #222'
            $('.posts-view .paginator.bottom').fadeIn 1000), 3000
    
    
        
    switchPage: (posts, pageNum, fetchDirection) =>
        @pageNumber = pageNum

        #Is there more to fetch?
        hasMore = posts.length > @pageSize
        if hasMore 
            if fetchDirection is 'forward' or pageNum is 1
                posts.pop() 
            else
                posts.shift()       

        #Unlikely condition, which happens when a lot of entries at the beginning have been removed.
        #If the user pressed prev, and page number > 1 and there are no more records.
        #   eg, we are on page 2 and there aren't any records on page 1.
        if not hasMore and fetchDirection is 'back' and @pageNumber > 1
            @fetch {}, {}, (posts) =>
                @switchPage posts, 1, 'forward'
        else
            @hasNext = fetchDirection is 'back' or (fetchDirection is 'forward' and hasMore)

            $('.posts-view .paginator .page-number').html "Page #{@pageNumber}"
            $('.posts-view .paginator .prev')[if @pageNumber > 1 then 'removeClass' else 'addClass'] 'disabled'
            $('.posts-view .paginator .next')[if @hasNext then 'removeClass' else 'addClass'] 'disabled'
         
            @render posts



    onPreviousPage: =>
        params = {}
        if @pageNumber > 1
            #If the current page number is 2, we are about to fetch the first page.
            if @pageNumber > 2
                if @params.category isnt 'open'
                    params.after = @model.at(0).get('publishedAt')
                params.minuid = @model.at(0).get('uid')
            pageNum = @pageNumber - 1                
            do (pageNum) =>
                @fetch params, {}, (posts) =>
                   @switchPage posts, pageNum, 'back'
        false



    onNextPage: =>
        if @hasNext
            params = {}
            if @params.category isnt 'open'
                params.before = @model.at(@model.length - 1).get('publishedAt')
            params.maxuid = @model.at(@model.length - 1).get('uid')    
            pageNum = @pageNumber + 1
            do (pageNum) =>
                @fetch params, {}, (posts) =>
                   @switchPage posts, pageNum, 'forward'                       
        false



    #apiInfo will indicate if paging has to be done client-side or server side.
    #   Some APIs return all results, and this might need to be paged client side.
    fetch: (data, apiInfo, onLoad) =>   
        data.limit = @pageSize + 1
        data.category = @params.category
                
        if @params.tag
            data.tag = @params.tag
            
        if @params.type
            data.type = @params.type
            
        if @params.attachmentType?
            data.attachmentType = @params.attachmentType 

        @model.fetch { data, success: onLoad }
            


    attachEvents: =>
        self = @
        $(document).bindNew 'click', '.posts-view .filter a.type', =>
            $('.posts-view .filter .active').hide()
            $('.posts-view .filter .select').show()
            false
            
        $(document).bindNew 'click', '.posts-view .filter .select a', ->
            filter = $(@).attr 'class'
            self.applyFilter filter
            false

        $(document).bindNew 'click', '.posts-view .filter .cancel-filter', =>
            @applyFilter 'all'
            false
        
        
    applyFilter: (filter) =>
        if @params.category is 'all'
            if @params.tag
                if filter is 'all'
                    app.navigate "/posts/tagged/#{@params.tag}", true                    
                else
                    app.navigate "/posts/#{filter}/tagged/#{@params.tag}", true
            else
                if filter is 'all'
                    app.navigate "/posts", true
                else                    
                    app.navigate "/posts/#{filter}", true
        else
            if @params.tag
                if filter is 'all'
                    app.navigate "/posts/#{@params.category}/tagged/#{@params.tag}", true
                else
                    app.navigate "/posts/#{@params.category}/#{filter}/tagged/#{@params.tag}", true
            else
                if filter is 'all'
                    app.navigate "/posts/#{@params.category}", true
                else
                    app.navigate "/posts/#{@params.category}/#{filter}", true
        

    resizeOnRefresh: =>
        true

    
    getPostByUID: (uid) =>
        @postListView.getPostByUID uid
       
       
    updatePost: (post) =>
        @postListView.updatePost post        


    
window.Poe3.PostsView = PostsView
