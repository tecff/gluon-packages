include $(TOPDIR)/rules.mk

PKG_NAME:=tecff-ebtables-net-rules
PKG_VERSION:=1
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/tecff-ebtables-net-rules
  SECTION:=tecff
  CATEGORY:=Customization
  TITLE:=net-specific ebtables rules to filter unreasonable L2 traffic.
  DEPENDS:=+gluon-core +gluon-ebtables
endef

define Package/tecff-ebtables-net-rules/description
	This package adds an additional layer-2 filter-ruleset to prevent traffic,
	which is not destined for any legitimate layer-3 specific target,
	from entering the network via the nodes.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/tecff-ebtables-net-rules/install
	$(INSTALL_DIR) $(1)/lib/gluon/ebtables/
	$(CP) ./files/lib/gluon/ebtables/100-tecff-net-chain $(1)/lib/gluon/ebtables/
	$(CP) ./files/lib/gluon/ebtables/110-tecff-net-allow-ipv4-space $(1)/lib/gluon/ebtables/
	$(CP) ./files/lib/gluon/ebtables/110-tecff-net-allow-ipv6-spaces $(1)/lib/gluon/ebtables/
	$(CP) ./files/lib/gluon/ebtables/400-add-tecff-net-chain $(1)/lib/gluon/ebtables/
endef

$(eval $(call BuildPackage,tecff-ebtables-net-rules))
