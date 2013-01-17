class UserListView extends Poe3.ModalView

    constructor: (users, options) ->
        super { model: users }
        @heading = options.heading
        @render()
        @modalConfig.urlLess = true



    render: =>    
        @createModalContainer "user-list-view-container"
        $('.user-list-view-container').html @el
        $(@el).html @template { heading: @heading, users: @model }
        @displayModal()        
        @onRenderComplete '.user-list-view-container'
        
    
window.Poe3.UserListView = UserListView
