include $(TOPDIR)/rules.mk

PKG_NAME:=tecff-domain-director
PKG_VERSION:=3
PKG_RELEASE:=1

include $(TOPDIR)/../package/gluon.mk

define Package/tecff-domain-director
  TITLE:=Domain-Director
  DEPENDS:=+gluon-core +luaposix
endef

define Package/tecff-domain-director/description
	Direct nodes into their corresponding mesh-domain based on their location.
endef

$(eval $(call BuildPackageGluon,tecff-domain-director))
