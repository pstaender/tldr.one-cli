request = require('request')
fs = require('fs')
qs = require('querystring')
config = {}
configFileName = '.tldr.one.yml'
_ = require('lodash')

# check and merge config file(s); in this folder and in home dir
[ __dirname+'/../'+configFileName, require('home-dir')()+'/'+configFileName ].forEach (ymlFilePath) ->
  try
    configData = require('yaml').eval(fs.readFileSync(ymlFilePath).toString())
    config = _.assign config, configData
  catch e

argv = require('yargs')
    .help('h')
    .alias('h', 'help')
    .describe('sort', 'sort articles by attribute')
    .default('sort', config.cli.queryParameters.sort)
    .choices('sort', ['popular', 'recent'])
    .describe('limit', 'number max. articles displayed')
    .default('limit', Number(config.cli.queryParameters.limit))
    .describe('debug', 'display additional debug information')
    .choices('debug', ['0', '1'])
    .default('debug', String(Number(config.cli.debug)))
    .describe('excludeFooter', 'hide footer')
    .default('excludeFooter', config.cli.queryParameters.excludeFooter)
    .describe('categories', 'List all available news categories')
    .describe('coloredOutput', 'Use colored terminal text')
    .default('coloredOutput', String(Number(config.cli.coloredOutput)))
    .choices('coloredOutput', ['0', '1'])
    .usage('Usage: tldr.one [url] [options]')
    .epilog('Copyright 2016 by Philipp Staender, https://tldr.one')
    .argv

request.tldr = (options = {}, cb) ->
  options.method ?= 'GET'
  options.parameters ?= {}
  method = options.method
  headers = {}
  headers['Accept'] = 'text/plain' unless argv.coloredOutput
  # add file type and query parameter(s)
  url = options.url.replace(/\.[a-zA-Z]+$/,'')+'.txt?' + qs.stringify(queryParameters)
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
      console.log "\n# Available Categories:\n"
      data.newsCategories.forEach (newsCategory) ->
        title = newsCategory.menu_title + Array(20 - newsCategory.menu_title.length).join(' ')
        console.log "#{title}#{newsCategory.link.replace(/^\//,'')}"
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
}

# convert arguments to numbers
argv.debug = Number(argv.debug)
argv.coloredOutput = Number(argv.coloredOutput)
queryParameters.limit = Number(queryParameters.limit)
queryParameters.excludeFooter = Number(queryParameters.excludeFooter)

request.tldr { url: requestURL, parameters: queryParameters }, (err, res) ->
  if argv.debug
    console.error "<-- statusCode: #{res?.statusCode}"
  if err or res?.statusCode isnt 200
    console.error "couldn't find something useful (#{err || res?.statusCode})\ntldr.one --categories \tlists all available categories"
    process.exit(1)
  else
    console.log res.body
