include $(TOPDIR)/rules.mk

PKG_NAME:=tecff-treatment
PKG_VERSION:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/tecff-treatment
  SECTION:=gluon
  CATEGORY:=Gluon
  TITLE:=treatment
  DEPENDS:=+gluon-core
endef

define Build/Prepare
        mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/tecff-treatment/install
        $(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,tecff-treatment))

