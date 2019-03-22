include $(TOPDIR)/rules.mk

PKG_NAME:=ffffm-button-bind
PKG_VERSION:=2
PKG_RELEASE:=1

include $(TOPDIR)/../package/gluon.mk

define Package/$(PKG_NAME)
  MAINTAINER:=Freifunk Frankfurt and Kiel
  TITLE:=Bind a router button to a feature set
  DEPENDS:=+gluon-web-admin
endef

define Build/Prepare
	$(call Gluon/Build/Prepare)
	$(CP) gluonShellDiet.sh $(PKG_BUILD_DIR)/gluonShellDiet.sh
endef

define ShellSrcDiet
	rm -rf $(2)
	$(CP) $(1) $(2)
	$(FIND) $(2) -type f | while read src; do \
		$(PKG_BUILD_DIR)/gluonShellDiet.sh "$$$$src" > "$$$$src.o"; \
		chmod $$$$(stat -c%a "$$$$src") "$$$$src.o"; \
		mv "$$$$src.o" "$$$$src"; \
	done
endef

define Build/Compile
	$(call Gluon/Build/Compile)
	$(call ShellSrcDiet,shsrc,$(PKG_BUILD_DIR)/shdest/)
endef

define Package/ffffm-button-bind/install
	$(Gluon/Build/Install)
	$(CP) $(PKG_BUILD_DIR)/shdest/. $(1)/
endef

$(eval $(call BuildPackageGluon,$(PKG_NAME)))
