---
title: "Er Elm relevant i 2025?"
description: "En dypdykk i det funksjonelle programmeringsspråket som fortsatt har noe å lære oss"
tags: ["elm", "frontend", "funksjonell programmering", "arkitektur"]
date: 2025-03-XX
draft: true
---

## Hvorfor snakke om Elm i 2025?

I en verden dominert av React, Vue og Svelte kan det virke merkelig å løfte frem Elm – et nisje-språk som har eksistert siden 2012, men som nesten har færre releases siden da enn React har på et år. Men nettopp nå, når frontend-utviklingen blir stadig mer kompleks, er det verdt å se nærmere på hva Elm gjør riktig.

### Paradigmeutvikling: Å ta vekk muligheter for å få mer kontroll

## 🏗 Før strukturert programmering – _"Full frihet, full kaos"_

Før 1960-tallet skrev utviklere ofte kode i en **rent imperativ stil**, hvor programmer besto av sekvenser av kommandoer med **GOTO-setninger** for hopp mellom ulike deler av programmet.

🔴 **Problem:** Koden ble vanskelig å forstå og vedlikeholde («spaghetti-kode»). Ingen garantier for at en sekvens av operasjoner var fornuftig, og feil ble uforutsigbare. "Undefined behaviour" ble en del av hverdagen, for å si det mildt.

---

## 📏 Strukturert programmering – _"Ingen flere vilkårlige hopp!"_

Dijkstra og andre datavitere på 1960-70-tallet argumenterte for at all programlogikk burde kunne uttrykkes gjennom **sekvenser, valg (if/while/switch) og løkker**. Dette gjorde programmer mer forutsigbare.

✂ **Fjernet:** GOTO
✅ **Resultat:** Klarere kontrollflyt, lettere å debugge

---

## 🏛 Objektorientert programmering (OOP) – _"Trygg polymorfisme!"_

OOP oppsto på 1980-90-tallet som en respons på behovet for mer fleksible og utvidbare systemer. Den største innovasjonen var kanskje ikke innkapsling av tilstand, men **trygg polymorfisme** gjennom grensesnitt og arv.

✂ **Fjernet:** Utrygge "pointers to functions" og hardkodede avhengigheter
✅ **Resultat:**

- **Dependency Inversion** – Høynivåmoduler kan nå avhenge av abstraksjoner, ikke konkrete implementasjoner
- **Plugin-arkitektur** – Systemer kan utvides uten å endre eksisterende kode
- **Testbarhet** – Avhengigheter kan enkelt byttes ut med mock-objekter

Før OOP måtte utviklere bruke farlige "pointers to functions" for å oppnå polymorfisme. OOP gjorde dette trygt og forutsigbart gjennom virtuelle funksjoner og grensesnitt.

---

## 🧩 Funksjonell programmering (FP) – _"Fjern mutabilitet og bivirkninger!"_

FP har riktignok røtter tilbake til 1950-tallet (Lisp), men fikk økt popularitet med språk som Haskell, Elm og moderne bruk i TypeScript og React. Målet er å eliminere **uventede bivirkninger**, sikre at funksjoner alltid gir samme output for samme input, og unngå delt tilstand. Jeg har valgt å se på det som neste (og siste) iterasjon på stigen mot å fjerne kaos.

✂ **Fjernet:**

- Mutabel tilstand
- Skjulte bivirkninger
- Objektorientert kompleksitet

✅ **Resultat:** Mer forutsigbar og testbar kode, men ofte brattere læringskurve.

---

## 🔄 Fellesnevner: Hver epoke har handlet om å fjerne feilbarlige friheter

1. **Strukturert programmering:** Fjernet vilkårlige hopp (GOTO)
2. **OOP:** Fjernet ukontrollert deling av tilstand
3. **FP:** Fjernet mutabilitet og skjulte side effects

Målet har alltid vært det samme: **Mindre kaos, mer kontroll**. 🔥

Dette er selvsagt en forenklet fremstilling av programmeringshistorien, men essensen er klar: **God kode handler ikke om maksimal frihet, men om velvalgte begrensninger.** De beste verktøyene hjelper oss å unngå feil, ikke bare å rette dem.

### Elm: Radikalt funksjonelt

Elm tar dette siste skrittet radikalt ved å gjøre immutabilitet obligatorisk:

```elm
-- Eksempel på Elm som forbyr mutasjon
update : Model -> Model
update model =
    { model | count = model.count + 1 }  -- Returnerer NY modell, mutasjon er umulig

-- Kompilatoren vil stoppe deg hvis du prøver:
-- model.count = 5  ← Kompileringsfeil!
```

Dette minner om Rich Hickeys påstand om enkelthet gjennom begrensninger, og Bret Victors observasjon: "The most important property of a program is whether it is correct. The second most important is whether it can be changed without breaking its correctness."

### Når begrensninger gir frihet

Ironisk nok gir Elms strenge begrensninger oss flere fordeler:

- **Enklere feilsøking**: Når data aldri endres, slipper du å lure på "hvem eller hva endret denne verdien?"

  ```elm
  -- Elm's tilstandshåndtering
  initModel = { count = 0 }
  model1 = update initModel  -- { count = 1 }
  model2 = update model1     -- { count = 2 }
  -- initModel forblir uendret
  ```

- **Forutsigbar kode**: Rene funksjoner + uforanderlige data = samme input gir alltid samme output

  ```elm
  -- Elm-funksjoner er alltid rene
  sum : List Int -> Int  -- Gitt samme liste, alltid samme sum
  ```

- **Tryggere refaktorering**: Kompilatoren finner alle steder som må oppdateres

  ```elm
  type Msg
      = OldMessage  -- Endrer til NewMessage
      ↓
      = NewMessage
  -- Kompilatoren viser alle case-mønstre som må oppdateres
  ```

- **Mindre mental belastning**: Du trenger ikke holde hele tilstandshistorikken i hodet
  ```elm
  view : Model -> Html Msg  -- Kun gjeldende tilstand er relevant
  ```

## Hva er Elm?

Elm er et funksjonelt programmeringsspråk spesielt designet for webapplikasjoner. Her er nøkkelforskjellene fra moderne JavaScript-rammeverk:

- **Ingen runtime-feil** – Når koden kompilerer, kan den kjøre uten uventede krasj
- **Fullstendig tilstandshåndtering** – Kompilatoren hjelper deg med alle grensetilfeller
- **Forutsigbar arkitektur** – The Elm Architecture (TEA) gir en klar struktur som skalerer godt
- **Automatisk versjonshåndtering** – Kompilatoren oppdager breaking changes

### Moderne fordeler i praksis

Elm gjør funksjonell programmering praktisk for webutvikling gjennom:

1. **Typeinferens** som reduserer boilerplate:

   ```elm
   -- Kompilatoren forstår at 1 og 2 er Int
   sum = 1 + 2  -- Ingen typeannotasjon nødvendig
   ```

2. **JavaScript-integrasjon** via ports:

   ```elm
   port module Main exposing (..)
   port toJS : String -> Cmd msg  -- Send data til JavaScript
   port fromJS : (String -> msg) -> Sub msg  -- Motta data
   ```

3. **Vennlige feilmeldinger** som lærer deg språket:
   ```elm
   -- Hvis du glemmer en case i pattern matching:
   "This `case` does not have branches for all possibilities:
   Missing possibilities include: DataReceived (Err _)
   ```

## SOLID by default

Det som fascinerer meg mest med Elm er hvordan det tvinger frem god arkitektur. Se på dette eksempelet:

```elm
type Msg
    = FetchData
    | DataReceived (Result Http.Error Data)
    | UserClicked Int

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchData ->
            ( { model | loading = True }
            , fetchDataCmd
            )

        DataReceived result ->
            case result of
                Ok data ->
                    ( { model | data = data, loading = False }
                    , Cmd.none
                    )

                Err _ ->
                    ( { model | error = True, loading = False }
                    , Cmd.none
                    )

        UserClicked id ->
            ( { model | selectedId = Just id }
            , Cmd.none
            )
```

Dette mønsteret, kjent som The Elm Architecture, implementerer mange av prinsippene fra Clean Architecture:

1. **Tydelig separasjon av ansvar** – View, Update og Model er helt separate
2. **Dependency Inversion** – All kommunikasjon går gjennom meldinger (Msg)
3. **Single Responsibility** – Hver funksjon har én jobb
4. **Open/Closed** – Ny funksjonalitet legges til ved å utvide, ikke modifisere

## Moderne frontend-utvikling trenger dette

I 2025 ser vi et paradoks: Verktøyene blir enklere, men applikasjonene blir mer komplekse. Elm adresserer dette gjennom:

1. **Typesikkerhet uten konfigurasjon** – Ingen kompliserte TypeScript-oppsett
2. **Trygg refaktorering** – Kompilatoren finner alle steder som må endres
3. **Isolerte sideeffekter** – Gjør testing og feilsøking enklere
4. **Felles arkitekturmønster** – Reduserer diskusjoner om kodestruktur

## Når bør du vurdere Elm?

Elm passer spesielt godt når:

1. Du bygger en kompleks frontend-applikasjon
2. Robusthet og vedlikeholdbarhet er kritisk
3. Du har mulighet til å trene opp teamet
4. Du starter et nytt prosjekt fra bunnen

## Utfordringene

La oss være ærlige om utfordringene også:

- Bratt læringskurve for utviklere vant til imperativ programmering
- Mindre økosystem enn React/Vue
- Færre utviklere tilgjengelig
- Kan være vanskelig å "selge inn" til beslutningstakere

## Konklusjon

Elms relevans i 2025 ligger ikke i markedsandeler, men som arkitektonisk kompass. Mange av dens prinsipper finner vi igjen i:

- React Server Components' isolering av effekter
- TypeScripts stadig strengere type-system
- Veksten av compile-time-verktøy som tRPC og Zod

Altså: det diverse "best-practices" oppfordrer den drevne utvikler til å legge vinn på, er en obligatorisk del av Elm. Visst kan (og bør!) du skrive funksjonell React med god arkitektur, sterke typer og isolerte side effects; med Elm får du ikke lov til noe annet.

## Ressurser for å komme i gang

- [Elm Guide](https://guide.elm-lang.org/) – Den offisielle guiden
- [Elm in Action](https://amzn.to/41z14kq) – En utmerket bok for å lære hvordan Elm fungerer i større applikasjoner
- [Elm Slack](https://elm-lang.org/community) – Et uvanlig hjelpsomt og åpent community
- [elm-spa](https://www.elm-spa.dev/) – For å bygge Single Page Applications
  - (Evt. mitt [hjemmesnekrede opplegg](https://github.com/cekrem/create-elm-live-app) fra gamledager, som gjør mye av det samme)
- [Elm Land](https://elm.land/) – Nytt meta-rammeverk (2024)
