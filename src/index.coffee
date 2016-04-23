fs = require('fs')
_ = require('lodash')
config = {}
configFileName = process.env.TLDRConfigFile || '.tldr.one.yml'

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
    .default('debug', Number(config.cli.debug))
    .describe('offline', 'read only cached / downloaded files')
    .default('offline', Number(config.cli.offline))
    .describe('download', 'download all articles from categories (matches given glob pattern)')
    .default('download', config.cli.download)
    .describe('excludeFooter', 'hide footer')
    .default('excludeFooter', Number(config.cli.queryParameters.excludeFooter))
    .describe('version', 'version')
    .describe('self-update', 'update global npm installed tldr.one module (may require root privileges)')
    .describe('order', 'sort articles ascending or descending')
    .choices('order', ['+', '-', 'asc', 'desc'])
    .default('order', config.cli.queryParameters.order)
    .describe('categories', 'list all available news categories')
    .describe('coloredOutput', 'use colored terminal text')
    .default('coloredOutput', Number(config.cli.coloredOutput))
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

  unless config?.cli
    throw Error("No valid config file '#{configFileName}' found: Please reinstall or check manually existing config file(s) for yaml syntax")

  # TODO: get rid of argv (i.e. merge with config in a reasonable way)
  config.argv = argv

  # is the first argument an url? (i.e. not starting with - or --)
  requestURL = null
  unless argv._[0]
    requestURL = config.cli.home
  else unless /^\-{1,2}/.test(argv._[0])
    requestURL = argv._[0]

  {
    request
    requestAvailableCategories
    requestArticles
    tempfileFor
    downloadArticles
    writeToTempfile
    urlToTempfileName
  } = require('./request_tldr')(config)


  if argv.download
    pattern = if requestURL is '*' then '**' else argv._[0] || '**'
    return downloadArticles(pattern)

  # list categories
  else if argv.categories
    return requestAvailableCategories (err, newsCategories) ->
      if err
        console.error err.message
        process.exit(1)
      else
        console.log "\nAvailable Categories:\n"
        newsCategories.forEach (newsCategory) ->
          title = newsCategory.menu_title + Array(20 - newsCategory.menu_title.length).join(' ')
          console.log "#{title}#{newsCategory.link.replace(/^\//,'').replace(/\/+$/,'')}"
        process.exit(0)
  else
    # check url
    unless requestURL
      console.error("No valid URL given #{argv._[0] || ''}")
      process.exit(1)

    loadCached = (requestURL) ->
      console.log("--> try to find cached file '#{urlToTempfileName(requestURL)}'") if argv.debug
      #console.log("<-- found cached file") if argv.debug
      tempfileFor(requestURL, undefined, process.stdout)

    # check for cached (if offline mode is explicitly requested)
    if argv.offline or requestURL[0] is ':'
      requestURL = requestURL.substr(1)
      return loadCached(requestURL)
    # request from server
    requestArticles { url: requestURL }, (err, res) ->
      console.error "<-- statusCode: #{res?.statusCode}"
      if err or res?.statusCode isnt 200
        console.error "couldn't find something useful (#{err || res?.statusCode})\ntldr.one --categories \tlists all available categories"
        process.exit(1)
      else
        console.log res.body
