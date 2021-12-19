{ buildUBoot, fetchgit }:

let
  amlogic-boot-fip = fetchgit {
    url = "https://github.com/LibreELEC/amlogic-boot-fip.git";
    rev = "7ff0004e0e4d261ba81334a2f46302bd06704aca";
    sha256 = "083y64qbqrsrxr7a51k7943i4vnwk2vp5fflyqwhvg6w5kcqy3im";
  };
in
buildUBoot {
  defconfig = "beelink-gtking_defconfig";
  extraMeta.platforms = [ "aarch64-linux" ];
  filesToInstall = ["fip/u-boot.bin.sd.bin" "u-boot.bin"];

  # From https://u-boot.readthedocs.io/en/latest/board/amlogic/beelink-gtking.html
  postBuild = ''
    mkdir fip
    cp ${amlogic-boot-fip}/beelink-s922x/* fip/
    cp u-boot.bin fip/bl33.bin
    sh fip/blx_fix.sh \
      fip/bl30.bin \
      fip/zero_tmp \
      fip/bl30_zero.bin \
      fip/bl301.bin \
      fip/bl301_zero.bin \
      fip/bl30_new.bin \
      bl30

    sh fip/blx_fix.sh \
      fip/bl2.bin \
      fip/zero_tmp \
      fip/bl2_zero.bin \
      fip/acs.bin \
      fip/bl21_zero.bin \
      fip/bl2_new.bin \
      bl2

    fip/aml_encrypt_g12b --bl30sig --input fip/bl30_new.bin \
                          --output fip/bl30_new.bin.g12a.enc \
                          --level v3

    fip/aml_encrypt_g12b --bl3sig --input fip/bl30_new.bin.g12a.enc \
                            --output fip/bl30_new.bin.enc \
                            --level v3 --type bl30

    fip/aml_encrypt_g12b --bl3sig --input fip/bl31.img \
                            --output fip/bl31.img.enc \
                            --level v3 --type bl31

    fip/aml_encrypt_g12b --bl3sig --input fip/bl33.bin --compress lz4 \
                            --output fip/bl33.bin.enc \
                            --level v3 --type bl33

    fip/aml_encrypt_g12b --bl2sig --input fip/bl2_new.bin \
                            --output fip/bl2.n.bin.sig

    fip/aml_encrypt_g12b --bootmk \
            --output fip/u-boot.bin \
            --bl2 fip/bl2.n.bin.sig \
            --bl30 fip/bl30_new.bin.enc \
            --bl31 fip/bl31.img.enc \
            --bl33 fip/bl33.bin.enc \
            --ddrfw1 fip/ddr4_1d.fw \
            --ddrfw2 fip/ddr4_2d.fw \
            --ddrfw3 fip/ddr3_1d.fw \
            --ddrfw4 fip/piei.fw \
            --ddrfw5 fip/lpddr4_1d.fw \
            --ddrfw6 fip/lpddr4_2d.fw \
            --ddrfw7 fip/diag_lpddr4.fw \
            --ddrfw8 fip/aml_ddr.fw \
            --level v3
  '';
}
