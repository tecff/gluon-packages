include $(TOPDIR)/rules.mk

PKG_NAME:=tecff-broken-wlan-workaround
PKG_VERSION:=4
PKG_RELEASE:=0

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/tecff-broken-wlan-workaround
  SECTION:=tecff
  CATEGORY:=Customization
  TITLE:=broken wlan workaround
  DEPENDS:=+gluon-core +gluon-state-check +micrond +tecff-general-workaround
endef

define Build/Prepare
        mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/tecff-broken-wlan-workaround/install
        $(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,tecff-broken-wlan-workaround))
