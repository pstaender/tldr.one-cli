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

Toggle between colored output and plain text:

```sh
  $ tldr.one news --coloredOutput=0
```

List all available categories with:

```sh
  $ tldr.one --categories

  Available Categories:

  Sports             other/sports/
  Europe             news/europe/
  News               news/
  Gaming             other/gaming/
  Television         other/television/
  Gossip             other/gossip/
  Science            science/
  History            history/
  Movies             movies/
  Finance            finance/
  Tech               tech/
```

List all available options with:

```
  $ tldr.one -h
```

Optional: Default values can be set in a custom `.tldr.one.yml` (needs to be located in your home dir). You can  use [the default config file as template](https://github.com/pstaender/tldr.one-cli/blob/master/src/.tldr.one.yml) and set define own in `~/.tldr.one.yml`.
