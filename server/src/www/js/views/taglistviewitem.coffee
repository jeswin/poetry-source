class TagListViewItem extends Poe3.BaseView

    constructor: (@model, @containerPrefix, @fnAppend, @fnOnAsyncWidgetLoad, @fnOnSyncWidgetLoad, @getCoverPost) ->
        super()
        @render()



    render: =>
        @mainPost = @getCoverPost @model.posts

        @model.content = @mainPost.formatAsIcon()
        @model.stacktype = ['stacktwo', 'stackthree', 'stackfour'][parseInt Math.random() * 3]        
        @model.containerPrefix = @containerPrefix
        
        html = @template @model      
        @fnAppend html        
          
        if @mainPost.get('attachmentType') is 'image'
            $("##{@containerPrefix}-posts-by-tag-#{@model.tag}").imagesLoaded =>
                @fnOnAsyncWidgetLoad @model
        else
            @fnOnSyncWidgetLoad @model
        
        @attachEvents()
        @onRenderComplete "##{@containerPrefix}-posts-by-tag-#{@model.tag}"
        
        
    
    attachEvents: =>
        $(document).bindNew "click", "##{@containerPrefix}-posts-by-tag-#{@model.tag}", =>
            app.navigate "/#{@mainPost.get('createdBy').domain}/#{@mainPost.get('createdBy').username}/tagged/#{@model.tag}", false                     
            new Poe3.PostView { mode: 'gallery', data: { posts: @model.posts } }


window.Poe3.TagListViewItem = TagListViewItem
