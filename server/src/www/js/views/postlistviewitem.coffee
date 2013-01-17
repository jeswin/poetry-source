class PostListViewItem extends Poe3.BaseView

    constructor: (@model, @containerPrefix, @tagPrefix, @fnAppend, @fnOnAsyncWidgetLoad, @fnOnSyncWidgetLoad) ->
        super()
        @render()



    render: =>
        authors = {}        
        for part in @model.get('selectedParts')
            authors[part.createdBy.id] = part.createdBy

        @model.set 'cols', 1 #if (Math.random() * 10 > 6 and @model.get('attachmentType') is 'image') then 2 else 1
        
        params = { post: @model.toTemplateParam(), @containerPrefix, @tagPrefix }
        params.authors = for k,v of authors 
            v
        params.formattedParts = @model.format('condensed')
        
        if @model.get('attachmentType') is 'image'
            params.displayClass = 'with-image'
            params.attachmentIsImage = true
        else
            params.displayClass = 'just-text'             
        
        html = @template params
        
        @fnAppend html
                
        $(document).bindNew 'click', "##{@containerPrefix}-postid-#{@model.id}", =>
            uid = @model.get('uid')
            new Poe3.PostView uid, { tagPrefix: @tagPrefix }
            app.navigate "/#{uid}", { trigger: false }
            false

        for author in params.authors
            do (author) =>
                $(document).bindNew 'click', "##{@containerPrefix}-postid-#{@model.id}-author-#{author.id}", =>
                    app.navigate "/#{author.domain}/#{author.username}", { trigger: true }
                    false

        if @model.get('attachmentType') == 'image'
            $("##{@containerPrefix}-postid-#{@model.id} .background").imagesLoaded =>
                @fnOnAsyncWidgetLoad @model
        else
            @fnOnSyncWidgetLoad @model
            
        @onRenderComplete "##{@containerPrefix}-postid-#{@model.id}"
            

           
window.Poe3.PostListViewItem = PostListViewItem
