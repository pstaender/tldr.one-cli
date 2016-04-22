request = require('request')
fs = require('fs')
qs = require('querystring')
config = {}
configFileName = '.tldr.one.yml'
_ = require('lodash')

# check and merge config file(s); in this folder and in home dir
[ __dirname+'/../'+configFileName, require('home-dir')()+'/'+configFileName ].forEach (ymlFilePath) ->
  try
    _.merge config, require('yaml').eval(fs.readFileSync(ymlFilePath).toString())
  catch e
    #console.error e

argv = require('yargs')
    .help('h')
    .alias('h', 'help')
    .describe('sort', 'sort articles by attribute')
    .default('sort', config.cli.queryParameters.sort)
    .choices('sort', ['popular', 'recent'])
    .describe('limit', 'number max. articles displayed')
    .default('limit', Number(config.cli.queryParameters.limit))
    .describe('debug', 'display additional debug information')
    .choices('debug', [0, 1])
    .default('debug', Number(config.cli.debug))
    .describe('excludeFooter', 'hide footer')
    .choices('excludeFooter', [0, 1])
    .default('excludeFooter', Number(config.cli.queryParameters.excludeFooter))
    .describe('version', 'version')
    .describe('self-update', 'update global npm installed tldr.one module (may require root privileges)')
    .describe('order', 'sort articles ascending or descending')
    .choices('order', ['+', '-', 'asc', 'desc'])
    .default('order', config.cli.queryParameters.order)
    .describe('categories', 'list all available news categories')
    .describe('coloredOutput', 'use colored terminal text')
    .default('coloredOutput', Number(config.cli.coloredOutput))
    .choices('coloredOutput', [0, 1])
    .usage('Usage: tldr.one [url] [options]')
    .epilog('Copyright 2016 by Philipp Staender, https://tldr.one')
    .argv

if argv.version
  console.log require('../package.json').version
  process.exit(0)
else if argv['self-update']
  child_process = require('child_process')
  console.log "Installed version: #{require('../package.json').version}"
  command = 'npm install -g tldr.one'
  console.log "Performing self update `#{command}` - please stand by"
  selfUpdate = child_process.exec(command)#(command[0], command.slice(1))
  selfUpdate.stdout.pipe(process.stdout)
  selfUpdate.stderr.pipe(process.stderr)
  selfUpdate.on 'close', (exitCode) ->
    console.log "\nNow installed version: "
    cp = child_process.exec('tldr.one --version')
    cp.stdout.pipe(process.stdout)
    cp.on 'close', -> process.exit(exitCode)
  i = 0
  ind = '⠁⠂⠄⡀⢀⠠⠐⠈'
  setInterval ->
    process.stdout.write ind[i%ind.length] + ind[(i+1)%ind.length] + ind[(i+2)%ind.length] + ind[(i+3)%ind.length] + "\r"
    i++
  , 100
else
  request.tldr = (options = {}, cb) ->
    options.method ?= 'GET'
    options.parameters ?= {}
    method = options.method
    headers = {}
    headers['Accept'] = 'text/plain' unless argv.coloredOutput
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
    console.error "--> #{url} (#{method})" if argv.debug
    request { url, method, headers }, cb


  unless config?.cli
    throw Error("No valid config file '#{configFileName}' found: Please reinstall or check manually existing config file(s) for yaml syntax")

  # list categories
  if argv.categories
    return request.tldr url: 'api/v1/news-categories', (err, res) ->
      try
        data = JSON.parse(res.body)
        console.log "\nAvailable Categories:\n"
        data.newsCategories.forEach (newsCategory) ->
          title = newsCategory.menu_title + Array(20 - newsCategory.menu_title.length).join(' ')
          console.log "#{title}#{newsCategory.link.replace(/^\//,'').replace(/\/+$/,'')}"
        process.exit(0)
      catch error
        console.error "Could not get valid data from api:\n#{error} / #{err}"
        process.exit(1)

  # is the first argument an url? (i.e. not starting with - or --)
  unless argv._[0]
    requestURL = config.cli.home
  else unless /^\-{1,2}/.test(argv._[0])
    requestURL = argv._[0]
  else
    console.error("No valid URL given #{argv._[0] || ''}")
    process.exit(1)

  queryParameters = {
    sort: argv.sort || config.cli.queryParameters.sort
    excludeFooter: argv.excludeFooter || config.cli.queryParameters.excludeFooter
    limit: argv.limit || config.cli.queryParameters.limit
    order: argv.order || config.cli.queryParameters.order
  }

  # convert arguments to numbers
  argv.debug = Number(argv.debug)
  argv.coloredOutput = Number(argv.coloredOutput)
  queryParameters.limit = Number(queryParameters.limit)
  queryParameters.excludeFooter = Number(queryParameters.excludeFooter)

  unless argv.debug
    # pipe to stdoutt
    request.tldr({ url: requestURL, parameters: queryParameters }).pipe process.stdout
  else
    request.tldr { url: requestURL, parameters: queryParameters }, (err, res) ->
      console.error "<-- statusCode: #{res?.statusCode}"
      if err or res?.statusCode isnt 200
        console.error "couldn't find something useful (#{err || res?.statusCode})\ntldr.one --categories \tlists all available categories"
        process.exit(1)
      else
        console.log res.body
