include $(TOPDIR)/rules.mk

PKG_NAME:=tecff-aptimeclock
PKG_VERSION:=3
PKG_RELEASE:=0

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/tecff-aptimeclock
  SECTION:=gluon
  CATEGORY:=Gluon
  TITLE:=Turn on/off client AP by cron
  DEPENDS:=+gluon-core +micrond
endef

define Build/Prepare
        mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/tecff-aptimeclock/install
        $(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,tecff-aptimeclock))

