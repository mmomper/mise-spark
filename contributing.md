# Contributing

Testing Locally:

```shell
asdf plugin test <plugin-name> <plugin-url> [--asdf-tool-version <version>] [--asdf-plugin-gitref <git-ref>] [test-command*]

#
asdf plugin test spark https://github.com/jeffryang24/asdf-spark.git "spark-shell --help"
```

Tests are automatically run in GitHub Actions on push and PR.
