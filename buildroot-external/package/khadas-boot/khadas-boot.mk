################################################################################
#
# Khadas AMLogic secure boot loader
#
################################################################################

KHADAS_BOOT_SOURCE = fip-$(KHADAS_BOOT_VERSION).tar.xz
KHADAS_BOOT_SITE = https://github.com/khadas/khadas-uboot/releases/download/tc
KHADAS_BOOT_LICENSE = GPL-2.0+
KHADAS_BOOT_LICENSE_FILES = Licenses/gpl-2.0.txt
KHADAS_BOOT_INSTALL_IMAGES = YES
KHADAS_BOOT_DEPENDENCIES = uboot host-python


ifeq ($(BR2_PACKAGE_KHADAS_BOOT_VIM1),y)
KHADAS_BOOT_VERSION = 251220

KHADAS_BOOT_BINS += u-boot.gxl

KHADAS_BOOT_FIP_DIR = $(@D)/VIM1

define KHADAS_BOOT_BUILD_CMDS
	# Implement signing u-boot.bin similar to how its done in
	# https://github.com/spikerguy/khadas-uboot/blob/master/packages/u-boot-mainline/package.mk
	#cp -r $(BUILD_DIR)/uboot-2021.04/fip $(@D)
	mkdir -p fip

	cp $(KHADAS_BOOT_FIP_DIR)/bl2.bin fip/
	cp $(KHADAS_BOOT_FIP_DIR)/acs.bin fip/
	cp $(KHADAS_BOOT_FIP_DIR)/bl21.bin fip/
	cp $(KHADAS_BOOT_FIP_DIR)/bl30.bin fip/
	cp $(KHADAS_BOOT_FIP_DIR)/bl301.bin fip/
	cp $(KHADAS_BOOT_FIP_DIR)/bl31.img fip/
	cp $(BINARIES_DIR)/u-boot.bin fip/bl33.bin


	$(KHADAS_BOOT_FIP_DIR)/blx_fix.sh \
		fip/bl30.bin \
		fip/zero_tmp \
		fip/bl30_zero.bin \
		fip/bl301.bin \
		fip/bl301_zero.bin \
		fip/bl30_new.bin \
		bl30

	$(HOST_DIR)/bin/python2 $(KHADAS_BOOT_FIP_DIR)/acs_tool.pyc \
		fip/bl2.bin \
		fip/bl2_acs.bin \
		fip/acs.bin \
		0

	$(KHADAS_BOOT_FIP_DIR)/blx_fix.sh \
		fip/bl2_acs.bin \
		fip/zero_tmp \
		fip/bl2_zero.bin \
		fip/bl21.bin \
		fip/bl21_zero.bin \
		fip/bl2_new.bin \
		bl2

	$(KHADAS_BOOT_FIP_DIR)/aml_encrypt_gxl --bl3enc --input fip/bl30_new.bin
	$(KHADAS_BOOT_FIP_DIR)/aml_encrypt_gxl --bl3enc --input fip/bl31.img
	$(KHADAS_BOOT_FIP_DIR)/aml_encrypt_gxl --bl3enc --input fip/bl33.bin
	$(KHADAS_BOOT_FIP_DIR)/aml_encrypt_gxl --bl2sig --input fip/bl2_new.bin \
		--output fip/bl2.n.bin.sig

	$(KHADAS_BOOT_FIP_DIR)/aml_encrypt_gxl --bootmk --output fip/u-boot.bin \
		--bl2 fip/bl2.n.bin.sig \
		--bl30 fip/bl30_new.bin.enc \
		--bl31 fip/bl31.img.enc \
		--bl33 fip/bl33.bin.enc

	cp -f fip/u-boot.bin.sd.bin  $(@D)/u-boot.gxl
endef

endif

define KHADAS_BOOT_INSTALL_IMAGES_CMDS
	$(foreach f,$(KHADAS_BOOT_BINS), \
			cp -dpf $(@D)/$(f) $(BINARIES_DIR)/
	)
endef

$(eval $(generic-package))
