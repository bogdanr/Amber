#!/bin/bash
#set -x
#set -e


buildKernel() {

  if [[ ! -d zen-kernel ]]; then
    git clone git@github.com:zen-kernel/zen-kernel.git
  fi

  cd initramfs64
  #find . -print | cpio -o -H newc 2>/dev/null | xz -f --extreme --check=crc32 > ../initramfs64.img
  find . -print | cpio -o -H newc 2>/dev/null > ../zen-kernel/initramfs64.cpio
  cd -
  cp kernel.config zen-kernel/.config
  cd zen-kernel
  git pull
  rm -f .version
  make -j4
  cp arch/x86/boot/bzImage ../redisKernel
  cd -
  sync
  du -h redisKernel

}

# UNTESTED
buildBusybox() {

  BBVERSION="busybox-1.26.2"

  if [[ ! -d $BBVERSION ]]; then
    wget http://busybox.net/downloads/$BBVERSION.tar.bz2
    tar xvf $BBVERSION
  fi

  cp busybox.config $BBVERSIION/.config
  cd $BBVERSION
  make -j4
  cp busybox ../initramfs/bin/
  cd -
  sync

}

handleLibs() {

  LIBS=(`LD_TRACE_LOADED_OBJECTS=1 $PRGM | awk -F ">" '/=/ {print $2}' | cut -d " " -f2 | grep -v libc.so.6`)
  for LIB in ${LIBS[*]}; do
    case $1 in
      "install" )
	  cp $LIB initramfs64$LIB
      ;;
      "clean" )
	  rm initramfs$LIB
      ;;
    esac
  done

}

runVM() {

  #qemu-system-x86_64 --enable-kvm -kernel redisKernel -append "ip=10.0.2.15::10.0.2.2:255.255.255.0:myboard:eth0:off:8.8.8.8 vga=5 quiet"
  if virsh domdisplay RedisKernel; then
    virsh destroy RedisKernel
  fi
  virsh create RedisKernel.xml
  echo "Waiting 3 seconds for all to run"
  sleep 3

}

testRedis() {

  echo "Look below for how long Redis was running"
  ./tools/redis-cli -h 192.168.122.10 -p 6379 info | grep uptime_in_seconds
  spicy --uri `virsh domdisplay RedisKernel`

}

testMemcached() {

  echo ...testing
  echo stats | nc 102.168.122.10 11211
  spicy --uri `virsh domdisplay RedisKernel`

}

buildRedis() {

cp $PRGM initramfs64/usr/bin/redis-server
strip initramfs64/usr/bin/redis-server

echo "#!/bin/sh
# Make Redis happy
echo 512 > /proc/sys/net/core/somaxconn
echo 1 > /proc/sys/vm/overcommit_memory
ulimit -n 10240

/usr/bin/redis-server /etc/redis.conf
" > initramfs64/run_app
chmod +x initramfs64/run_app

buildKernel
runVM
testRedis

rm initramfs64/usr/bin/redis-server
}

buildMemcached() {

cp $PRGM initramfs64/usr/bin/memcached
strip initramfs64/usr/bin/memcached

echo "#!/bin/sh
ulimit -n 10240
whoami

/usr/bin/memcached -u root
" > initramfs64/run_app
chmod +x initramfs64/run_app

handleLibs install
buildKernel
handleLibs clean
runVM
testMemcached

rm initramfs64/usr/bin/redis-server

}



if [[ -z $1 ]]; then
	echo "Tell me what to build"
	echo "You options are: redis, memcached"
else
	case $1 in
	 "redis" )
          PRGM="apps/redis-3.2.6/src/redis-server"
	  echo "...BUILDING REDIS"
          buildRedis
	 ;;
	 "memcached" )
          PRGM="apps/memcached-1.4.34/memcached"
	  echo "...BUILDING MEMCACHED"
	  buildMemcached
	 ;;
	 "test" )
          PRGM="apps/redis-3.2.6/src/redis-server"
	  echo "...TESTING SOMETHING"
	  handleLibs clean
	 ;;
	esac
	echo -e "\n $0 \033[7m DONE \033[0m \n"
fi



