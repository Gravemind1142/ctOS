# Research Notes

Findings distilled from written sources about the Watch Dogs UI, ctOS, Blume and DedSec. Each finding says where it came from. Lines marked _(observed)_ come from looking at images, not from text. **Implications** are our reading, not the source's.

## Typography

- **Helvetica is the ctOS typeface.** The Profiler text in Watch Dogs and Watch Dogs 2 is set in Helvetica. [W3] The WD1 trailer's "sterile, Helvetica-driven theme" was kept on purpose for the WD2 opening because Ubisoft "liked the sterility and ubiquity of Helvetica". [S1]
- **ctOS is a utility, and Helvetica is its branding system.** MK12 modelled ctOS on the **New York City Transit Authority Graphics Standards Manual**, which puts Helvetica at the centre of its identity, and "referenced their branding guidelines and philosophy pretty often". [S1]
- **Hacking has a second, rawer voice.** The WD1 hacking UI uses "barebones typography and icons that draw upon early cell phone iconography and 8-bit/DOS programming fonts", a "basic computing" look that deliberately clashes with the polished cinematic graphics. [S2]

**Implications**
- Type works in two voices. **System** (ctOS speaking): a neo-grotesk such as Helvetica, Nimbus Sans or TeX Gyre Heros. **Raw** (hacking, terminals, data): monospace or bitmap. The repo currently uses JetBrains Mono everywhere, which only covers the raw voice.
- The NYCTA manual is a legitimate primary reference for layout, signage hierarchy and colour coding, not just "inspiration".

## Iconography

- Icons are "barebones", drawn from **early cell-phone iconography** and 8-bit graphics. [S2]
- **The world is the interface.** Hack icons are anchored to the objects they control, so "it looks almost as if the world has its own interface". [S2]
- The look is understated and "not overly polished", so hacking feels "raw and a relatively new phenomenon". [S2]

**Implications:** use small, pixel-honest, monochrome icons. Put indicators next to the thing they describe (the window, device or workspace) rather than in a distant panel.

## Hacking and data visualisation

- Hacking is shown as **"a glitchy series of network lines"** connecting devices and data, conveying complexity that the user controls with ease. [S2]
- MK12 added "a layer of **machine thought**" by studying real-time tracking interfaces: face, flight and weather tracking, and flight-guidance systems. They also ran footage through tracking software and kept its data and artefacts in the final shots. [S1]
- Techniques explored for the WD2 cinematic: **dither** animation, **point-cloud** graphics, **glitch** tests and **arrow-flow** animation. [S1]
- Profiler hacks **take about two seconds** to take effect and cost **battery**, which recharges over time. During a blackout the profiler is useless. [W3]

**Implications**
- A thin progress fill of about 2 s is the canonical "hack in progress" state.
- A resource or battery meter is native to ctOS, so the bar's meters fit the source.
- A "blackout" (everything disabled) is a legitimate state to design for, such as lock or idle.

## Motion and transitions

- MK12 prefers **transitions over cuts**, to show that "all of the information … is intertwined and interdependent". The signature move goes from the **sterile ctOS world into the hacker underworld** in a single transition. [S1]
- To bridge sterile ctOS and the anarchic hacker look, MK12 drew on **early-'70s design**, when "computer and counterculture art first began to erode away at the clean modernism of the '60s". References: Aaron Marcus, John Whitney, Paul Rand, Robert Brownjohn. [S1]

**Implications:** move between states with transitions rather than hard swaps. A ctOS → DedSec "erosion" (clean modernism being degraded by dither and glitch) is the canonical intrusion transition.

## The Profiler (content model)

- WD1 shows the target's **name, occupation, income**, one personal fact, and **crime probability**. [W3]
- WD2 redesigned the profiler to be brighter and more colourful, evoking **Material Design**, with an emoji for the person's mood. Vehicles got their own box: company, logo, make and model, category and plate. [W1, W3]
- Its apps include **Talk Feed** (social), **City Hotspots** (locations) and **DedSec Field Guide**. [W3]

**Implications:** the WD1 profiler (terse, monochrome, Helvetica) is our reference. WD2's Material redesign is the direction *not* to follow. The profiler's structure (name line, labelled facts, one highlighted line) is the template for identity cards and notifications.

## ctOS: the system

- ctOS means **Central Operating System** (called "City Operating System" in a tie-in novel). It is built by Blume and runs a city's infrastructure. [W1]
- **Systems it controls:** traffic lights, bridges, blockers and spikes, the L train, steam pipes, electric grid, power transformers, security cameras, facial recognition, crime prediction, ATMs and bank accounts, TVs and ads, cellular networks, connected devices and vehicles. [W1]
- Data lives in **Control Centres** (server sites) throughout the city, linked by **communication towers**. [W1]
- Its versions are **ctOS (2011, Chicago)**, **ctOS 2.0** (WD2) and **ctOS 3.0** (Legion). [W1]

**Implications:** for our ctOS the desktop *is* infrastructure. Modules, labels and status copy can borrow this vocabulary (systems, nodes, control centre, scan, link established).

## Blume: voice and brand

- Blume describes itself as the "**world's foremost innovator of high-tech, high-performance communications and security technology**". [W2]
- Branding appears as a **"ctOS" wordmark with "POWERED BY BLUME"** and the hexagonal Blume mark. _(observed)_
- **WD2 ads:** a single macro flower photo with one word, "Simple." / "Beautiful." / "Elegant.", and the BLUME lockup. _(observed)_
- **Legion ctOS slogans:** "Not just safer, it's the law." · "Security. Civility. Connectivity." · "Your London. Your life. Your ctOS." · "Connecting London. Connecting You." · "Unifying London." · "All of us, autonomous." [W1]

**Implications** for the copy voice:
- Short declarative fragments, each ending in a full stop.
- Benevolent and civic on the surface, quietly authoritarian underneath.
- Triads ("Security. Civility. Connectivity.").
- Always written as lowercase "ct" + uppercase "OS".

## DedSec: the intruder

- DedSec seized ctOS's official website and turned it into a **black page covered by a DedSec logo made of ASCII characters**. They also tag ctOS ads and city signage with graffiti. [W4]
- Their purpose is to prove ctOS is flawed by exploiting it publicly. [W4]

**Implications:** the canonical DedSec pattern is **takeover and defacement** of ctOS surfaces: black background, ASCII art, content layered *over* ctOS rather than replacing its design language. The existing fastfetch `dedsec.txt` already follows this pattern.

## Still to read

- **NYCTA Graphics Standards Manual** (1970, Vignelli/Noorda). The reference MK12 actually used. Facsimile at standardsmanual.com.
- **Aaron Marcus**: early computer-graphics and UI-design work from the '70s.
- **Legion UI team:** Daniel Molina (HUD and motion), Nicolas Lajeunesse (branding, cinematic and loading screens). [S3] Their portfolios may have process write-ups.
- **Rebecca Cohen-Palacios:** UI designer on Watch Dogs. TGC 2018 talk on UI supporting story.
- **Elastic:** studio behind the original WD1 "sterile Helvetica" trailer. [S1]

## Sources

- **S1:** [Motionographer: Breakdown, Watch Dogs 2.0 opening cinematic by MK12](https://motionographer.com/2016/11/16/breakdown-watch-dogs-2-0-opening-cinematic-by-mk12)
- **S2:** [HUDS+GUIS: Watchdogs Hacking UI](https://www.hudsandguis.com/2013/07/24/watchdogs-hacking-ui/) (2013)
- **S3:** [Noreen Rana: Watch Dogs Legion UI art](https://noreenrana.myportfolio.com/watchdogs-legion)
- **W1:** [Watch Dogs Wiki: ctOS](https://watchdogs.fandom.com/wiki/CtOS)
- **W2:** [Watch Dogs Wiki: Blume Corporation](https://watchdogs.fandom.com/wiki/Blume_Corporation)
- **W3:** [Watch Dogs Wiki: Profiler](https://watchdogs.fandom.com/wiki/Profiler)
- **W4:** [Watch Dogs Wiki: DedSec](https://watchdogs.fandom.com/wiki/DedSec)

Fan-wiki claims (W1–W4) are community-sourced. The Helvetica and profiler-content claims agree with S1 and S2.
