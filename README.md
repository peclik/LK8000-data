[//]: # (coding:utf-8)

# Data LK8000 pro CZ piloty (kluzáky i letouny)

--------------------------------------------------------------------------------

## Stažení

* <https://github.com/peclik/LK8000-data/releases>

## Mapy

* Soubory map jsou velké - určené pro telefony s Androidem (na starých PDA nebudou fungovat)
* Mapy jsou vytvořené z OpenStreetMap podkladů

<!-- -->

* `_Maps/*.lkm` jsou topologie (řeky, silnice, koleje, města, vodní plochy, lesy)
    * Oproti automaticky generovaným souborům dostupným na internetu tento soubor:
      * věrněji zobrazuje zastavěné plochy měst
      * přesněji zobrazuje silnice a koleje apod.
      * zobrazuje lesní plochy a nadzemní elektrické vedení
    * Města jsou ve vrstvách
      * _Velká města_
      * _Střední města_
      * _Malá města_ - pro tuto vrstvu doporučuji nastavit _Úroveň přiblížení = **3.0**_
    * Vrstva **nadzemní elektrické vedení**
      * Používá nastavení vrstvy _**Menší města**_.
      * Pro tuto vrstvu doporučuji nastavit _Úroveň přiblížení Menší města = **0.5**_
    * Vrstva **lesní plochy** je zobrazena šrafovaně.
      * Nastavení _Úrovně přiblížení_ sdílí s vrstvou _Střední města_.
    * Vrstva **názvy vodních ploch**.
      * Nastavení _Úrovně přiblížení_ sdílí s vrstvou _Malá města_.
    * _Úroveň přiblížení_ se pro vrstvy nastavuje v LK8000 v nabídce:
      _Nastavení 2/3 => Nastavení LK8000 => Nastavení systému Nastavení 4 Zobrazení Terénu => Nastavit topologii_
    * Další nastavení vrstvev (změna barev, schování vrstvy) je možné ruční úpravou souboru `topology.tpl`.
      Soubor `.lkm` je `.zip` archív a v něm se nachází `topology.tpl`.
* `_Maps/*.dem` je topografie území, tj. výšky terénu
    * číslo `100m`, `200m` v názvu označuje rozlišení (přesnost)


## Vzdušné prostory

* `_Airspaces\CZ-2014-border` hranice CZ
* `_Airspaces\CZFL95.txt` vzdušné prostory CZ pro GA do FL95 (bez PGZ, ATZ) (autor Petr Koutný)
* `_Airspaces\CZ-WPA.txt` vzdušné prostory CZ + SK vztahující se k některým waypointům
    * Pro tyto prostory jsou využity třídy "A" a "B", které se v ČR jinak nepoužívají
      a v LK8000 lze selektivně zakázat jejich zobrazování na mapě
    * Horní hranice těchto prostorů je 0 AGL, aby prostory nerušily v obrazovkách
      s bočním pohledem, LK8000 tedy nehlásí vstup do prostoru
    * AD - ATZ letišť; použita třída prostoru "A"
    * Heli - heliporty s ATZ; použita třída prostoru "A"
    * PGZ - prostory, kde bývá prováděn vzlet paraglidistů lanem; použita třída prostoru "B"
    * PG - informativně prostor s provozem paraglidingu, r=0.5NM; použita třída prostoru "B"
    * SLZ - informativně prostor ULL, r=1NM; použita třída prostoru "A"
* `_Airspaces\SK-LZBB.txt` prostory SK (Ján Hrnčírik)



## Otočné body

* Soubory jsou připraveny tak, aby byly na mapě body zobrazeny vhodným názvem s diakritikou
  ale aby šlo vyhledávat podle celého názvu bez diakritky (v LK8000 nelze zadávat diakritiku)
* V LK8000 **nastavit zobrazení waypoints pomocí ICAO kódu**
  (systémová nastavení č. `3 Zobrazení mapy`, `Značky` = `ICAO Code`)
* Soubory obsahují i některé body pro Slovensko

<!-- -->

* `_Waypoints\CZ-WPN.txt` - poznámky k bodům (frekvence, dráhy, okruhy apod.)
* `_Waypoints\CZ-WPT-ADPG.cup` - letiště, ULL a nouzové plochy, PG prostory
    * AD (LKxxx) - na mapě označeny ICAO kódem a ATZ zónou třídy A poloměru 3NM
    * SLZ (LKxxxx) - na mapě označeny zkrác. názvem a zónou třídy B poloměru 1NM
    * SLZ negarantované (LKxxxx) - na mapě označeny zkrác. názvem a zónou třídy B poloměru 1NM
    * Nouzové plochy (ULxxxx) - na mapě označeny zkrác. názvem
    * Heliporty - na mapě označeny křížkem a písmenem "H"
    * PGZ plochy - na mapě označeny křížkem a písmeny "PGZ" a zónou třídy B poloměru 1NM
    * PG plochy - na mapě označeny křížkem a zónou Class B poloměru 0.5NM
    * Para provoz na letištích - na mapě označeny křížkem a znaky "P!"
* `_Waypoints\CZ-WPT-ObstHill.cup` - vysoké překážky, vrcholy kopců
    * Překážky - na mapě označeny věží s červenou špičkou bez názvu (vysílač)
    * Vrcholy - na mapě označeny trojúhelníkem
* `_Waypoints\CZ-WPT-Other.cup`    - další body
    * Otočné, hory, přehrady, kostely, křižovatky apod. - na mapě označeny zkrác. názvem
* `_Waypoints\CZ-WPT-VFRVOR.cup`   - VOR, DME, NDB, hlásné body VFR, významné body IFR
    * VFR hlásné body - na mapě označeny názvem a 2 posledními písmeny ICAO kódu CTR
    * IFR body - na mapě označeny názvem
    * DME/VOR/NDB majáky - na mapě označeny identifikačním kódem


## Instalace do zařízení Android

* Datové soubory _LK8000_ jsou uloženy ve složce telefonu
  `Interní paměť/Android/data/org.lk8000/files`
* Datové soubory _LK8000 **Beta**_ jsou uloženy ve složce telefonu
  `Interní paměť/Android/data/org.lk8000.test/files`
* Datové soubory z toho balíku nakopírovat do příslušných podsložek
  `_Airspaces`, `_Maps`, `_Waypoints`.

--------------------------------------------------------------------------------

## Licence

* Mapy jsou vytvořené z OpenStreetMap, licence k datům dle "Open Data Commons
  Open Database License", viz <https://www.openstreetmap.org/copyright>


## Statistika stažení

* [1](https://tooomm.github.io/github-release-stats/?username=peclik&repository=LK8000-data)

## Změny

* 15.02.2025
  * Aktualizace .lkm
  * Přidány vrstvy lesů a nadzemního elektrického vedení
* 06.05.2021
  * Aktualizace bodů a informací dle AisView platných od 20.5.2021,
  * Vzdušné prostory CZ 25FEB21 (Petr Koutný)
  * Vzdušné prostory SK 6.5.2021 2021 (Ján Hrnčírik)
* 07.08.2020
  * První vydání
