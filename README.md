# Browse through all articles on tldr.one

## Installation

The **tldr.one cli module** requires nodejs.

Install the module with:

```sh
  $ npm install -g tldr.one
```

## Usage

```sh
  $ tldr.one news
```

Query more specific periods of time:

```sh
  $ tldr.one news/yesterday
  $ tldr.one news/thisMonth
  $ tldr.one news/lastWeek
  $ tldr.one news/day/2016-04-19
```

Sort articles with:

```sh
  $ tldr.one news --sort=recent
  $ tldr.one tech --sort=popular
  $ tldr.one tech/lastMonth --sort=popular
```

Limit the number of articles:

```sh
  $ tldr.one news/europe --sort=recent --limit=5
```

or just use `less` to navigate / paginate:

```sh
  $ tldr.one news/europe | less -r
```

Order ascending or descending:

```sh
  $ tldr.one news/europe --order=+
  $ tldr.one news/europe --order=-
```

Toggle between colored output and plain text:

```sh
  $ tldr.one news --coloredOutput=0
```

List all available categories with:

```sh
  $ tldr.one --categories

  Available Categories:

  Sports             other/sports
  Europe             news/europe
  News               news
  Gaming             other/gaming
  Television         other/television
  Gossip             other/gossip
  Science            science
  History            history
  Movies             movies
  Finance            finance
  Tech               tech
```

List all available options with:

```sh
  $ tldr.one -h
```

Update application (same as `npm install -g tldr.one`):

```sh
  $ tldr.one --self-update
```

## Offline reading

You can bulk download all summaries (i.e. for yesterday, this/last week, this/last month …) at once for all categories (takes ~ ½ - 3 mins):

```sh
  $ tldr.one --download
```

or download just specific categories (using glob pattern):

```sh
  $ tldr.one 'news/*' --download
```

Hint: Always apostroph `'` your query when using wilcards `*` to avoid auto-bash-replacements. 

To read the downloaded articles offline, use a leading `:` before the category name:

```sh
  $ tldr.one :news/lastWeek
```

Or if you prefer a explicit (unhandy) switch:

```sh
  $ tldr.one news/lastWeek --offline
```

## Configuration

Default values can be set in a custom `.tldr.one.yml` (needs to be located in your home dir). You can  use [the default config file as template](https://github.com/pstaender/tldr.one-cli/blob/master/.tldr.one.yml) and define your own in `~/.tldr.one.yml`. The custom configuration is optional but helpful if you want to set specific options permanently without writing the argument each time.
