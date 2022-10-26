<div align="center">

# asdf-spark [![Build](https://github.com/jeffryang24/asdf-spark/actions/workflows/build.yml/badge.svg)](https://github.com/jeffryang24/asdf-spark/actions/workflows/build.yml) [![Lint](https://github.com/jeffryang24/asdf-spark/actions/workflows/lint.yml/badge.svg)](https://github.com/jeffryang24/asdf-spark/actions/workflows/lint.yml)

[Apache Spark](https://spark.apache.org/docs/latest/) plugin for the [asdf version manager](https://asdf-vm.com).

</div>

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Contributing](#contributing)
- [License](#license)

# Dependencies

- `java`: JDK, you can install it using [asdf-java](https://github.com/halcyon/asdf-java) plugin.
- `bash`, `curl`, `tar`: Generic POSIX utilities.
- `ASDF_SPARK_HADOOP_VERSION`: Set this environment variable to use custom hadoop version from the Spark archive download page, e.g. `ASDF_SPARK_HADOOP_VERSION=3`. By default, this plugin will pick the latest hadoop version from the archive page.
- `ASDF_SPARK_WITHOUT_HADOOP`: Set this environment variable to download spark binary without hadoop support, e.g. `ASDF_SPARK_WITHOUT_HADOOP=1`. By default, this plugin will download spark archive with hadoop support.

# Install

Plugin:

```shell
asdf plugin add spark
# or
asdf plugin add spark https://github.com/jeffryang24/asdf-spark.git
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
spark --help
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to
install & manage versions.

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/jeffryang24/asdf-spark/graphs/contributors)!

# License

Licensed under [Apache License 2.0](LICENSE).
