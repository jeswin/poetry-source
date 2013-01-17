BaseModel = require('./basemodel').BaseModel
AppError = require('../common/apperror').AppError

class Session extends BaseModel

    ###
        Fields
            - passkey (string)
            - accessToken (string)
            - userid (string)
            - timestamp (integer)
    ###    
    
    @_meta: {
        type: Session,
        collection: 'sessions',
        logging: {
            isLogged: false
        }
    }    


                
    validate: =>
        errors = []
        
        if not @passkey
            errors.push 'Invalid passkey.'

        if not @accessToken
            errors.push 'Invalid accessToken.'
            
        if not @userid
            errors.push 'Invalid userid.'
            
        if isNaN(@timestamp)
            errors.push 'Invalid timestamp.'
            
        { isValid: errors.length is 0, errors }



exports.Session = Session
