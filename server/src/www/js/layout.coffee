class Layout

    constructor: (@container, _style) ->
        @style = $.extend {}, _style
        @fullWidth = @container.width() - (@style.marginLeft + @style.marginRight)
        @maxColumns = Math.floor (@fullWidth + @style.colSpacing)/(@style.colWidth + @style.colSpacing)        
        @occupiedWidth = ((@maxColumns - 1) * (@style.colWidth + @style.colSpacing)) + @style.colWidth
        
        if @style.adjustWidth
            extraPerColumn = (@fullWidth - @occupiedWidth) / @maxColumns
            @style.colWidth += Math.floor ((@style.widthToSpacingRatio/(@style.widthToSpacingRatio + 1)) * extraPerColumn)
            @style.colSpacing += Math.floor ((1/(@style.widthToSpacingRatio + 1)) * extraPerColumn)
        
        @colMargin = Math.floor (@style.colSpacing / 2)
        
        @occupancyIndex = []
        @createLayout()



    createLayout: =>
        @domCols = []
        
        i = 0
        while i < @maxColumns
            if i is 0
                col = $('<div class="layout-column" style="float: left; min-height: 1px; margin-left:' + @style.marginLeft + 'px; margin-right:' + @colMargin + 'px; width:' + @style.colWidth + 'px"></div>')
            else if i is @maxColumns - 1
                col = $('<div class="layout-column" style="float: left; min-height: 1px; margin-left:' + @colMargin + 'px; width:' + @style.colWidth + 'px"></div>')
            else
                col = $('<div class="layout-column" style="float: left; min-height: 1px; margin-left:' + @colMargin + 'px; margin-right:' + @colMargin + 'px; width:' + @style.colWidth + 'px"></div>')
            @domCols.push col
            @container.append col
            i++
        


    getVacancies: (col, height) =>
        colOccupancy = @getOccupancy(col)
        
        possibilities = []
        prevListEnd = 0

        for item in colOccupancy
            hasItems = true
            if (item.begin - prevListEnd) > height
                possibilities.push prevListEnd + 1
            prevListEnd = item.end
        
        possibilities.push if hasItems then prevListEnd + 1 else 0
        
        possibilities


        
    addOccupancy: (col, elemBegin, height, elem) =>
        colOccupancy = @getOccupancy(col)
        
        index = 0
        for item in colOccupancy
            if elemBegin > item.end
                if item.elem
                    prevElem = item
                index++
            else
                if item.elem
                    nextElem = item
                    break #Found what we want.
        
        #Insert the occupancy!        
        occupancy = { begin: elemBegin, end: elemBegin + height }
        colOccupancy.splice index, 0, occupancy

        if elem        
            occupancy.elem = elem
        
            if prevElem
                #if there is a vertical gap between the current occupancy and the previous occupancy, we need to fill it up with a spacer            
                #   Remove existing spacer, if any.
                if prevElem.elem.next().hasClass 'layout-spacer'
                    prevElem.elem.next().remove()
                
                if occupancy.begin - prevElem.end > 1
                    spacer = $("<div class=\"layout-spacer\" style=\"width:#{@style.colWidth}px;height:#{(occupancy.begin - prevElem.end - 1)}px\"></div>")
                    spacer.insertAfter prevElem.elem
                    elem.insertAfter spacer
                else
                    elem.insertAfter prevElem.elem
                
            else
                if @domCols[col].children().first().hasClass 'layout-spacer'
                    @domCols[col].children().first().remove()
                
                if occupancy.begin > 0
                    spacer = $("<div class=\"layout-spacer\" style=\"width:#{@style.colWidth}px;height:#{(occupancy.begin - 1)}px\"></div>")
                    @domCols[col].prepend spacer
                    elem.insertAfter spacer
                else
                    @domCols[col].prepend elem    
            
            if nextElem
                if nextElem.begin - occupancy.end > 1
                    spacer = $("<div class=\"layout-spacer\" style=\"width:#{@style.colWidth}px;height:#{(nextElem.begin - occupancy.end - 1)}px\"></div>")
                    spacer.insertAfter elem
            


    hasVacancy: (col, elemBegin, height) =>
        colOccupancy = @getOccupancy(col)
        
        prevEnd = 0
        for item in colOccupancy        
            if (item.begin >= elemBegin)
                return (item.begin - prevEnd) >= height
            prevEnd = item.end
        
        #elemBegin is outside the occupancyList. Always true.
        prevEnd <= elemBegin
        
        
        
    getOccupancy: (col) =>
        if not @occupancyIndex[col]
            @occupancyIndex[col] = []
        @occupancyIndex[col]        


        
    layoutElement: (elem) =>
        
        #Find the number of columns possible
        # For each column, space occupied is width(w) + spacing(s), except the right-most, which has no padding
        # Let total columns be N. Let n be 'non-rightmost' columns, ie.. N-1
        #   total-width(t) = nw + ns + w; 
        #   n = (t-w)/(w+s); and N = (t-w)/(w+s) + 1
        
        elem = $(elem)        
        elem.addClass 'layout-managed'
        
        #Represents the width (in columns) of a elem
        # means we can fit a elem only from 1..(max-elemColSize).
        elemColSize = parseInt elem[0].className.match(/cols-(\d+)/)[1]
        
        #they are initially expected to be hidden
        elem.css "width", (elemColSize * @style.colWidth) + ((elemColSize - 1) * @style.colSpacing) + "px"

        #Our fitting algorithm is:
        #   Find vacancy in col(x)
        #   See if compatible sections are available in all columns between col(x-l) and col(x+r)
        #       where (l+r) = elemColSize-1

        #List of vacancies found in each column.        
        vacancies = []
        
        for indexColumn in [0..(@maxColumns-elemColSize)]
            #start from bigger of 0 || x-l                
            firstCol = if 0 > (indexColumn - (elemColSize - 1)) then 0 else (indexColumn - (elemColSize - 1))
            for vacancy in @getVacancies(indexColumn, elem.outerHeight(true))
                #see if that specific spot is vacant in all columns this elem will span
                for elemStartCol in [firstCol..indexColumn]
                    vacant = true
                    for checkingColumn in [elemStartCol..(elemStartCol + (elemColSize - 1))]
                        if indexColumn isnt checkingColumn
                            if not @hasVacancy(checkingColumn, vacancy, elem.outerHeight(true))
                                vacant = false
                                break
                    if vacant
                        vacancies.push { vacancy, elemStartCol }
                        #found the top most possible vacancy for indexCol.
                        break

        #find the topmost vacancy across all cols (ie, indexCols)
        comparer = (a, b) ->
            if a.vacancy < b.vacancy then -1 else if a.vacancy > b.vacancy then 1 else 0
        vacancies.sort comparer
        
        for col in [vacancies[0].elemStartCol..(vacancies[0].elemStartCol + (elemColSize - 1))]
            @addOccupancy col, vacancies[0].vacancy, elem.outerHeight(true), if col is vacancies[0].elemStartCol then elem
        
        left = vacancies[0].elemStartCol * (@style.colWidth + @style.leftPadding + @style.rightPadding + @style.colSpacing) + @style.left
        
        elem.css "display", "block"
        

window.Poe3.Layout = Layout        
        
