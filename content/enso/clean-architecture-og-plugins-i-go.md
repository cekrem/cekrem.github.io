---
title: "Et praktisk eksempel på Dependency Inversion i Go med Plugins"
description: "La oss sette Clean Architecture og SOLID-prinsipper på dagsorden igjen!"
tags: ["go", "golang", "arkitektur", "SOLID", "plugin"]
date: 2025-01-07
draft: true
---

## Dependency Inversion – en viktig del av SOLID

Jeg har nylig tatt en ny titt på [SOLID-prinsippene](//en.wikipedia.org/wiki/SOLID), og gravd meg litt lengre ned og inn enn jeg hadde planlagt. I programvarearkitekturens verden er det få prinsipper som har tålt tidens tann som disse, og personlig tenker jeg at "Dependency Inversion-prinsippet" er særlig sentralt – og dessverre ofte oversett i moderne applikasjoner. Denne artikkelen utforsker hvordan man kan etterleve dette prinsippet fullt ut ved hjelp av plugin-systemet i Go.

**Merk:** God arkitektur er langt mer enn enkeltestående SOLID-prinsipper. Men Dependency Inversion-prinsippet er et utmerket sted å starte!

## Dependency Inversion i et nøtteskall

Hva det betyr:

1. Høynivåmoduler (kjernefunksjonalitet) skal ikke være avhengig av lavnivåmoduler (detaljer). Begge skal være avhengig av abstraksjoner (interfaces eller abstrakte klasser).
2. Abstraksjoner skal ikke være avhengig av detaljer. Detaljer (konkrete implementasjoner) skal være avhengig av abstraksjoner.

Hvorfor det er viktig:

- Det gjør systemet mer fleksibelt og enklere å endre.
- Det reduserer koblingen mellom komponenter, noe som gjør koden mer vedlikeholdbar.
- Det gjør det enklere å teste komponenter i isolasjon.

I dag skal vi utforske hvordan Go sitt plugin-system gjør det mulig for oss å etterleve dette fullt ut i praksis. Vi tar for oss noe enkelt, nemlig et kommandolinjeverktøy som transformerer tekst fra StdIn til StdOut.

Den fullstendige koden for denne artikkelen finnes på [github.com/cekrem/go-transform](https://github.com/cekrem/go-transform).

## Forståelse av landskapet

Mens mange språk implementerer modularitet gjennom eksterne avhengigheter (som DLL-er i C# eller JAR-er i Java), er Go stolt av sin evne til å kompilere til en enkelt, selvstendig kjørbar fil. Denne tilnærmingen gir flere fordeler:

- Forenklet distribusjon og versjonshåndtering
- Eliminering av avhengighetskonflikter
- Redusert operasjonell kompleksitet

Nettopp dette med en "single executable binary" er en av tingene jeg liker best når jeg jobber med Go! Det finnes imidlertid scenarioer hvor en plugin-arkitektur blir verdifull – spesielt når du trenger å:

- Legge til funksjonalitet uten å rekompilere kjerneapplikasjonen
- Tillate tredjepartsutvidelser
- Isolere forskjellige komponenter for bedre vedlikeholdbarhet

Go tilbyr en innebygd løsning for disse tilfellene gjennom sin `plugin`-pakke. Selv om den er mindre kjent enn andre språks modulsystemer, tilbyr den en ryddig og pragmatisk tilnærming til utvidbar arkitektur som samsvarer godt med Gos filosofi om enkelhet. Og gratulerer med flott og enkel navngiving; `plugin` er et særdeles godt navn – det er det det er.

## Clean Architecture i praksis

Det som følger er et enkelt og lite proof-of-concept-prosjekt som demonstrerer hvordan det ser ut "when the rubber meets the road". Prosjektet implementerer en enkel transformasjonspipeline hvor plugins kan modifisere inputdata. La oss gjøre Dependency Inversion-prinsippet (DIP) til kjernen i systemet vårt.

### Arkitekturlag

Prosjektet følger Clean Architecture-prinsipper med tre distinkte lag:

1. **Domenelag** (`pkg/domain`)

   - Inneholder kjerneforretningsregler og grensesnitt
   - Har ingen eksterne avhengigheter
   - Definerer hva transformers skal gjøre
   - Her finner vi `Transformer` og `Plugin` grensesnittene

2. **Applikasjonslag** (`internal/app`)

   - Inneholder kjerne-applikasjonslogikk
   - Er kun avhengig av domenegrensesnitt
   - Koordinerer transformasjonsprosessen
   - Her finner vi `Processor` som håndterer plugins og utfører transformasjoner

3. **Infrastrukturlag** (`plugins`)
   - Inneholder konkrete implementasjoner
   - Er avhengig av domenegrensesnitt
   - Implementerer spesifikke transformasjonsstrategier
   - Her finner vi f.eks. `passthrough`-pluginen

Denne lagdelingen sikrer at:

- Domenelaget forblir rent og stabilt
- Avhengigheter peker alltid innover mot domenet
- Nye implementasjoner kan legges til uten å endre eksisterende kode

Større prosjekter ender ofte opp med flere lag, men la oss holde det så enkelt som mulig.

### Kjernedomenet

I hjertet av systemet vårt ligger transformer-interfacen:

```go
// Transformer er en hva-som-helst som kan utføre en transformasjon fra input bytes til output bytes. Hvordan? Don't know, don't care.
type Transformer interface {
    // Transform prosesserer input-bytes og returnerer transformerte bytes eller en feil.
    Transform(input []byte) ([]byte, error)
}

// Plugin er en hva-som-helst som kan opprette en ny Transformer (definert over). Hvordan? Vil helst ikke vite.
type Plugin interface {
    // NewTransformer oppretter og returnerer en ny Transformer-instans.
    NewTransformer() Transformer
}
```

Disse interfacene representerer våre kjernelogikk – "core business rules". Legg merke til hvor enkelt og stabilt det er – det er ikke avhengig av noen implementasjonsdetaljer, og kommer nok ikke til å endre seg spesielt ofte eller mye.

### Plugin-implementasjon

Her er hvordan en enkel passthrough-plugin implementerer dette grensesnittet:

```go
// passthroughPlugin implementerer transformer.Plugin; en plugin som bare sender input til output uten å gjøre noe mer.
type passthroughPlugin struct{}

// NewTransformer returnerer en ny passthrough transformer-instans.
func (passthroughPlugin) NewTransformer() domain.Transformer {
    return &passthroughTransformer{}
}

// passthroughTransformer implementerer domain.Transformer.
type passthroughTransformer struct{}

// Transform implementerer domain.Transformer ved å returnere input-bytes umodifisert.
func (pt passthroughTransformer) Transform(input []byte) ([]byte, error) {
    return input, nil
}

// Plugin eksporterer passthrough transformer-pluginen for dynamisk lasting.
var Plugin passthroughPlugin

// Vi kan gjøre en compile-time-sjekk for å sikre at passthroughPlugin implementerer domain.Plugin.
var _ domain.Plugin = (*passthroughPlugin)(nil)
```

Det fine med denne tilnærmingen er at plugins er helt isolert fra hverandre og bare er avhengige av kjerneinterfacene i domene-laget.

## Dependency Inversion i aksjon

Vår processor-komponent demonstrerer etterlever DIP til punkt og prikke:

```go
// Processor håndterer lasting og kjøring av transformasjons-plugins.
type Processor struct {
    plugins map[string]domain.Plugin
}

// NewProcessor oppretter og initialiserer en ny Processor-instans.
func NewProcessor() Processor {
    return &Processor{
        plugins: make(map[string]domain.Plugin),
    }
}
```

Legg merke til hvordan `Processor` er avhengig av abstraksjoner (`domain.Plugin`), ikke konkrete implementasjoner. Dette er DIP i sin reneste form. (🤤)

## Plugin-systemet!

`main`-funksjonen laster plugins dynamisk:

```go
// Opprett en ny processor for å håndtere plugins.
proc := processor.NewProcessor()

// Last plugins fra plugins-mappen.
pluginsDir := filepath.Join(execDir, "plugins")
plugins, err := filepath.Glob(filepath.Join(pluginsDir, "*.so"))
if err != nil || len(plugins) == 0 {
    log.Printf("Kunne ikke liste plugins: %v\n", err)
    os.Exit(1)
}

for _, plugin := range plugins {
    if err := proc.LoadPlugin(plugin); err != nil {
        log.Printf("Kunne ikke laste plugin %s: %v\n", plugin, err)
        continue
    }
}
```

Denne tilnærmingen gir flere fordeler:

1. Plugins kan utvikles og distribueres uavhengig
2. Kjerneapplikasjonen forblir stabil
3. Ny funksjonalitet kan legges til uten å modifisere eksisterende kode

I praksis kan du legge til nye plugins **mens du kjører programmet**. Kult?

## Andre bruksområder?

Dette mønsteret kan i prinsippet enkelt utvides til API-utvikling. Tenk deg:

```go
type APIPlugin interface {
    RegisterRoutes(router Router)
    GetBasePath() string
}
```

Hver plugin kunne da håndtere sitt eget API-domene:

- `/users/*` ruter i en users-plugin
- `/products/*` ruter i en products-plugin
- `/orders/*` ruter i en orders-plugin

Mulighetene er jo uendelige! Nå er ikke dette nødvendigvis alltid en god idé, det finnes en del fallgruver ved bruk av `plugin`-pakken. Men, som pakken sier om seg selv, før den lirer av seg den ene advarselen etter den andre:

> The ability to dynamically load parts of an application during execution, perhaps based on user-defined configuration, may be a useful building block in some designs. In particular, because applications and dynamically loaded functions can share data structures directly, plugins may enable very high-performance integration of separate parts.

"Useful building block" er riktig, spør du meg.

## En enkel måte å bygge både det ene og det andre på

Prosjektet bruker en Makefile for å håndtere plugin-kompilering:

```makefile
# Go-kommandoer
GO := go
GOBUILD := $(GO) build
GOCLEAN := $(GO) clean

# Mapper
BUILD_DIR := build
PLUGIN_DIR := plugins
CMD_DIR := cmd

.PHONY: all
all: build plugins

.PHONY: build
build:
    @mkdir -p $(BUILD_DIR)
    $(GOBUILD) -o $(BUILD_DIR)/transform $(CMD_DIR)/main.go

.PHONY: build-plugins
build-plugins:
    @mkdir -p $(BUILD_DIR)/plugins
    @echo "Bygger plugins..."
    @for plugin in $(PLUGIN_DIR)/*/ ; do \
        if [ -f $$plugin/go.mod ]; then \
            plugin_name=$$(basename $$plugin); \
            echo "Bygger plugin: $$plugin_name"; \
            cd $$plugin && go mod tidy && \
            $(GOBUILD) -buildmode=plugin -o ../../$(BUILD_DIR)/plugins/$$plugin_name.so || exit 1; \
            cd ../../; \
        fi \
    done
```

Easy peasy.

## Poenget med det hele

1. Clean Architecture og SOLID-prinsippene tvinger frem en sunn "Separation of Concerns" og gjør systemet enklere å vedlikeholde og videreutvikle
2. Dependency Inversion spesielt sikrer at vår kjernelogikk bare er avhengig av abstraksjoner
3. Go sitt Plugin-system gir en praktisk måte å implementere disse prinsippene på
4. Denne tilnærmingen skalerer godt fra enkle transformasjoner til komplekse API-systemer

## Konklusjon

Gos plugin-system eksemplifiserer språkets forpliktelse til enkelhet og pragmatisk design. Ved å gi et enkelt, kraftig fundament for å bygge modulære systemer, demonstrerer det at kompleksitet ikke er nødvendig for sofistikasjon. Det er et nyttig verktøy enhver ambisiøs utvikler bør ha i skrinet sitt, etter min mening.

Fokuse på klare skillelinjer mellom arkitekturlag og riktig avhengighetshåndtering skaper systemer som er enkle å utvide og vedlikeholde, enten vi bygger enkle transformasjonspipelines eller komplekse API-tjenester.

For den fullstendige implementasjonen, sjekk ut prosjektet på [github.com/cekrem/go-transform](https://github.com/cekrem/go-transform).
