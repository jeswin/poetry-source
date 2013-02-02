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
                <img class="fb-login-button" src="/images/facebook.png" alt="FB connect" /> 
                <img class="twitter-login-button" src="/images/twitter.png" alt="FB connect" /> 
            </div>'
                    
        @attachEvents()
        @displayModal()
        

        
    attachEvents: =>        
        $('.login-view-container .fb-login-button').click =>
            FB.login ((response) =>
                @loginSuccess = response.status is 'connected'
                if @loginSuccess
                    app.login 'fb', response.authResponse.accessToken
                $('.login-view-container').trigger 'close', { mustClose: true }
            ), { scope: 'email,publish_actions' }
            false
        

        $('.login-view-container .twitter-login-button').click =>
            window.location.href = "/auth/twitter"
            false
            
            
    
    afterClose: =>
        =>
            if @loginSuccess
                @loginSuccessAction?()
            else
                @loginFailAction?()
            
    
window.Poe3.LoginView = LoginView
