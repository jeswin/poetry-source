AppError = require('../../common/apperror').AppError

class Controller        

    getValue: (src, field, safe = true) =>
        src[field]
        
    
    
    handleError: (onError) ->
        (fn) ->
            return ->
                if arguments[0]
                    onError arguments[0]
                else
                    fn.apply undefined, arguments
    
    
    
    setValues: (target, src, fields, options = {}) =>
    
        if not options.safe?
            options.safe = true
        if not options.ignoreEmpty
            options.ignoreEmpty = true

        setValue = (src, targetField, srcField) =>
            val = @getValue src, srcField, options.safe
            if options.ignoreEmpty
                if val?
                    target[field] = val
            else
                target[field] = val

        if fields.constructor == Array
            for field in fields
                setValue src, field, field
        else
            for ft, fsrc of fields
                setValue src, ft, fsrc
                

exports.Controller = Controller
