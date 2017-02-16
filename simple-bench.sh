#!/bin/bash

disk_latency_test() {
  local sample_count=${1:-3}
  local container_image=${2:-"host"}
  local label=${3:-""}
  local prefix_cmd="timeout --kill-after=30s 2m "
  for iter in $(seq 1 ${sample_count}); do
    echo "--> From ${container_image^} ${label} ${iter}/${sample_count}"
    echo "------------------------------"
    if [ "hostx" == "${container_image}x" ]; then
      test_filename="${PWD}/test512kb_zero_${container_image%:*}_${iter}.data"
      test_cmd="time -p dd if=/dev/zero of=${test_filename} bs=512 count=1000 conv=fdatasync "
      ${prefix_cmd} ${test_cmd}
    else
      test_filename="/mnt/test512kb_zero_$(basename ${container_image%%:*})_${iter}.data"
      test_cmd="time -p dd if=/dev/zero of=${test_filename} bs=512 count=1000 conv=fdatasync "
      docker_cmd="docker run --rm -v $PWD/:/mnt -w /mnt ${container_image} bash -c "
      ${prefix_cmd} ${docker_cmd} "${test_cmd}"
    fi
    sync -f
    echo "------------------------------"
    echo
  done
}

disk_throughput_test() {
  local sample_count=${1:-3}
  local container_image=${2:-"host"}
  local label=${3:-""}
  local prefix_cmd="timeout --kill-after=30s 2m "
  for iter in $(seq 1 ${sample_count}); do
    echo "--> From ${container_image^} ${label} ${iter}/${sample_count}"
    echo "------------------------------"
    if [ "hostx" == "${container_image}x" ]; then
      test_filename="${PWD}/test1G_zero_$(basename ${container_image%%:*})_${iter}.data"
      test_cmd="time -p dd if=/dev/zero of=${test_filename} bs=1G count=1 conv=fdatasync "
      ${prefix_cmd} ${test_cmd}
    else
      test_filename="/mnt/test1G_zero_$(basename ${container_image%%:*})_${iter}.data"
      test_cmd="time -p dd if=/dev/zero of=${test_filename} bs=1G count=1 conv=fdatasync "
      docker_cmd="docker run --rm -v $PWD/:/mnt -w /mnt ${container_image} bash -c "
      ${prefix_cmd} ${docker_cmd} "${test_cmd}"
    fi
    sync -f
    echo "------------------------------"
    echo
  done
}

cpu_speed_test() {
  local sample_count=${1:-3}
  local container_image=${2:-"host"}
  local label=${3:-""}
  local prefix_cmd="timeout --kill-after=30s 2m "
  for iter in $(seq 1 ${sample_count}); do
    echo "--> From ${container_image^} ${label} ${iter}/${sample_count}"
    echo "------------------------------"
    test_cmd='dd if=/dev/zero bs=1M count=1024 | md5sum'
    if [ "hostx" == "${container_image}x" ]; then
      ${prefix_cmd} bash -c "${test_cmd}"
    else
      docker_cmd="docker run --rm -v $PWD/:/mnt -w /mnt ${container_image} bash -c "
      ${prefix_cmd} ${docker_cmd} "${test_cmd}"
    fi
    sync -f
    echo "------------------------------"
    echo
  done

}

echo "Testing performance"
echo "--------------------"
echo
echo "Executing Simple CPU Benchmark: 1000 blocks of 1M filled by Zeros sent to md5sum"
echo
cpu_speed_test 3
cpu_speed_test 3 'debian:jessie' 'x86_64'
cpu_speed_test 3 'multiarch/debian-debootstrap:armhf-jessie' 'ARM'

echo "Executing disk write test for Latency: 1000 blocks of 512B filled by Zeros"
echo
disk_latency_test 3
disk_latency_test 3 'debian:jessie' 'x86_64'
disk_latency_test 3 'multiarch/debian-debootstrap:armhf-jessie' 'ARM'

echo "Executing disk write test for throughput: 1 block of 1GB filled by Zeros"
echo
disk_throughput_test 3
disk_throughput_test 3 'debian:jessie' 'x86_64'
disk_throughput_test 3 'multiarch/debian-debootstrap:armhf-jessie' 'ARM'
echo
echo "Cleaning up"
rm -f *.data

