## tecff-button-bind

Mit diesem Package können dem Wifi-Taster des Routers andere Aufgaben zugewiesen werden.
Diese können über den Router-Konfigurationsmodus oder auf der Konsole per `uci` gesetzt werden.

![screenshot](https://user-images.githubusercontent.com/1591563/43073047-7ee14e88-8e78-11e8-8046-a6d1412bd6db.png)

Das Package passt die Funktionalität des Wifi-Tasters über das Skript `/etc/rc.button/rfkill` an.

Bereits bestehende Einstellungen werden nicht überschrieben, zudem wird im Falle von schon vor der
Installation deaktivierten Wifi-Interfaces die Original-Funktion des Tasters beibehalten.

Über die Konsole wird die Funktionalität wie folgt eingestellt, wobei X für eine Funktionsziffer steht:
`uci set button-bind.wifi.function=X; uci commit button-bind`

Es stehen folgende Tasterfunktionalitäten zur Verfügung:

0. WLAN an/aus
1. Keine Funktion **(default)**
2. WLAN-Reset
3. Nachtmodus 1, alle Status-LEDs an/aus
4. Nachtmodus 2, aber während Taster-Betätigung an
5. Client-Netz an/aus
6. Mesh-VPN aus für 5 Stunden

Bei Option 3. startet der Knoten immer im Nachtmodus. Dies funktioniert auch bei
Geräten, die keinen Taster haben. Ohne Taster gelingt es nur im Konfigurationsmodus oder
auf der Konsole, die LEDs zu aktivieren.

Bei Option 5. bleibt das Mesh-Netz aktiv, sodass der Router weiter mit der
lokalen Wolke und eventuellen Gateways über das Mesh-VPN mesht.

Bei Option 6. schaltet sich das Mesh-VPN nach 5 Stunden automatisch wieder ein.
Man kann durch nochmaliges Drücken diesen Timer abbrechen und das Mesh-VPN
sofort wieder einschalten.
