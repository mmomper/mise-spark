<div align="center">

# asdf-spark [![Build](https://github.com/jeffryang24/asdf-spark/actions/workflows/build.yml/badge.svg)](https://github.com/jeffryang24/asdf-spark/actions/workflows/build.yml) [![Lint](https://github.com/jeffryang24/asdf-spark/actions/workflows/lint.yml/badge.svg)](https://github.com/jeffryang24/asdf-spark/actions/workflows/lint.yml)

[Apache Spark](https://spark.apache.org/docs/latest/) plugin for the [asdf version manager](https://asdf-vm.com).

</div>

# Contents

- [Dependencies](#dependencies)
- [Environment Variables](#environment-variables)
- [Install](#install)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License](#license)

# Dependencies

- `java`: JDK, you can install it using [asdf-java](https://github.com/halcyon/asdf-java) plugin.
- `bash`, `curl`, `tar`: Generic POSIX utilities.
- `shasum`: Verify archive checksum.

# Environment Variables

- `ASDF_SPARK_HADOOP_VERSION`: Set this environment variable to use custom hadoop version from the Spark archive download page, e.g. `ASDF_SPARK_HADOOP_VERSION=3 asdf install spark 3.3.0`. By default, this plugin will pick the latest hadoop version from the archive page if this environment variable is not being set.
- `ASDF_SPARK_WITHOUT_HADOOP`: Set this environment variable to download spark binary archive without hadoop support, e.g. `ASDF_SPARK_WITHOUT_HADOOP=1 asdf install spark 3.3.0`. By default, this plugin will download spark archive with hadoop support if this environment variable is not being set.
- `ASDF_SPARK_SKIP_VERIFICATION`: Set this environment variable to skip archive checksum verification step, e.g. `ASDF_SPARK_SKIP_VERIFICATION=1 asdf install spark 3.3.0`. By default, this plugin will verify the archive checksum if this environment variable is not being set.

# Install

Plugin:

```shell
asdf plugin add spark https://github.com/jeffryang24/asdf-spark.git
# or
asdf plugin add spark git@github.com:jeffryang24/asdf-spark.git
```

spark:

```shell
# Show all installable versions
asdf list-all spark

# Install specific version
asdf install spark latest

# Set a version globally (on your ~/.tool-versions file)
asdf global spark latest

# Now spark commands are available
spark-shell --help
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to
install & manage versions.

# FAQ

## How to set `SPARK_HOME` environment variable?

You can set `SPARK_HOME` environment variable inside your shell configuration file. Currently, this plugin only supports `bash` and `zsh` shells. Please note that you must place below scripts after sourcing the asdf-vm since these scripts require `asdf where` command.

For `zsh`, please add this script inside your `.zshrc` file.

```shell
source ~/.asdf/plugins/spark/set-spark-home.zsh
```

For `bash`, please add this script inside your `.bashrc` file.

```shell
source ~/.asdf/plugins/spark/set-spark-home.bash
```

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/jeffryang24/asdf-spark/graphs/contributors)!

# License

Licensed under [Apache License 2.0](LICENSE).
