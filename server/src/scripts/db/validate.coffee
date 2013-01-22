async = require('../../common/async')
utils = require('../../common/utils')
conf = require '../../conf'
models = new (require '../../models').Models(conf.db)
AppError = require('../../common/apperror').AppError
sys = require 'sys'

#Validate everything

tasks = []

typeInfoList = [
    { type: models.Session, id: (x) -> x._id },
    { type: models.User, id: (x) -> "#{x.domain}/#{x.username}" },
    { type: models.UserInfo, id: (x) -> x._id },
    { type: models.Post, id: (x) -> x._id },
    { type: models.Comment, id: (x) -> x._id },
    { type: models.Message, id: (x) -> x._id },                    
]

hasErrors = false
for info in typeInfoList
    do (info) ->
        tasks.push (cb) ->
            info.type.getAll {}, {}, (err, items) =>
                for item in items
                    result = item.validate()
                    if not result.isValid
                        hasErrors = true
                        console.log "#{info.type._meta.collection}(#{info.id(item)}) has errors."
                        for error in result.errors
                            console.log "#{error}"
                        console.log "\n"
                cb()


async.series tasks, ->
    if hasErrors
        console.log "There are errors."
    console.log 'Validation complete.'
    process.exit()
