# Data LK8000 pro CZ piloty (kluzáky i letouny)

--------------------------------------------------------------------------------

## Mapy

* Soubory map jsou velké - určené pro telefony s Androidem (na starých PDA nebudou fungovat)
* Mapy jsou vytvořené z OpenStreetMap, licence k datům dle "Open Data Commons
  Open Database License", viz <https://www.openstreetmap.org/copyright>

<!-- -->

* `_Maps/*.dem` je topografie území, tj. výšky terénu
    * číslo `100m`, `200m` v názvu označuje rozlišení (přesnost)
* `_Maps/*.lkm` jsou topologie (řeky, silnice, koleje, města)
    * Oproti automaticky generovaným souborům dostupným na internetu je tento
      soubor upraven tak, aby lépe zobrazoval zastavěné plochy měst, přesněji
      zobrazoval silnice a koleje apod.


## Vzdušné prostory

* `_Airspaces\CZ-2014-border` hranice CZ
* `_Airspaces\CZFL95-2020.txt` vzdušné prostory CZ pro GA do FL95 (bez PGZ, ATZ) (autor Petr Koutný)
* `_Airspaces\CZ-WPA-2020.txt` vzdušné prostory CZ + SK vztahující se k některým waypointům
    * Pro tyto prostory jsou využity třídy "A" a "B", které se v ČR jinak nepoužívají
      a v LK8000 lze selektivně zakázat jejich zobrazování na mapě
    * Horní hranice těchto prostorů je 0 AGL, aby prostory nerušily v obrazovkách
      s bočním pohledem, LK8000 tedy nehlásí vstup do prostoru
    * AD - ATZ letišť; použita třída prostoru "A"
    * Heli - heliporty s ATZ; použita třída prostoru "A"
    * PGZ - prostory, kde bývá prováděn vzlet paraglidistů lanem; použita třída prostoru "B"
    * PG - informativně prostor s provozem paraglidingu, r=0.5NM; použita třída prostoru "B"
    * SLZ - informativně prostor ULL, r=1NM; použita třída prostoru "A"
* `_Airspaces\SK-2020.txt` prostory SK



## Otočné body

* Soubory jsou připraveny tak, aby byly na mapě body zobrazeny vhodným názvem s diakritikou
  ale aby šlo vyhledávat podle celého názvu bez diakritky (v LK8000 nelze zadávat diakritiku)
* V LK8000 **nastavit zobrazení waypoints pomocí ICAO kódu**
  (systémová nastavení č. `3 Zobrazení mapy`, `Názvy` = `ICAO Code`)
* Soubory obsahují i některé body pro Slovensko

<!-- -->

* `_Waypoints\CZ-WPN-2020.txt` - poznámky k bodům (frekvence, dráhy, okruhy apod.)
* `_Waypoints\CZ-WPT-ADPG-2020.cup` - letiště, ULL a nouzové plochy, PG prostory
    * AD (LKxxx) - na mapě označeny ICAO kódem a ATZ zónou třídy A poloměru 3NM
    * SLZ (LKxxxx) - na mapě označeny zkrác. názvem a zónou třídy B poloměru 1NM
    * SLZ negarantované (LKxxxx) - na mapě označeny zkrác. názvem a zónou třídy B poloměru 1NM
    * Nouzové plochy (ULxxxx) - na mapě označeny zkrác. názvem
    * Heliporty - na mapě označeny křížkem a písmenem "H"
    * PGZ plochy - na mapě označeny křížkem a písmeny "PGZ" a zónou třídy B poloměru 1NM
    * PG plochy - na mapě označeny křížkem a zónou Class B poloměru 0.5NM
    * Para provoz na letištích - na mapě označeny křížkem a znaky "P!"
* `_Waypoints\CZ-WPT-ObstHill-2020.cup` - vysoké překážky, vrcholy kopců
    * Překážky - na mapě označeny věží s červenou špičkou bez názvu (vysílač)
    * Vrcholy - na mapě označeny trojúhelníkem
* `_Waypoints\CZ-WPT-Other-2020.cup`    - další body
    * Otočné, hory, přehrady, kostely, křižovatky apod. - na mapě označeny zkrác. názvem
* `_Waypoints\CZ-WPT-VFRVOR-2020.cup`   - VOR, DME, NDB, hlásné body VFR, významné body IFR
    * VFR hlásné body - na mapě označeny názvem a 2 posledními písmeny ICAO kódu CTR
    * IFR body - na mapě označeny názvem
    * DME/VOR/NDB majáky - na mapě označeny identifikačním kódem


--------------------------------------------------------------------------------

## Změny

* 07.08.2020 - první vydání
