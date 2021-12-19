nix build .#sdImage.aarch64-linux.config.system.build.sdImage

cp result/sd-image/nixos-sd-image-22.05pre-git-aarch64-linux.img.zst .
zstd -d nixos-sd-image-22.05pre-git-aarch64-linux.img.zst
rm -f nixos-sd-image-22.05pre-git-aarch64-linux.img.zst

pv nixos-sd-image-22.05pre-git-aarch64-linux.img | sudo dd conv=fsync,notrunc of=/dev/sdd bs=1M

rm -f nixos-sd-image-22.05pre-git-aarch64-linux.img
rm -f result
