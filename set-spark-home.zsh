#!/usr/bin/env zsh

asdf_set_spark_home() {
  local spark_home_path

  spark_home_path="$(asdf where spark)"

  if [[ -n "${spark_home_path}" ]]; then
    export SPARK_HOME
    SPARK_HOME="${spark_home_path}"
  fi
}

autoload -U add-zsh-hook && add-zsh-hook precmd asdf_set_spark_home
