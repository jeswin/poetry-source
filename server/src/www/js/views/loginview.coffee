class LoginView extends Poe3.ModalView

    constructor: (@loginSuccessAction, @loginFailAction) ->
        super()        
        @render()
        @modalConfig.urlLess = true
        


    render: =>  
        @setTitle 'Login with Facebook'
        @createModalContainer "login-view-container"

        $('.login-view-container').html '
            <div class="main-section">
                <p>
                    You need to login to do that.
                </p>
                <img class="fb-login-button" src="/images/fb-connect.png" alt="FB connect" />
            </div>'
                    
        @attachEvents()
        @displayModal()
        

        
    attachEvents: =>        
        $('.login-view-container .fb-login-button').click =>
            FB.login ((response) =>
                @loginSuccess = response.status is 'connected'
                $('.login-view-container').trigger 'close', { mustClose: true }
            ), { scope: 'email,publish_actions' }
        

    
    afterClose: =>
        =>
            if @loginSuccess
                @loginSuccessAction?()
            else
                @loginFailAction?()
            
    
window.Poe3.LoginView = LoginView
