#!/bin/sh

echo entering virtualenv shell
. "${1:-env}/bin/activate" && \
  exec env \
    VIRTUAL_ENV="$VIRTUAL_ENV" \
    PATH="$VIRTUAL_ENV/bin:$PATH" \
    "$SHELL"

