request = require('request')
qs = require('querystring')
fs = require('fs')
Sequence = require('sequence').Sequence
minimatch = require("minimatch")
ProgressBar = require('progress')

module.exports = (config) ->

  request.tldr = (options = {}, cb) ->
    options.method ?= 'GET'
    options.parameters ?= {}
    method = options.method
    headers = {}
    headers['Accept'] = 'text/plain' unless config.argv.coloredOutput
    # add file type and query parameter(s)
    url = options.url
    # query parameter(s) set?
    regexURLParts = /^(.+?)\?(.*)$/
    if regexURLParts.test(url)
      queryString = url.match(regexURLParts)?[2]
      url = url.match(regexURLParts)?[1]
    else
      queryString = ''
    if qs.stringify(options.parameters)
      queryString = if queryString then queryString + '&' + qs.stringify(options.parameters) else qs.stringify(options.parameters)
    url = url.replace(/\.[a-zA-Z]+$/,'').replace(/\/+$/, '')+'.txt?' + queryString
    # add base url
    url = config.cli.baseUrl.replace(/\/+$/,'') + '/' + url.replace(/^(\/*|http[s]*\:\/\/)/, '')
    console.error "--> #{url} (#{method})" if config.argv.debug
    request { url, method, headers }, cb

  requestAvailableCategories = (cb) ->
    request.tldr url: 'api/v1/news-categories', (err, res) ->
      try
        data = JSON.parse(res.body)
        cb(null, data.newsCategories)
      catch error
        cb(Error("Could not get valid data from api:\n#{error} / #{err}"), null)

  requestArticles = (options = {}, cb) ->

    requestURL = options.url
    queryParameters = options.queryParameters || {
      sort: config.argv.sort || config.cli.queryParameters.sort
      excludeFooter: config.argv.excludeFooter || config.cli.queryParameters.excludeFooter
      limit: config.argv.limit || config.cli.queryParameters.limit
      order: config.argv.order || config.cli.queryParameters.order
    }

    # convert arguments to numbers
    config.argv.debug = Number(config.argv.debug)
    config.argv.coloredOutput = Number(config.argv.coloredOutput)
    queryParameters.limit = Number(queryParameters.limit)
    queryParameters.excludeFooter = Number(queryParameters.excludeFooter)

    unless config.argv.debug
      # pipe to stdoutt
      request.tldr({ url: requestURL, parameters: queryParameters }).pipe process.stdout
    else# if typeof cb is 'function'
      request.tldr { url: requestURL, parameters: queryParameters }, cb

  urlToTempfileName = (url, folder = require('os').tmpdir()) ->
    folder + '/tldr.one_cachefile_' + url.replace(config.cli.baseUrl,'').replace(/http[s]*\:\/\//i, '').replace(/\/*$/,'').replace(/[\/\?\&]/g, '-') + '.txt'

  tempfileFor = (url, holdbacktime = 21600, output = false) ->
    now = Date.now()
    filepath = urlToTempfileName(url)
    try
      if lastModified = new Date(fs.statSync(filepath).mtime).getTime()
        if lastModified + (holdbacktime * 1000) >= now
          return if output then fs.createReadStream(filepath).pipe(process.stdout) else fs.readFileSync(filepath).toString()
      # else, needs to be renewed
      return null
    catch error
      console.error(error) unless error.code is 'ENOENT'
      return false

  writeToTempfile = (url, content = '', holdbacktime) ->
    filepath = urlToTempfileName(url)
    if cachedContent = tempfileFor(url, holdbacktime, false)
      return cachedContent
    else
      fs.writeFileSync(filepath, content, 'utf8')
      return true

  downloadArticles = (pattern, cb) ->
    requestAvailableCategories (err, categories) ->
      # download Articles
      timePeriods = [ '', 'yesterday', 'lastWeek', 'thisMonth', 'lastMonth' ]
      if categories
        sequence = new Sequence
        jobs = []
        timePeriods.forEach (timePeriod) ->
          categories.forEach (category) ->
            url = category.link.replace(/^\//,'') + timePeriod
            jobs.push(url) if minimatch(url, pattern)
        bar = new ProgressBar('downloading articles [:bar] :percent :etas', { total: jobs.length })
        jobs.forEach (url) ->
          sequence.then (next) ->
            request.tldr { url }, (err, data) ->
              if not err and data
                console.log("writing #{urlToTempfileName(url)}") if config.argv.debug
                writeToTempfile(url, data.body, 0)
                # console.log data
              bar.tick()
              next()





  { request, requestAvailableCategories, requestArticles, tempfileFor, downloadArticles, writeToTempfile, urlToTempfileName }
