include $(TOPDIR)/rules.mk

PKG_NAME:=tecff-general-workaround
PKG_VERSION:=1
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/tecff-general-workaround
  SECTION:=tecff
  CATEGORY:=Customization
  TITLE:=general workaround
  DEPENDS:=+gluon-core +micrond
endef

define Build/Prepare
        mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/tecff-general-workaround/install
        $(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,tecff-general-workaround))
