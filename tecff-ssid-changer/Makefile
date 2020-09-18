include $(TOPDIR)/rules.mk

PKG_NAME:=tecff-ssid-changer
PKG_VERSION:=1
PKG_RELEASE:=4

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/tecff-ssid-changer
  SECTION:=gluon
  CATEGORY:=Gluon
  TITLE:=SSID Changer
  DEPENDS:=+gluon-core +micrond
endef

define Build/Prepare
        mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/tecff-ssid-changer/install
        $(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,tecff-ssid-changer))

