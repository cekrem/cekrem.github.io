---
title: "Et praktisk eksempel på Dependency Inversion i Go med Plugins"
description: "La oss sette Clean Architecture og SOLID-prinsipper på dagsorden igjen!"
tags: ["go", "golang", "arkitektur", "SOLID", "plugin"]
date: 2025-01-07
draft: true
---

## SOLID? Clean Architecture?

Jeg har nylig tatt en ny titt på [SOLID-prinsippene](//en.wikipedia.org/wiki/SOLID), og gravd meg lengre ned/inn enn jeg hadde planlagt. I programvarearkitekturens verden er det få prinsipper som har stått tidens test like godt som disse. Jeg finner "Dependency Inversion-prinsippet" spesielt interessant, siden det ofte blir oversett i moderne applikasjoner, eller drukner i så mye over-engineering at kost/nytte-ligningen blir forskjøvet.

**Merk:** God arkitektur er langt mer enn enkeltestående SOLID-prinsipper, men vi må begynne et sted. Denne artikkelen tar for seg Dependenci Inversion-prinsippet (DIP), som jeg har opplevd som særlig forsømt i prosjekter jeg har vært med på i det siste. Selv har jeg en liten hangup på "Clean Architecture" om dagen, og forsøker å finne ut hvor langt man kan og bør gå i den retningen.

> Dependency Inversion-prinsippet sier:
>
> 1. Høynivåmoduler bør ikke importere noe fra lavnivåmoduler. Begge bør være avhengige av abstraksjoner (f.eks. grensesnitt).
> 2. Abstraksjoner bør ikke være avhengige av detaljer. Detaljer (konkrete implementasjoner) bør være avhengige av abstraksjoner.

I dag skal vi utforske hvordan Go sitt plugin-system muliggjør disse prinsippene.

Den fullstendige koden for denne artikkelen finnes på [github.com/cekrem/go-transform](https://github.com/cekrem/go-transform).

Først en kudos til Uncle Bob for å minne meg på viktigheten av god **programvarearkitektur** i hans klassiker [Clean Architecture](https://amzn.to/4iAc8o1)! Som han sier (ish): "Uten god arkitektur vil vi alle ende opp med å bygge firmware (dvs programvare som er vanskelig å endre)!".

## Forståelse av landskapet

Mens mange språk implementerer modularitet gjennom eksterne avhengigheter (som DLL-er i C# eller JAR-er i Java), er Go stolt av sin evne til å kompilere til en enkelt, selvstendig kjørbar fil. Denne tilnærmingen gir flere fordeler:

- Forenklet distribusjon og versjonshåndtering
- Eliminering av avhengighetskonflikter
- Redusert operasjonell kompleksitet

Nettopp dette med en "single executable binary" er en av tingene jeg liker best når jeg jobber med Go! Det finnes imidlertid scenarioer hvor en plugin-arkitektur blir verdifull – spesielt når du trenger å:

- Legge til funksjonalitet uten å rekompilere kjerneapplikasjonen
- Tillate tredjepartsutvidelser
- Isolere forskjellige komponenter for bedre vedlikeholdbarhet

Go tilbyr en innebygd løsning for disse tilfellene gjennom sin `plugin`-pakke. Selv om den er mindre kjent enn andre språks modulsystemer, tilbyr den en ryddig og pragmatisk tilnærming til utvidbar arkitektur som samsvarer godt med Gos filosofi om enkelhet. Og gratulerer med flott og enkel navngiving. "Plugin" er et særdeles godt navn – det er det det er.

## Clean Architecture i praksis

La oss undersøke et proof-of-concept-prosjekt som demonstrerer noen av disse prinsippene. Prosjektet implementerer en enkel transformasjonspipeline hvor plugins kan modifisere inputdata. La oss gjøre Dependency Inversion-prinsippet (DIP) til kjernen i systemet vårt.

### Kjernedomeneet

I hjertet av systemet vårt ligger transformer-interfacen:

```go
// Transformer definerer interface for datatransformasjonsoperasjoner.
type Transformer interface {
    // Transform prosesserer input-bytes og returnerer transformerte bytes eller en feil.
    Transform(input []byte) ([]byte, error)
}

// Plugin definerer interfacen for plugin-implementasjoner.
type Plugin interface {
    // NewTransformer oppretter og returnerer en ny Transformer-instans.
    NewTransformer() Transformer
}
```

Disse interfacene representerer våre kjærnelogikk – "core business rules". Legg merke til hvor enkelt og stabilt det er – det er ikke avhengig av noen implementasjonsdetaljer, og kommer nok ikke til å endre seg spesielt ofte eller mye.

### Plugin-implementasjon

Her er hvordan en enkel passthrough-plugin implementerer dette grensesnittet:

```go
// passthroughPlugin implementerer transformer.Plugin; en plugin som bare sender input til output uten å gjøre noe mer.
type passthroughPlugin struct{}

// NewTransformer returnerer en ny passthrough transformer-instans.
func (passthroughPlugin) NewTransformer() transformer.Transformer {
    return &passthroughTransformer{}
}

// passthroughTransformer implementerer transformer.Transformer.
type passthroughTransformer struct{}

// Transform implementerer transformer.Transformer ved å returnere input-bytes umodifisert.
func (pt passthroughTransformer) Transform(input []byte) ([]byte, error) {
    return input, nil
}

// Plugin eksporterer passthrough transformer-pluginen for dynamisk lasting.
var Plugin transformer.Plugin = &passthroughPlugin{}
```

Det fine med denne tilnærmingen er at plugins er helt isolert fra hverandre og bare er avhengige av kjernegrensesnittene.

## Dependency Inversion i aksjon

Vår processor-komponent demonstrerer DIP perfekt:

```go
// Processor håndterer lasting og kjøring av transformasjons-plugins.
type Processor struct {
    plugins map[string]transformer.Plugin
}

// NewProcessor oppretter og initialiserer en ny Processor-instans.
func NewProcessor() Processor {
    return &Processor{
        plugins: make(map[string]transformer.Plugin),
    }
}
```

Legg merke til hvordan `Processor` er avhengig av abstraksjoner (`transformer.Plugin`), ikke konkrete implementasjoner. Dette er DIP i sin reneste form. (🤤)

## Plugin-systemet!

Hovedapplikasjonen laster plugins dynamisk:

```go
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

I praksis kan du legge til nye plugins mens du kjører programmet. Kult?

## Andre bruksområder?

Dette mønsteret kan i prinsippet enkelt utvides til API-utvikling. Tenk deg:

```go
type APIPlugin interface {
    RegisterRoutes(router Router)
    GetBasePath() string
}
```

Hver plugin kunne håndtere et forskjellig API-domene:

- `/users/*` ruter i en users-plugin
- `/products/*` ruter i en products-plugin
- `/orders/*` ruter i en orders-plugin

Mulighetene er jo uendelige! Nå er ikke dette nødvendigvis alltid en god idé, det finnes en del [fallgruver](https://pkg.go.dev/plugin#hdr-Warnings) ved bruk av `plugin`-pakken. Men, som pakken sier om seg selv, før den lirer av seg den ene advarselen etter den andre:

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

## Hovedpoenger

1. **Clean Architecture** og **SOLID**-prinsippene tvinger frem en sunn "Separation of Concerns" og gjør systemet mer vedlikeholdbart
2. **Dependency Inversion** spesielt sikrer at vår kjernelogikk bare er avhengig av abstraksjoner
3. **Plugin-systemer** gir en praktisk måte å implementere disse prinsippene på
4. Denne tilnærmingen skalerer godt fra enkle transformasjoner til komplekse API-systemer

## Konklusjon

Go's plugin-system eksemplifiserer språkets forpliktelse til enkelhet og pragmatisk design. Ved å gi et enkelt, kraftig fundament for å bygge modulære systemer, demonstrerer det at kompleksitet ikke er nødvendig for sofistikasjon. Kombinert med Clean Architecture-prinsipper gjør det oss i stand til å skape systemer som både er fleksible og robuste.

Den virkelige kraften kommer fra denne enkelheten: ved å fokusere på klare grensesnitt og riktig avhengighetshåndtering, kan vi skape systemer som er enkle å utvide og vedlikeholde, enten vi bygger enkle transformasjonspipelines eller komplekse API-tjenester.

For flere detaljer og den fullstendige implementasjonen, sjekk ut prosjektets repository på [github.com/cekrem/go-transform](https://github.com/cekrem/go-transform).
