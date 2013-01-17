BaseModel = require('./basemodel').BaseModel
AppError = require('../common/apperror').AppError

class Message extends BaseModel
    
    ###
        Fields
            - userid (string)
            - type (string; global-notification, user-notification)
            - reason (string; new-user, new-post etc)
            - data (object, depends on reason). We don't validate this.
            - timestamp (integer)
    ###

    
    @_meta: {
        type: Message,
        collection: 'messages',
        logging: {
            isLogged: true,
            onInsert: 'NEW_MESSAGE'
        }
    }
    
    
    constructor: (params) ->
        @priority = 'normal'
        super
        
        
    
    save: (context, cb) =>
        @timestamp ?= Date.now()
        super context, cb
        
        
    
    validate: =>
        errors = []
        
        if not @userid?
            errors.push 'Invalid userid.'
         
         if not @type
            errors.push 'Invalid type.'
                    
        if @type is 'user-notification'
            _errors = Message._models.User.validateSummary(@to)
            if _errors.length
                errors.push 'Invalid to.'
                errors.concat _errors
            
            _errors = Message._models.User.validateSummary(@from)
            if _errors.length
                errors.push 'Invalid from.'
                errors.concat _errors
        
        if isNaN(@timestamp)
            errors.push 'Invalid timestamp.'
            
        #We don't care so much about what's in @data; it is based on @reason.
        #If that's messed up, no big deal.
        
        { isValid: errors.length is 0, errors }
        
    
exports.Message = Message
