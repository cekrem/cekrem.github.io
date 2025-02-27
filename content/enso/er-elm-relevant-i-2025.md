---
title: "Er Elm relevant i 2025?"
description: "En dypdykk i det funksjonelle programmeringsspråket som fortsatt har noe å lære oss"
tags: ["elm", "frontend", "funksjonell programmering", "arkitektur"]
date: 2025-03-XX
draft: true
---

## Hvorfor snakke om Elm i 2025?

I en verden dominert av React, Vue og Svelte kan det virke merkelig å løfte frem Elm – et nisje-språk som har eksistert siden 2012. Men nettopp nå, når frontend-utviklingen blir stadig mer kompleks, er det verdt å se nærmere på hva Elm gjør riktig.

### Paradigmskiftet: Færre muligheter gir bedre kode

Utviklingen fra strukturert programmering -> OOP -> funksjonell programmering kan sees som en serie med begrensninger som tvinger frem bedre praksis:

1. **Strukturert programmering** (1960-tallet) fjernet `goto` for å unngå "spaghetti-kode":

   ```c
   // Gammel C-kode med goto
   if (error) goto cleanup;  // Uforutsigbar flyt
   ```

   Edsger Dijkstra's "Go To Statement Considered Harmful" (1968) banet vei for `if/else` og løkker

2. **OOP** (1980-tallet) begrenset direkte tilgang til tilstand gjennom encapsulering:

   ```java
   // Uten encapsulering
   public class BankAccount {
       public double balance;  // Fare for direkte manipulasjon
   }

   // Med encapsulering
   private double balance;
   public void deposit(double amount) {  // Kontrollert endring
       if (amount > 0) balance += amount;
   }
   ```

3. **Funskjonell programmering** (LISP 1958, ML 1973) fjerner muterbar tilstand og side-effekter:

   ```javascript
   // Imperativ JavaScript
   let count = 0;
   count += 1; // Mutasjon!

   // Funksjonell tilnærming
   const newCount = count + 1; // Original count uendret
   ```

Elm tar dette siste skrittet radikalt ved å:

```elm
-- Eksempel på Elm som forbyr mutasjon
update : Model -> Model
update model =
    { model | count = model.count + 1 }  -- Returnerer NY modell, mutasjon er umulig

-- Kompilatoren vil stoppe deg hvis du prøver:
-- model.count = 5  ← Kompileringsfeil!
```

Dette minner om Rich Hickeys påstand om enkelthet gjennom begrensninger, og Bret Victors observasjon: "The most important property of a program is whether it is correct. The second most important is whether it can be changed without breaking its correctness."

### Frihet vs. produktivitet

Ironien er at ved å fjerne "frihet" (mutasjon, sideeffekter, runtime exceptions) får vi:

- **Enklere feilsøking**: Når data aldri muteres, elimineres heisen "Hvem endret denne verdien?"

  ```elm
  -- Elm's tilstandshåndtering
  initModel = { count = 0 }
  model1 = update initModel  -- { count = 1 }
  model2 = update model1     -- { count = 2 }
  -- initModel forblir uendret
  ```

- **Forutsigbar kode**: Pure funksjoner + immutable data = samme input gir samme output

  ```elm
  -- Elm-funksjoner er alltid pure
  sum : List Int -> Int  -- Gitt samme liste, alltid samme sum
  ```

- **Automatiserte refaktoreringer**: Kompilatoren finner alle steder som må oppdateres

  ```elm
  type Msg
      = OldMessage  -- Endrer til NewMessage
      ↓
      = NewMessage
  -- Kompilatoren viser alle case-mønstre som må oppdateres
  ```

- **Mindre kognitiv belastning**: Utvikleren trenger ikke holde hele tilstandshistorikk i hodet
  ```elm
  view : Model -> Html Msg  -- Kun gjeldende tilstand er relevant
  ```

Dette er ikke nytt - ML-språkene fra 70-tallet hadde mange av disse egenskapene. Men Elm gjør disse begrensningene praktiske for webutvikling i 2025 gjennom:

1. **Typeinferens** som reduserer boilerplate:

   ```elm
   -- Kompilatoren forstår at 1 og 2 er Int
   sum = 1 + 2  -- Ingen typeannotasjon nødvendig
   ```

2. **Interop med JavaScript**-økosystemet via ports:

   ```elm
   port module Main exposing (..)
   port toJS : String -> Cmd msg  -- Send data til JavaScript
   port fromJS : (String -> msg) -> Sub msg  -- Motta data
   ```

3. **Kompilator som lærer deg** gjennom menneskevennlige feilmeldinger:
   ```elm
   -- Hvis du glemmer en case i pattern matching:
   "This `case` does not have branches for all possibilities:
   Missing possibilities include: DataReceived (Err _)
   ```

## Hva er Elm?

Elm er et funksjonelt programmeringsspråk spesielt designet for webapplikasjoner. Nøkkelforskjeller fra moderne JavaScript-rammeverk:

- **Ingen(!) Runtime Exceptions** – Så lenge koden kan kompileres, kan koden kjøre
- **Fullstendig tilstandshåndtering** – Kompilatoren hjelper deg med alle grensetilfeller
- **Forutsigbar arkitektur** – The Elm Architecture (TEA) gir klar og forutsigbar struktur som skalerer utrolig bra
- **Semantisk versjonshåndtering** – Automatisk deteksjon av breaking changes

## SOLID by default

Det som fascinerer meg mest med Elm er hvordan det tvinger frem god arkitektur. La oss se på et eksempel:

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

Dette mønsteret, kjent som The Elm Architecture, implementerer mange av prinsippene vi kjenner fra Clean Architecture:

1. **Tydelig separasjon av ansvar** – View, Update og Model er helt separate
2. **Dependency Inversion** – All kommunikasjon går gjennom meldinger (Msg)
3. **Single Responsibility** – Hver funksjon har én jobb
4. **Open/Closed** – Ny funksjonalitet legges til ved å utvide, ikke modifisere

## Moderne frontend-utvikling trenger dette

I 2025 ser vi paradokset: Enklere verktøy, men mer komplekse applikasjoner. Elm adresserer utfordringene gjennom:

1. **Zero-config type safety** uten TypeScript-kompleksitet
2. **Automatisert refaktorering** takket være streng kompilator
3. **Isolerte side effects** som forenkler testing og debugging
4. **Felles arkitekturmønster** som reduserer teamdiskusjoner om struktur

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
