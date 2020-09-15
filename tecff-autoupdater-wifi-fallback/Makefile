include $(TOPDIR)/rules.mk

PKG_NAME:=tecff-autoupdater-wifi-fallback
PKG_VERSION:=5

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)
PKG_BUILD_DEPENDS := respondd

include $(TOPDIR)/../package/gluon.mk

define Package/tecff-autoupdater-wifi-fallback
  SECTION:=tecff
  CATEGORY:=Customization
  TITLE:=Implements switching to fallback mode if we are cut off from the mesh
  DEPENDS:=+gluon-autoupdater +gluon-site +iw +libgluonutil +libiwinfo-lua +luabitop +luaposix +micrond
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(call Build/Compile/Default)
	$(call GluonSrcDiet,./luasrc,$(PKG_BUILD_DIR)/luadest/)
endef

define Package/tecff-autoupdater-wifi-fallback/install
	$(CP) ./files/* $(1)/
	$(CP) $(PKG_BUILD_DIR)/luadest/* $(1)/

	$(INSTALL_DIR) $(1)/lib/gluon/respondd
	$(CP) $(PKG_BUILD_DIR)/respondd.so $(1)/lib/gluon/respondd/autoupdater-wifi-fallback.so
endef

$(eval $(call BuildPackage,tecff-autoupdater-wifi-fallback))
