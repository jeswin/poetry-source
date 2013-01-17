BaseModel = require('./basemodel').BaseModel
AppError = require('../common/apperror').AppError

class UserInfo extends BaseModel

    ###
        Fields
            - userid (string)            
            - lastMessageAccessTime (integer)
    ###    
        
    @_meta: {
        type: UserInfo,
        collection: 'userinfo',
        logging: {
            isLogged: false,
            onInsert: 'NEW_USERINFO'
        }
    }
    


    validate: =>
        errors = []
        
        if not @userid
            errors.push 'Invalid userid.'
        
        { isValid: errors.length is 0, errors }
    
    
    
exports.UserInfo = UserInfo
