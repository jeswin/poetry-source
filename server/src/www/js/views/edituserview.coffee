class EditUserView extends Poe3.ModalView

    constructor: (@domain, @username) ->
        super { model: new Poe3.User { domain: @domain, username: @username } }



    initialize: =>
        @model.bind 'change', @render, @
        @model.fetch()
        
        
        
    render: =>
        @setTitle "Editing #{@model.get('name')}"

        @createModalContainer 'edit-user-view-container'        

        user = @model.toTemplateParam()
        $('.edit-user-view-container').html @el
        $(@el).html @template user

        @displayModal()
        
        $(document).bindNew 'click', '.edit-form button.save', @save
        
        @onRenderComplete '.edit-user-view-container'
            
        
        
    save: =>
        params = {
            id: @model.get('id'),
            about: $('.edit-user .about').val(),
            twitterUsername: $('.edit-user .twitter-username').val(),
            website: $('.edit-user .website').val()
        }
        
        user = new Poe3.User params
        user.save {}, {
            success: (model, resp) =>                
                app.activeView.model.set resp       
                @closeModal()
        }

        
    
window.Poe3.EditUserView = EditUserView
