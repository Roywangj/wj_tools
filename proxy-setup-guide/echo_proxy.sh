#!/usr/bin/env bash

echo "== 当前代理环境变量 =="
echo "代理: ${http_proxy:-${https_proxy:-${all_proxy:-}}}"
echo "主机: ${PROXY_HOST:-}"
echo "端口: ${PROXY_PORT:-}"
echo "https_proxy: ${https_proxy:-}"
echo "all_proxy:   ${all_proxy:-}"
echo "no_proxy:    ${no_proxy:-}"

echo
echo "== 编辑器代理相关配置 =="

if [ -f "$HOME/.cursor-server/data/Machine/settings.json" ]; then
  echo "-- Cursor Server --"
  cat "$HOME/.cursor-server/data/Machine/settings.json"
else
  echo "Cursor Server settings.json 不存在"
fi

echo

if [ -f "$HOME/.vscode-server/data/Machine/settings.json" ]; then
  echo "-- VS Code Server --"
  cat "$HOME/.vscode-server/data/Machine/settings.json"
else
  echo "VS Code Server settings.json 不存在"
fi
