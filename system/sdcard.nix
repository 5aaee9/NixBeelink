{ nixpkgs, packages }:

import "${toString nixpkgs}/nixos/lib/eval-config.nix" {
  system = "aarch64-linux";
  modules = [
    "${toString nixpkgs}/nixos/modules/installer/sd-card/sd-image.nix"
    "${toString nixpkgs}/nixos/modules/profiles/base.nix"

    ({ pkgs, lib, config, ... }:

    {
      # Bootloader
      boot.loader.grub.enable = false;
      boot.loader.generic-extlinux-compatible.enable = true;

      boot.consoleLogLevel = lib.mkDefault 7;
      boot.kernelParams = ["console=ttyS0,115200n8" "console=ttyAMA0,115200n8" "console=tty0"];

      hardware.deviceTree.name = "amlogic/meson-g12b-gtking.dtb";

      sdImage = let
        bootScript = pkgs.writeText "aml_autoscript.src" ''
          if printenv bootfromsd; then exit; else setenv ab 0; fi;
          setenv bootcmd 'run start_autoscript; run storeboot'
          setenv start_autoscript 'if mmcinfo; then run start_mmc_autoscript; fi; if usb start; then run start_usb_autoscript; fi; run start_emmc_autoscript'
          setenv start_emmc_autoscript 'if fatload mmc 1 1020000 autoscript; then autoscr 1020000; fi;'
          setenv start_mmc_autoscript 'if fatload mmc 0 1020000 autoscript; then autoscr 1020000; fi;'
          setenv start_usb_autoscript 'for usbdev in 0 1 2 3; do if fatload usb ''${usbdev} 1020000 autoscript; then autoscr 1020000; fi; done'
          setenv upgrade_step 2
          saveenv
          sleep 1
          reboot
        '';

        autoScript = pkgs.writeText "autoscript.src" ''
          echo "start new uboot to extlinux"
          if fatload mmc 0 0x1000000 u-boot.ext; then go 0x1000000; fi;
          if fatload mmc 1 0x1000000 u-boot.ext; then go 0x1000000; fi;
          if fatload usb 0 0x1000000 u-boot.ext; then go 0x1000000; fi;
        '';
      in {
        firmwareSize = 512;

        populateFirmwareCommands = ''
          ${pkgs.ubootTools}/bin/mkimage -A arm -O linux -T script -C none -d ${bootScript} firmware/aml_autoscript
          ${pkgs.ubootTools}/bin/mkimage -A arm -O linux -T script -C none -d ${autoScript} firmware/autoscript

          cp ${packages.beelink-uboot}/u-boot.bin firmware/u-boot.ext
          ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./firmware
        '';


        postBuildCommands = ''
          # set part 1 bootable, that can load extlinux from it
          ${pkgs.parted}/bin/parted $img set 1 boot on

          dd if="${packages.beelink-uboot}/u-boot.bin.sd.bin" of="$img" conv=fsync,notrunc bs=512 skip=1 seek=1
          dd if="${packages.beelink-uboot}/u-boot.bin.sd.bin" of="$img" conv=fsync,notrunc bs=1 count=444
        '';

        populateRootCommands = "";
      };

      services.openssh.enable = true;
      services.openssh.permitRootLogin = "yes";

      networking = {
        useDHCP = false;
        useNetworkd = true;
        hostName = "edge";
      };

      systemd.network.networks.eth0 = {
        name = "eth0";
        DHCP = "yes";
      };

      users.users.root.openssh.authorizedKeys.keys = [
        # CI Deploy Keys
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBuNngR3JgkjC7I7g8/v4YQNH8Pu13bZcCl9q7Ho8hYJ"
        # Home NAS
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDHDfjdhKhsp76c/c3q9o8HHwFoZ5SjKi6jVEQp6B4Ty root@nixos"
        # Glowstone Laptop
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQChAHl9xXQPu0uF1kEoLLT/mpIdasbaTItnh3kQSk8X2G1Sf9MBnaDQhZ/VcCbehJNZ/tfai+ieUgm/fUtaefLiJwQXm0sx85YB2VroYBr2iSpxc8ia68PQ6+Ii784fAjLWADX4THOHexCYcIzDgVq1pTh/IR/8KVFfKiuhPqEYYUFbZ/oH2VuNKGtIso/leBgoUM/7Tgg+nKzMuv96PMlxzpTsQT9ogX3kTx8xAvKvJ/kyzemmZQoxw5dtcK7ojAOB8kPG0fybCz4EGJmFjyMzB4BtADeShCnUXcHoUcj3NXyp6DhAYfHg/L4s6yfKnZg4TPOdOuDnv5WNHGWzNQlEoCOu2cP9tjQmCtvFasLjQIBwuM1vjtYQY3FsMiMMHskIwGosSwF102ovylpASzIfsTldzWXoqOwUcMDC341SznY4WbejIX4WYKw/qt+CPXNZmQfpCVRuqHFihc2qPMiLqt/q4CrzplUupthWdXkzrP595Qzw/MYrQkCITTZ1Gts= indexyz@Glowstone"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJg/HHwlBxt2/Io+4M5j6Qwwi8IMTYe8XoDijkfTXHoE"
      ];
    })
  ];
}
