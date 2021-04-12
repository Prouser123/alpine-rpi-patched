set -x

echo using pwd: $(pwd)

# Part 1: Use Docker to create the .gz image using patcher.sh

sudo rm -rf docker/

mkdir docker/

cp ./* docker/
cp -r ./jcx docker/
cp -r ./.git docker/

chmod +x docker/patcher.sh

docker run -it --rm --workdir /docker --entrypoint ./patcher.sh -v $(pwd)/docker:/docker alpine

# Part 2: turn the patched .gz into a bootable .img

mkdir -p docker/img && cd docker/img

# Script Begin
dd if=/dev/zero bs=1024k count=128 > rpi.img
parted rpi.img mklabel msdos
parted rpi.img mkpart primary fat32 1MB 128MB

LOOP=$(losetup --partscan --show --find rpi.img)
lsblk
echo ${LOOP}p1
mkfs -t fat -n ALPINEBOOT ${LOOP}p1
mkdir -p /mnt/rpi-boot
mount ${LOOP}p1 /mnt/rpi-boot
sudo tar xvf ../alpine-patched.tar.gz -C /mnt/rpi-boot/ --no-same-owner

umount /mnt/rpi-boot
losetup -d $LOOP
# Script End