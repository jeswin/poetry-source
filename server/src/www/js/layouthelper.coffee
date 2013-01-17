
class LayoutHelper
    
    constructor: (@widgetContents, @style, @viewportElement, @widgetContainer, @widgetSelector, @isLoadedAsync, @itemTemplate, @onLayoutChange) ->
        @layout = new Poe3.Layout $(@viewportElement), @style ? {}
        
        
    doLayout: =>
        #There are two types of widgetContents.
        # Sync ContentItem - eg: Simple text poem. There is no additional content to be loaded.
        # Async ContentItem - eg: Poem with an image. Image has to be loaded seperately. This widgetContent can be laid out only once the image loads.
        
        #ContentItem types and layouts.
        # - We need to mix/intersperse the async and sync widgetContents, so that it looks better.
        # - We can't do this in the natural order of the widgetContents array, since all the sync widgetContents will come first then.               
        # - Note that sync widgets will always appear is natural order. And async widgets will be displayed on first loaded basis. 
        
        #First sequence the posts randomly.
        sequence = []
                
        for i in [0...@widgetContents.length]
            sequence.push { order: Math.random(), index: i }
        
        comparer = (a, b) ->
            if a.order < b.order then -1 else if a.order > b.order then 1 else 0
        sequence.sort comparer

        syncWidgetInserts = (i for x, i in sequence when not @isLoadedAsync(@widgetContents[x.index]))       
        
        #Pull out a list of sync items, with their random position 
        syncWidgetSequence = []
        for widgetContent in @widgetContents
            if not @isLoadedAsync(widgetContent)
                syncWidgetSequence.push { insertAt: syncWidgetInserts.shift(), widgetContent }
            else
                hasAsyncWidgets = true        

        fnAppend = (html) => $(@widgetContainer).append html

        laidOutItems = 0

        #ContentItems with an image are loaded async. This gets called only when the image is fully loaded.
        fnOnAsyncWidgetLoad = (widgetContent) =>
            @layout.layoutElement $(@widgetSelector widgetContent)
            @onLayoutChange?()
            laidOutItems++

            #Check if there is anything waiting in syncWidgets
            showSyncWidgets()    

        syncWidgets = []
        
        #Pure text widgetContents are loaded sync. This gets called immediately.
        fnOnSyncWidgetLoad = (widgetContent) =>
            #Find the insertion point for this sync item.
            seq = (x for x in syncWidgetSequence when x.widgetContent is widgetContent)[0]
            syncWidgets.push { widget: $(@widgetSelector widgetContent), insertAt: seq.insertAt }


        showSyncWidgets = =>
            matching = (w for w in syncWidgets when w.insertAt <= laidOutItems)            
            if matching.length
                syncWidgets = (w for w in syncWidgets when w.insertAt > laidOutItems)
                item = matching[0]
                while item?.insertAt <= laidOutItems
                    matching.shift()
                    @layout.layoutElement item.widget
                    laidOutItems++
                    @onLayoutChange?()
                    item = matching[0]
                showSyncWidgets()
                    
                            
        #bump async count every once in a way, since some async might never load.
        bump = (showall = false) =>
            if showall
                laidOutItems = 100000 #bignum
            else
                laidOutItems++
            showSyncWidgets()
            if syncWidgets.length
                setTimeout bump, if hasAsyncWidgets then 500 else 0
                    
        for widgetContent in @widgetContents
            @itemTemplate widgetContent, fnAppend, fnOnAsyncWidgetLoad, fnOnSyncWidgetLoad

        setTimeout bump, if hasAsyncWidgets then 500 else 0
        
        #Show everything after 7 seconds.
        setTimeout (=> bump(true)), 7000


window.Poe3.LayoutHelper = LayoutHelper
