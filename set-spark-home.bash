#!/usr/bin/env bash

asdf_set_spark_home() {
  local spark_home_path

  spark_home_path="$(asdf where spark)"

  if [[ -n "${spark_home_path}" ]]; then
    export SPARK_HOME
    SPARK_HOME="${spark_home_path}"
  fi
}

asdf_set_spark_home_prompt_command() {
  if [[ "${PWD}" == "${LAST_PWD}" ]]; then
    return
  fi

  LAST_PWD="${PWD}"
  asdf_set_spark_home
}

if ! [[ "${PROMPT_COMMAND}" =~ asdf_set_spark_home_prompt_command ]]; then
  PROMPT_COMMAND="asdf_set_spark_home_prompt_command${PROMPT_COMMAND:+";${PROMPT_COMMAND}"}"
fi
