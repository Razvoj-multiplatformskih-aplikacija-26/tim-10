# tim-10
ReelToMeal - Korisnici dele linkove do Instagram i TikTok videa iz kojih aplikacija izdvaja recepte i preporuke restorana u licne kolekcije, a urednici pre objave u javnom katalogu proveravaju predloge i spajaju duplikate.

# ReelToMeal

Sistem za cuvanje recepata i restorana iz kratkih videa. Korisnik u mobilnoj aplikaciji podeli link do Instagram ili TikTok videa, a sistem iz njega izdvaja recepte (sastojci, koraci, nutritivne vrednosti) ili preporuke restorana (lokacija, kuhinja, preporucena jela, cene). Ako video sadrzi vise stavki, svaka postaje poseban unos. Korisnik unose organizuje u kolekcije, dopunjuje ih licnim beleskama i fotografijama, vidi sacuvane restorane na mapi i od vise recepata pravi jednu listu za kupovinu.

Unosi koje korisnici predloze i urednici odobre cine zajednicki javni katalog restorana i recepata. Urednici iz backoffice aplikacije pregledaju predloge, spajaju duplikate i odrzavaju bazu namirnica iz koje se racunaju nutritivne vrednosti. Katalog je javno dostupan na vebu.

## Tim

| Ime i prezime | Broj indeksa | Grupa | GitHub nalog |
| --- | --- | --- | --- |
| Stefan Nestorovic | 85/24 | 413 | Stefn10 |
| Petar Andjelkovic | 134/24 | 413 | RoPesh |

## Zahtevi za temu

1. **Uloge.** Sistem koriste korisnici i urednici, sa razlicitim ovlascenjima: korisnik upravlja samo svojim unosima i kolekcijama i moze da predlozi unos za javni katalog, a urednik odobrava ili odbija predloge, spaja duplikate i uredjuje bazu namirnica.
2. **Stanja.** Unos prolazi kroz vise stanja: ceka analizu, u obradi je, ceka korisnikov pregled, sacuvan je ili analiza nije uspela; unos predlozen za katalog zatim ceka odluku urednika i i u zavisnosti od odluke moze biti objavljen ili odbijen.
3. **Pravila.** Korisnik moze da pokrene najviše 20 analiza dnevno, a unos koji je u obradi ne može da se menja. Isti restoran moze postojati samo jednom u javnom katalogu i isti video se analizira samo jednom; to zavisi od unosa drugih korisnika, pa konacno odlucuje server, koji drugi predlog istog restorana pripaja postojecem zapisu.
4. **Rad bez mreze.** Korisnik moze bez signala da sacuva link do videa, koji se salje na analizu tek kada se veza vrati, i da u prodavnici stiklira stavke liste za kupovinu.
5. **Posao za osoblje.** Urednici svakodnevno pregledaju red predloga i prijavljenih gresaka, porede moguce duplikate jedan pored drugog i odrzavaju bazu od nekoliko stotina namirnica sa nutritivnim vrednostima, sto je posao za veci ekran.
6. **Javni sadrzaj.** Objavljeni restorani i recepti, kao i pregledi po gradu i vrsti kuhinje (npr. „ramen restorani u Beogradu"), zanimaju i one koji nemaju aplikaciju, pa ima smisla da ih pronadju pretrazivaci. Licne beleske, potrosnja i fotografije korisnika ostaju privatne.

## Delovi sistema

| Deo | Korisnici | Tehnologija | Platforme |
| --- | --- | --- | --- |
| Mobilna aplikacija | korisnici | Flutter | Android, iOS |
| Backoffice | urednici | Flutter | Windows, veb |
| Javni veb | svi posetioci | Jaspr | pregledac |
| Server | ostali delovi sistema | Relic, PostgreSQL | Linux, Windows |
| Domenski paket | svi delovi sistema | Dart | sve |
