#!/bin/sh
set -e

if [ $(echo "$1" | cut -c1) = "-" ]; then
  echo "$0: assuming arguments for parity"

  set -- parity "$@"
fi

if [ $(echo "$1" | cut -c1) = "-" ] || [ "$1" = "parity" ]; then
  mkdir -p "$ETHEREUM_DATA"
  chmod 700 "$ETHEREUM_DATA"
  chown -R ethereum "$ETHEREUM_DATA"

  echo "$0: setting data directory to $ETHEREUM_DATA"

  set -- "$@" --base-path="$ETHEREUM_DATA"
fi

if [ "$1" = "parity" ]; then
  echo
  exec gosu ethereum "$@"
fi

echo
exec "$@"
