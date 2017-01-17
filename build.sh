#!/bin/bash
#set -x
set -e

buildKernel() {

  cd initramfs64
  #find . -print | cpio -o -H newc 2>/dev/null | xz -f --extreme --check=crc32 > ../initramfs64.img
  find . -print | cpio -o -H newc 2>/dev/null > ../zen-kernel64/initramfs64.cpio
  cd -
  cp kernel.config zen-kernel64/.config
  cd zen-kernel64
  rm -f .version
  make -j4
  cp arch/x86/boot/bzImage ../redisKernel
  cd -
  sync
  du -h redisKernel

}

runVM() {

  #qemu-system-x86_64 --enable-kvm -kernel redisKernel -append "ip=10.0.2.15::10.0.2.2:255.255.255.0:myboard:eth0:off:8.8.8.8 vga=5 quiet"
  virsh destroy RedisKernel
  virsh create RedisKernel.xml
  echo "Waiting 3 seconds for all to run"
  sleep 3

}

testRedis() {

  echo "Look below for how long Redis was running"
  ./tools/redis-cli -h 192.168.122.10 -p 6379 info | grep uptime_in_seconds

}

testMemcached() {

  echo stats | nc 102.168.122.10 11211

}

buildRedis() {

cp apps/redis-3.2.6/src/redis-server initramfs64/usr/bin/redis-server
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


if [[ -z $1 ]]; then
	echo "Tell me what to build"
	echo "You options are: redis, memcached"
else
	case $1 in
	 "redis" )
	  echo "...BUILDING REDIS"
          buildRedis
	 ;;
	 "memcached" )
	  echo "...BUILDING MEMCACHED"
	  buildMemcached
	 ;;
	esac
	echo -e "\n $0 \033[7m DONE \033[0m \n"
fi



