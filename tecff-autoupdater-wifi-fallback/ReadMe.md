tecff-autoupdater-wifi-fallback
==============================

If a node has no connection to the mesh, neither via wlan-mesh nor via
mesh-vpn, it ist not possible to update this node via `autoupdater`. Therefor
the *wifi-fallback* was developed. It checks hourly whether the node is part of
a fully operative mesh or not. Else the node connects to a visible "Freifunknetz"
and tries downloads an update as wlan-client via executing `autoupdater -f`.

Actually this needs `iw connect` patched into `iw`. See the patch at ffho
[site repository](https://git.c3pb.de/freifunk-pb/site-ffho) or in tecff's gluon.

/etc/config/autoupdater-wifi-fallback
-------------------------------------

**autoupdater-wifi-fallback.settings.enabled:**
- `0` disables the fallback mode
- `1` enables the fallback mode

### example
```
config autoupdater-wifi-fallback 'settings'
	option enabled '1'
```
