# AS02MC04 Vivado Project Template

## Workflow

Das Template nutzt Vivado Project Mode, aber das Projekt wird vollständig aus Tcl erzeugt. Die GUI ist nur zum Untersuchen und Debuggen gedacht. Änderungen in der GUI sind nicht persistent, solange sie nicht in `rtl/`, `constraints/`, `ip/` oder `scripts/` übernommen werden.

Ein frischer Build muss aus dem Repository-Root reproduzierbar sein:

```bash
make clean
make bit
```

Alle generierten Dateien landen per Default unter `~/build/<PROJECT_NAME>/`. Vivado-Logs und Journals werden ebenfalls nach `BUILD/logs/` geschrieben.

## Make-Targets

- `make help`: zeigt Targets und Variablen
- `make project`: erzeugt/aktualisiert das Vivado-Projekt unter `BUILD`
- `make gui`: öffnet das generierte Projekt in der Vivado-GUI
- `make synth`: startet Synthese, schreibt `BUILD/checkpoints/<TOP>_synth.dcp` und Synthese-Reports
- `make impl`: startet Implementation bis Route, schreibt `BUILD/checkpoints/<TOP>_impl.dcp` und Reports
- `make bit`: startet Implementation inklusive Bitstream und kopiert den fertigen Bitstream nach `BUILD/output/<TOP>.bit`
- `make reports`: schreibt Reports aus vorhandenen Runs neu
- `make probe`: öffnet nur Hardware Manager, verbindet `hw_server`, setzt den JTAG-Takt und listet Devices/Properties
- `make program`: lädt einen vorhandenen Bitstream flüchtig per JTAG, nur mit `CONFIRM=1`
- `make clean`: entfernt den konfigurierten `BUILD`-Ordner und übliche Vivado-Artefakte im Repository-Root

## Make-Variablen

Defaults stehen im `Makefile`. Projektwerte stehen versioniert in `project.mk`; downstream Projekte sollen dort z.B. `TOP`, `PART`, `BOARD_PART` oder LED-Overrides ändern. Maschinen- oder Nutzerwerte wie ein lokaler Vivado-Pfad gehören in ein nicht versioniertes `local.mk`, das von Git ignoriert wird. Variablen auf der Kommandozeile haben weiterhin Vorrang.

```make
VIVADO ?= vivado
PROJECT_NAME ?= $(notdir $(REPO_ROOT))
BUILD ?= $(HOME)/build/$(PROJECT_NAME)
JOBS ?= 32
TOP ?= top
BOARD_PART ?= tiferking.cn:as02mc04:part0:1.0
PART ?= xcku3p-ffvb676-1-e
HW_FREQ ?= 1000000
BOARD_CONSTRAINTS ?= 1
LED_IOSTANDARD ?= BOARD
BOARD_AUTO_PORTS ?= 1
BOARD_AUTO_IOSTANDARD ?= NONE
```

Beispiel fuer `local.mk`:

```make
VIVADO := /opt/AMD/2025.2.1/Vivado/bin/vivado
JOBS := 32
```

Beispiele:

```bash
make bit PART=xcku3p-ffvb676-2-e JOBS=8
make gui BUILD=$HOME/build/fpga-debug
make probe HW_FREQ=750000
make project BOARD_CONSTRAINTS=0
make bit LED_IOSTANDARD=LVCMOS33
make program CONFIRM=1
```

`JOBS` setzt in den Tcl-Skripten `general.maxThreads`. Vivado 2025.2.1 akzeptiert lokal maximal `32`; höhere Werte wie `JOBS=128` werden mit Hinweis auf `32` gedeckelt.

`BOARD_CONSTRAINTS=1` erzeugt beim Projektaufbau `BUILD/generated/as02mc04_board.xdc` aus dem installierten Vivado-Boardfile. Die Projektzuordnung von Board-Pins auf RTL-Ports steht in `constraints/board_ports.tcl`; der generische Generator `scripts/board_constraints.tcl` sollte fuer normale Projekte nicht editiert werden. `LED_IOSTANDARD=BOARD` übernimmt den Wert aus dem Boardfile, `LED_IOSTANDARD=NONE` laesst den LED-I/O-Standard weg, und ein expliziter Wert wie `LVCMOS33` überschreibt ihn für die LED-Ports.

`BOARD_AUTO_PORTS=1` pinnt zusätzliche Top-Level-Ports automatisch, wenn deren Name exakt einem Board-Pin aus `part0_pins.xml` entspricht, z.B. `SFP_1_MOD_DEF_0` oder `pcie_perstn_rst`. Per Default setzt `BOARD_AUTO_IOSTANDARD=NONE` für diese automatisch erkannten Ports keinen I/O-Standard, weil sich die Quellen bei einigen SFP/I2C/Reset-Signalen widersprechen. Wenn du dem installierten Boardfile bewusst folgen willst, kannst du `BOARD_AUTO_IOSTANDARD=BOARD` setzen. Die generierte XDC enthält außerdem einen kommentierten Pinout-Katalog aller Board-Pins.

## Wo Projektanpassungen Hingehören

- `project.mk`: versionierte Projektparameter wie `TOP`, `BUILD`, `PART`, `BOARD_PART` und Constraint-Optionen.
- `local.mk`: nicht versionierte Maschinenwerte wie ein lokaler Vivado-Pfad oder persönliche `JOBS`.
- `rtl/`: dein HDL.
- `ip/`: versionierte XCI/IP-Quellen.
- `constraints/board_ports.tcl`: Board-Pin-zu-RTL-Port-Mapping. Hier ergänzt du neue Ports, wenn deine RTL-Namen nicht exakt den Board-Pin-Namen entsprechen.
- `constraints/as02mc04.xdc`: zusätzliche XDC-Constraints, Timing-Ausnahmen oder bewusste Overrides nach Hardwareprüfung.
- `scripts/board_constraints.tcl`: Template-Infrastruktur. Diese Datei liest das installierte Boardfile, ruft `constraints/board_ports.tcl` auf, ergänzt optional exakte Auto-Port-Matches und schreibt den kommentierten Pinout-Katalog.

Die Demo-Mappings in `constraints/board_ports.tcl` sind absichtlich optional. Wenn ein neues Projekt keine `led`-Ports oder keinen `clk_100mhz_p`-Port mehr hat, werden diese Constraints beim Generieren übersprungen; du musst sie also nicht zuerst herauswerfen.

## Speedgrade `-1-e` vs `-2-e`

Die Quellen sind nicht einheitlich: `TiferKing/as02mc04_hack` beschreibt im Board-File `xcku3p-ffvb676-2-e`, waehrend `dkozel/Alibaba-Cloud-FPGA` `xcku3p-ffvb676-1-e` nennt. Per AMD Device DNA wurde fuer diese Karte Speedgrade `1E` ermittelt. Deshalb ist `PART` bewusst als Make-Variable vorgesehen. Der Default ist `xcku3p-ffvb676-1-e`, kann aber pro Karte überschrieben werden.

## Constraints Und Offene Pinout-Punkte

Aktiv verwendet werden standardmäßig nur Clock- und LED-Pins, die im installierten Boardfile eindeutig belegt sind und deren RTL-Ports im Design existieren. Diese Demo-Zuordnung steht in `constraints/board_ports.tcl`. Die konkrete XDC wird bei `make project` nach `BUILD/generated/as02mc04_board.xdc` geschrieben. `constraints/as02mc04.xdc` bleibt für lokale Overrides reserviert.

| Signal | Pin | Aktiver Constraint | Quellen |
| --- | --- | --- | --- |
| `clk_100mhz_p` | E18 | `PACKAGE_PIN`, `IOSTANDARD LVDS`, 10 ns Clock | installierter TiferKing Board-Part `part0_pins.xml`; bestätigt durch Essenceia |
| `clk_100mhz_n` | D18 | `PACKAGE_PIN`, `IOSTANDARD LVDS` | installierter TiferKing Board-Part `part0_pins.xml`; bestätigt durch Essenceia |
| `led[0]` / `GPIO_LED_R` | A13 | `PACKAGE_PIN`, default `IOSTANDARD LVCMOS18`, `DRIVE 8`, `SLEW SLOW` | installierter TiferKing Board-Part `part0_pins.xml` |
| `led[1]` / `GPIO_LED_G` | A12 | `PACKAGE_PIN`, default `IOSTANDARD LVCMOS18`, `DRIVE 8`, `SLEW SLOW` | installierter TiferKing Board-Part `part0_pins.xml` |
| `led[2]` / `GPIO_LED_H` | B9 | `PACKAGE_PIN`, default `IOSTANDARD LVCMOS18`, `DRIVE 8`, `SLEW SLOW` | installierter TiferKing Board-Part `part0_pins.xml` |
| `led[3]` / `GPIO_LED_1` | B11 | `PACKAGE_PIN`, default `IOSTANDARD LVCMOS18`, `DRIVE 8`, `SLEW SLOW` | installierter TiferKing Board-Part `part0_pins.xml`; bestätigt durch Essenceia |
| `led[4]` / `GPIO_LED_2` | C11 | `PACKAGE_PIN`, default `IOSTANDARD LVCMOS18`, `DRIVE 8`, `SLEW SLOW` | installierter TiferKing Board-Part `part0_pins.xml`; bestätigt durch Essenceia |
| `led[5]` / `GPIO_LED_3` | A10 | `PACKAGE_PIN`, default `IOSTANDARD LVCMOS18`, `DRIVE 8`, `SLEW SLOW` | installierter TiferKing Board-Part `part0_pins.xml`; bestätigt durch Essenceia |
| `led[6]` / `GPIO_LED_4` | B10 | `PACKAGE_PIN`, default `IOSTANDARD LVCMOS18`, `DRIVE 8`, `SLEW SLOW` | installierter TiferKing Board-Part `part0_pins.xml`; bestätigt durch Essenceia |

Offene Unsicherheit: Essenceia und TiferKing nennen für die LEDs `LVCMOS18`; Chester Gillon dokumentiert später eine Korrektur auf `LVCMOS33` nach VCCO-Messung mit SYSMON. Der Default folgt dem installierten Boardfile (`LED_IOSTANDARD=BOARD`). Wenn deine Karte tatsächlich `LVCMOS33` für die LED-Bank braucht, baue mit `LED_IOSTANDARD=LVCMOS33` oder lege einen Override in `constraints/as02mc04.xdc` ab.

## Checkpoints In Der GUI Oeffnen

Nach `make synth`:

```bash
vivado ~/build/<PROJECT_NAME>/checkpoints/top_synth.dcp
```

Nach `make impl` oder `make bit`:

```bash
vivado ~/build/<PROJECT_NAME>/checkpoints/top_impl.dcp
```

Alternativ:

```bash
make gui
```

Dann in Vivado den passenden Run oder Checkpoint untersuchen. Relevante Aenderungenen danach in RTL, XDC oder Tcl übernehmen.

## Neues Projekt Aus Dem Template Starten

1. Repository kopieren oder als Template verwenden.
2. Projektwerte in `project.mk` setzen, insbesondere `TOP`, `PART`, `BOARD_PART` und gewuenschte Constraint-Optionen.
3. Eigene RTL-Dateien unter `rtl/` ablegen.
4. Neue Board-Pin-Mappings in `constraints/board_ports.tcl` ergänzen oder Top-Level-Ports exakt wie die Board-Pins benennen und `BOARD_AUTO_PORTS=1` nutzen.
5. Zusätzliche freie XDC-Constraints in `constraints/as02mc04.xdc` eintragen.
6. Boardfile installieren oder `BOARD_CONSTRAINTS=0` setzen und eigene Constraints pflegen.
7. Eigene XCI-Dateien unter `ip/` ablegen.
8. Mit `make clean && make synth` prüfen.
9. Erst nach geklärten I/O-Standards und DRC mit `make bit` bauen.

Fuer template-freundliche Merges: halte projektbezogene Einstellungen in `project.mk`, Board-Mappings in `constraints/board_ports.tcl` und lokale Pfade in `local.mk`. Aenderungen am Build-System sollten moeglichst in `Makefile` oder `scripts/` landen; diese Commits koennen dann per `cherry-pick` zurueck ins Template und von dort wieder in andere Projekte gemerged werden.

## Hardware-Zugriff

`make probe` ist nicht destruktiv. Es öffnet den Hardware Manager, verbindet `hw_server`, öffnet das lokale JTAG-Target, setzt `HW_FREQ` und gibt erkannte Devices plus Properties aus. Es programmiert nichts.

`make program CONFIRM=1` programmiert ausschliesslich die flüchtige FPGA-Konfiguration eines erkannten XCKU3P-Devices mit `BUILD/output/<TOP>.bit`.

## Keine Flash-Programmierung

Flash-Programmierung ist absichtlich nicht implementiert. Dieses Template legt keine Configuration-Memory-Objekte an, schreibt keinen QSPI-Flash und enthält kein Target dafür. `program` ist nur für volatile JTAG-Konfiguration gedacht.

## Quellen

- Essenceia: <https://essenceia.github.io/projects/alibaba_cloud_fpga/>
- dkozel: <https://github.com/dkozel/Alibaba-Cloud-FPGA>
- TiferKing: <https://github.com/TiferKing/as02mc04_hack>
- Chester Gillon: <https://gist.github.com/Chester-Gillon/765d6286b1c34c7dc26a7b4c4dd0c48c>
