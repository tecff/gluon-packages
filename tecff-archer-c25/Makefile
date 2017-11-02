include $(TOPDIR)/rules.mk

PKG_NAME:=tecff-archer-c25
PKG_VERSION:=1
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(TOPDIR)/../package/gluon.mk

define Package/tecff-archer-c25
  SECTION:=gluon
  CATEGORY:=Gluon
  TITLE:=Archer C25 custom package
  DEPENDS:=+gluon-core +gluon-site +lua-simple-uci
endef

define Package/tecff-archer-c25/description
	Disables 5 GHz Wifi Interfaces by default as the firmware is buggy. Can still be enabled manually.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
	$(call GluonSrcDiet,./luasrc,$(PKG_BUILD_DIR)/luadest/)
endef

define Package/tecff-archer-c25/install
	$(CP) $(PKG_BUILD_DIR)/luadest/* $(1)/
endef

$(eval $(call BuildPackage,tecff-archer-c25))
