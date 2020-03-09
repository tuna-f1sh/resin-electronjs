#!/bin/bash

# By default docker gives us 64MB of shared memory size but to display heavy
# pages we need more.
umount /dev/shm && mount -t tmpfs shm /dev/shm

# load goodix driver for hyperpixel4
if [[ -z "${HYPERPIXEL4}" ]]; then
  echo Not using Hyperpixel 4 display
else
  echo Configuring Hyperpixel 4 display
  modprobe i2c-dev && modprobe goodix && /usr/bin/hyperpixel4-init
  # link software i2c from display to usual hardware 1 which is not available
  ln -s /dev/i2c-3 /dev/i2c-1
  # add RTC as device on i2c-3 bus (ds1307 is compatable with ds3231)
  echo ds1307 0x68 > /sys/class/i2c-adapter/i2c-3/new_device
fi

# Default to UTC if no TIMEZONE env variable is set
./rtc_time.sh
echo "Setting time zone to ${TIMEZONE=UTC}"
rm -f /etc/localtime
ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime

# using local electron module instead of the global electron lets you
# easily control specific version dependency between your app and electron itself.
# the syntax below starts an X istance with ONLY our electronJS fired up,
# it saves you a LOT of resources avoiding full-desktops envs

rm /tmp/.X0-lock &>/dev/null || true

if [ ! -c /dev/fb1 ] && [ "$TFT" = "1" ]; then
  modprobe spi-bcm2708 || true
  modprobe fbtft_device name=pitft verbose=0 rotate=${TFT_ROTATE:-0} || true
  sleep 1
  mknod /dev/fb1 c $(cat /sys/class/graphics/fb1/dev | tr ':' ' ') || true
  FRAMEBUFFER=/dev/fb1 startx /usr/src/app/node_modules/electron/dist/electron /usr/src/app --enable-logging --no-sandbox
else
  DBUS_SYSTEM_BUS_ADDRESS=unix:path=/host/run/dbus/system_bus_socket startx /usr/src/app/node_modules/electron/dist/electron /usr/src/app --enable-logging --no-sandbox
fi
