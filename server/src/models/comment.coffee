BaseModel = require('./basemodel').BaseModel
AppError = require('../common/apperror').AppError

class Comment extends BaseModel

    ###
        Fields
        - postid (string)
        - content (string)
        - createdBy (summarized user)
        - timestamp (integer)
    ###
    
    @_meta: {
        type: Comment,
        collection: 'comments',
        logging: {
            isLogged: true,
            onInsert: 'NEW_COMMENT'
        },
        validateMultiRecordOperationParams: (params) ->            
            params.postid
    }
    
    
    save: (context, cb) =>
        @timestamp = Date.now()
        super context, cb
        
        
        
    validate: =>
        errors = []

        if not @postid
            errors.push 'Missing postid.'
            
        if not @content 
            errors.push 'Missing content.'
        
        _errors = Comment._models.User.validateSummary(@createdBy)
        if _errors.length
            errors.push 'Invalid createdBy.'
            errors = errors.concat _errors
            
        if isNaN(@timestamp)
            errors.push 'Invalid timestamp.'
           
        { isValid: errors.length is 0, errors }
        
        
    
exports.Comment = Comment
