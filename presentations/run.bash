#!/bin/bash

xrandr --output HDMI2 --right-of eDP1 --auto

# Run docker stack
pushd ../../xmpp-grid-broker
docker-compose rm --force
docker-compose build
docker-compose up &
popd

# Start presentation
npm start &

# Fine
echo '============================================='
echo "Press enter to exit"
echo '============================================='
read

kill $(jobs -p)

xrandr --output HDMI2 --off
