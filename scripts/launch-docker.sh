#!/bin/zsh

MODE=${1:-basic}

case $MODE in
  basic)
    TEMPLATE_VARS="{}"
    ;;
  enhanced)
    TEMPLATE_VARS='{"enhanced":true}'
    ;;
  integrated)
    TEMPLATE_VARS='{"enhanced":true,"integrated":true}' 
    ;;
  *)
    echo "无效模式: $MODE (可用模式: basic/enhanced/integrated)"
    exit 1
esac

# 生成最终配置
jinja2 scripts/docker-compose.template.yml $TEMPLATE_VARS > docker-compose.yml

docker-compose up -d