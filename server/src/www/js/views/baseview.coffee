class BaseView extends Backbone.View

    constructor: (options = {}) ->         
        @instanceid = Poe3.uniqueId()     
        @href = window.location.href
        super options


            
    getImageDimensions: (url, cb) =>    
        img = new Image
        img.src = url
        img.onload = () ->
            cb null, { width: @width, height: @height }



    defaultLayoutStyle: =>
        { top:0, colWidth: 300, colSpacing: 16, adjustWidth: true, widthToSpacingRatio: 6, marginLeft: 20, marginRight: 32 }



    onRenderComplete: (selector) =>
        Poe3.fixAnchors selector   

        
        
    replaceWithHumor: (reason, defaultText) =>
        list = switch reason
            when 'empty'
                [
                    "Empty pockets never held anyone back. Only empty heads and empty hearts can do that.",
                    "Education's purpose is to replace an empty mind with an open one.",
                    "All empty souls tend toward extreme opinions.",
                    "I keep my hands empty for the sake of what I have had in them.",
                    "Thoughts without content are empty, intuitions without concepts are blind.",
                    "Words empty as the wind are best left unsaid.",
                    "Prometheus is reaching out for the stars with an empty grin on his face.",
                    "I looked into that empty bottle and I saw myself."
                ]
            when 'empty-profile'
                [
                    "When I die, I want to die like my grandfather who died peacefully in his sleep. Not screaming like all the 
                     passengers in his car. <span style=\"font-style: italic\">- Will Rogers</span>"
                ]
            else
                [defaultText]
        list[parseInt(Math.random() * list.length)]
        

        
    sanitize: (text) =>
        #trim the content (spaces and newlines and beginning and end)
        text = text.replace(/^\s+|\s+$/g, '')
        #replace multiple spaces with a single space
        text = text.replace(/[ \t]{2,}/g, ' ')
        text        
  


    countLines: (text) =>
        text.split("\n").length        

        
       
    countWords: (text) =>
        text.split(" ").length     
        

    
class PageView extends BaseView

    constructor: (options) ->
        app.activeView = @
        
        #This is a new full page. Clear any modals that exist.
        if $('.modal-popup').length
            $('.modal-popup').trigger 'close', { navigateBack: false }         
        
        #Clear off all modals, just in case.
        app.activeModals = []
        
        super



    setTitle: (text, addAppname = true) =>
        $(document)[0].title = text



class ModalView extends BaseView

    constructor: (options) ->        
        @modalConfig = {}
        super
        
        

    setTitle: (text, addAppname = true) =>
        @previousDocumentTitle = $(document)[0].title
        $(document)[0].title = text
        
        
        
    createModalContainer: (@className) =>        

        if not @modalInitialized
            $('body').append "<div class=\"#{@className} modal-popup\"></div>"
            app.activeModals.push this                

            #If this is the top modal and there is another below us, hide the one below.
            if app.activeModals.length > 1
                me = app.activeModals[app.activeModals.length - 1]
                previous = app.activeModals[app.activeModals.length - 2]
                if this is me
                    $(".#{previous.className}").css 'opacity', '0.2'
                    #Clicking on the previous modal should close the top modal. So attach a handler.
                    $(document).bindNew 'click', ".#{previous.className}", =>
                        $(".#{@className}").trigger 'close'

        else
            $(".#{@className}").html ''
      

    
    displayModal: =>        
        #displayModal can only be called once.        
        if not @modalInitialized
            @modalInitialized = true
        
            @lightbox = {}
            $(".#{@className}").lightbox_me {     
                onClose: @onClose,                        
                overlayCSS: { background: 'black', opacity: .98 },
                destroyOnClose: true,
                lightboxReference: @lightbox
            }            
        
            $(".#{@className}").prepend '
                <p class="close-modal">
                    <i class="icon-remove"></i>
                </p>'
                

            $(document).bindNew 'mouseenter', ".#{@className}", =>
                @fadePopup = false
                $(".#{@className} .close-modal").addClass 'visible'
                
                
            $(document).bindNew 'mouseleave', ".#{@className}", =>
                @fadePopup = true
                setTimeout (=>
                    if @fadePopup
                        $(".#{@className} .close-modal").removeClass 'visible'), 2000
                

            $(document).bindNew 'click', ".#{@className} > .close-modal", =>
                $(".#{@className}").trigger 'close', { mustClose: true }
    
    

    #Fired before the modal closes.
    onClose: (e, options) =>
        #defaults.
        options ?= {}
        options.navigateBack ?= true
        options.mustClose ?= false
        
        #If a modal modal exists, close event should close the modal modal instead of the main modal.
        #   However, if the close button was explicitly clicked the main modal should be closed.
        #   - We know this because the close button sets mustClose to true.
        modalModal = $(".#{@className} .modal-modal")
        if modalModal.length and not options.mustClose
            @closeModalModal()
            #Cancel modal close by returning false.
            { close: false }
        else
            if @previousDocumentTitle
                $(document)[0].title = @previousDocumentTitle

            #pop off
            app.activeModals.pop()
            #If there is a modal behind this, we need to make it visible again
            if app.activeModals.length
                last = app.activeModals[app.activeModals.length - 1]
                $(".#{last.className}").css 'opacity', '1.0'
                #When we have modal on another modal, we would have attached a click on previous. Turn it off.
                $(document).off 'click', ".#{last.className}"

            @closeModalModal() #Make sure modal modal is closed
            { close: true, afterClose: @afterClose(options) }
        
    
    
    #Fired after the modal is removed from the DOM.
    afterClose: (options) =>
        =>
            #If the user manually clicks 'back', we don't need to do history.back().
            #Then the parent page will pass navigateBack as false, when it finds an un-closed modal.
            if options.navigateBack
                if @modalConfig.returnUrl
                    app.navigate @modalConfig.returnUrl, true
                else                            
                    if app.activeView
                        #If the modal has a url, and there is an active view (supposedly, the parent view), we need to do a history.back().
                        #   This returns the url to previous state.
                        #If the modal has no url, nothing needs to be done.
                        if not @modalConfig.urlLess
                            app.activeView.modalClosed = true
                            history.back()
                    else
                        #if there is no active modal, return to base!
                        #This strange situation happens when the url is showing a modal without a page behind it.
                        #   Actually, not so uncommon. Try refreshing example.com/nnn.
                        if not app.activeModals.length
                            app.navigate '/', true
            


    closeModal: =>
        $(".#{@className}").trigger 'close', { mustClose: true }
        
        
        
    showMessage: (text, type) =>
        $(".#{@className} div.message").html text
        if type
            $(".#{@className} div.message").addClass type
        $(".#{@className} div.message").show()


    
    hideMessage: () =>
        $(".#{@className} div.message").hide()

    
    
    displayModalModal: (parentSection, content, height) =>
        $(".#{@className} .modal-modal").remove()
        parentSection.append '<div class="modal-modal" style="display:none"></div>'
        modalModal = $(".#{@className} .modal-modal")
        modalModal.append content
        height = height ? (modalModal.height() + 32)
        top = parentSection.height() - (height + 48)
        if top < 64
            top = 64
        modalModal.css 'min-height', "#{height}px"
        modalModal.css 'top', "#{top}px"
        modalModal.css 'padding', '24px'
        modalModal.css 'width', "#{parentSection.width() - 48}px"
        
        $(".#{@className} .modal-modal").prepend '
            <p class="close-modal">
                <i class="icon-remove"></i>
            </p>'
            
        $(document).bindNew 'click', ".#{@className} .modal-modal > .close-modal", =>
            @closeModalModal()
        
        #Clicking anywhere on the parent should close the modal modal
        $(document).bindNew 'click', ".#{@className}", =>
            if $(".#{@className} .modal-modal").length
                @closeModalModal()
        
        #Clicking on the modal modal itself shouldn't close the modal modal.
        #   Stop event propogation to the parent.
        $(document).bindNew 'click', ".#{@className} .modal-modal", =>
            false
        
        modalModal.show()
        
        
    closeModalModal: =>
        #When we have a modal modal, we have a click event listener attached to the modal popup. Turn it off.
        $(document).off 'click', ".#{@className}"
        $(".#{@className} .modal-modal").remove()        
        false
      
      
    _hack_overlayHeightRefresh: =>
        @lightbox.setOverlayHeight()        
        
            
window.Poe3.BaseView = BaseView
window.Poe3.PageView = PageView
window.Poe3.ModalView = ModalView
