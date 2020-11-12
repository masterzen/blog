---
layout: single
title: Designing a keyboard from scratch - Part 4
header:
  image: /images/uploads/2020/05/header-part3.jpg
category:
- "mechanical keyboards"
- DIY
tags:
- design
- PCB
- electronics
- "mechanical keyboards"
---

Welcome for the fourth episode of this series of posts about designing a full fledged keyboard from scratch. So far we've seen:

* how to create the electronic schema of the keyboard controller in [the first episode](/2020/05/03/designing-a-keyboard-part-1/)
* how to design the matrix and layout components in [the second episode](/2020/05/25/designing-a-keyboard-part-2/)
* how to route the pcb efficiently in [the third episode](/2020/10/20/designing-a-keyboard-part-3)

I'll now cover:

* generating manufacturing output
* ordering PCB manufacturing
* selecting the correct components
* assembling the PCB
* creating the firmware
* testing the PCB

This is again a long episode that took me a quite long time to produce. Feel free to leave a comment if you have any questions or find anything suspect :)

## Getting manufacturing files

We need to export our PCB out of Kicad and send it to the factory. Hopefully, all the factories out there use a common file format that is called the [Gerber format](https://en.wikipedia.org/wiki/Gerber_format).

This file format is a vectorial format that describe precisely the layer traces and zones, silk screens, and sometimes where to drill holes (some manufacturer require Excellon format). This has become a kind of interchange standard for PCB factories. This is an old file format that was used to send numerical commands to Gerber plotters in the 70s. Since then the format has evolved and we're dealing now with Extended Gerber files.

Back to my PCB, I can generate my set of Gerber files to be sent to the factory from `pcbnew` by going to _File &rarr; Plot..._. A new window opens where I can configure the output.

The options to set will depend on the manufacturer. Here's a few manufacturer Kicad recommandations and settings:

* [JLCPCB (China)](https://support.jlcpcb.com/article/102-kicad-515---generating-gerber-and-drill-files)
* [PCBWay (China)](https://www.pcbway.com/blog/help_center/Generate_Gerber_file_from_Kicad.html)
* [Elecrow (China)](https://www.elecrow.com/pcb-manufacturing.html)
* [OSHPark (USA)](https://docs.oshpark.com/design-tools/kicad/generating-kicad-gerbers/)
* [Eurocircuits (EU)](https://www.eurocircuits.com/blog/kicad-eurocircuits-reads-in-native-kicad-data/) - note that Eurocircuit reads directly the Kicad file, no need to generate Gerber files.
* [Aisler (EU)](https://aisler.net/help/supported-pcb-design-tools/kicad)
* [Multi Circuit Board (EU)](https://www.multi-circuit-boards.eu/en/support/pcb-data/kicad.html)
* ... There are many others, see [PCBShopper](https://pcbshopper.com/) for a comparator

Caution: different manufacturer have different tolerances and capabilities (for instance minimum track size, via size, board size, etc). Make sure you check with them if your PCB can be manufactured.

This time, I'm going to be using [JLCPCB](https://jlcpcb.com/). Here's the recommended setup for JLCPCB with Kicad 5.1:

[![Plot Gerber](/images/uploads/2020/10/kicad-plot-gerber-jlcpcb.png){: .align-center style="width: 85%"}](/images/uploads/2020/10/kicad-plot-gerber-jlcpcb.png)

For this project the following layers needs to be checked:

* `F.Cu`
* `B.Cu`
* `F.SilkS`
* `B.SilkS`
* `F.Mask`
* `B.Mask`
* `Edge.Cuts`

The first two are for drawing the tracks and pads, the two second ones are the components reference and value indication (and the art), the mask contains the zone without it like pads and holes, and the `Edge.Cuts` the board outline.

Make sure the chosen format is `Gerber`, choose a sensible output folder (I like to put those files in a `manufacturing` subfolder).

And additionnally those options need to be checked:

* _Check Zone fills before plotting_ - to make sure zones have been recomputed
* _Plot footprint values_ - because our switch footprints have the key name as values in the silkscreen
* _Plot footprint references_ - because all the components execpt the switches have a unique reference (that will help when soldering)
* _Exclude PCB Edge from other layers_

When clicking on the _Plot_ button, the files are generated (in the folder I previously entered).

The next step is to generate the drill files, which will contain the location where to drill holes. This can be done by clicking on the _Generate Drill Files_ button next to the _Plot_ button in the previous window:

[![Plot Gerber](/images/uploads/2020/10/kicad-plot-drill-files.png){: .align-center style="width: 85%"}](/images/uploads/2020/10/kicad-plot-drill-files.png)

The important options to check are:

* _Excellion_
* _Use route command_
* _Postscript_

Generating the drill file is done by clicking on the _Generate Drill File_ (oh that was unexpected :) )
This produces two new files in my manufacturing folder, one for the plated holes and the other ones for the non-plated holes. The `manufacturing` folder now contains:

* aek67-B_Cu.gbr
* aek67-B_Mask.gbr
* aek67-B_SilkS.gbr
* aek67-Edge_Cuts.gbr
* aek67-F_Cu.gbr
* aek67-F_Mask.gbr
* aek67-F_SilkS.gbr
* aek67-NPTH.drl
* aek67-PTH.drl

Now zip everything (`cd manufacturing ; zip -r pcb.zip *` if you like the command-line). That's what we're going to upload to the manufacturer.

## Manufacturing

If you're interested in PCB manufacturing, you can watch this [video of the JLCPCB factory](https://www.youtube.com/watch?v=ljOoGyCso8s), you'll learn a ton of things about how PCB are made these days.

So, the process is to upload the Gerber and drill files to the factory. But first it's best to make sure those files are correct. Kicad integrates a Gerber viewer to do that. It's also possible to check with an online Gerber viewer like for instance [Gerblook](https://www.gerblook.org/) or [PCBxprt](http://www.pcbxprt.com/).

The Kicad viewer can be launched from the Kicad project window with _Tools &rarr; View Gerber Files_. The next step is to load the gerber files in the viewer with the _File &rarr; Open ZIP file_ and point it to the `pcb.zip` file of the previous chapter.

This gives this result:

[![Gerber Viewer](/images/uploads/2020/10/kicad-gerber-viewer.png){: .align-center style="width: 85%"}](/images/uploads/2020/10/kicad-gerber-viewer.png)

So, what to check in the viewer files?

1. check that the files can be correctly opened
2. check each layers independentlg
3. for copper layers, check that the pads seems correct
4. for soldermask layers, check that the soldermask doesn't appear on pads
5. for silkscreen layers, check that components' references and values appear correctly, then check the silkscreen art and text if there are some.

Once this basic verification has been done, it's time to upload the zip file to the manufacturer website. Once the file is uploaded, the site will display the gerber file. Make sure to check again the layers, as this time it's the manufacturer interpretation of the files. With JLCPCB the interface looks like this:

[![JLCPCB ordering](/images/uploads/2020/10/jlcpcb-ordering-1.png){: .align-center style="width: 95%"}](/images/uploads/2020/10/jlcpcb-ordering-1.png)

In this screenshot, I have omitted the price calculation and the bottom part (we'll get to this one below). You can see the gerber view, and most manufacturer host an online gerber viewer to make sure the files are correctly loaded.

Immediately below, there's the choice of number of layers and pcb dimensions. Those two numbers have been detected from the uploaded file. Make sure there's the right number of layers (two in this case), and that the dimensions are correct. If not, check the gerber files or original Kicad files edge cutout.

The next set of options deals with the number of PCB and their panelisation:

[![JLCPCB ordering](/images/uploads/2020/10/jlcpcb-ordering-2.png){: .align-center style="width: 70%"}](/images/uploads/2020/10/jlcpcb-ordering-2.png)

Paneling is the process of grouping multiple PCB on the same manufacturing board. The manufacturer will group several PCB (from either the same customer or different customers) on larger PCB. You can have the option of grouping your PCB the way you want, depending on the number of different designs you uploaded. On my case, this is straightforward as there's only one design that doesn't need to be panelized. Even though, I'm going to build only one keyboard, the minimum order quantity is 5 pieces. But that's not as bad as it seems, because that will leave me the freedom of failing the assembly of a few boards :)

The next set of options are the technical characteristics of the board:

[![JLCPCB ordering](/images/uploads/2020/10/jlcpcb-ordering-3.png){: .align-center style="width: 70%"}](/images/uploads/2020/10/jlcpcb-ordering-3.png)

There we can change the thickness, color, finish, copper weight etc.

Those parameters are important so I need to explain what to choose. The _PCB thickness_ represents the thickness of the FR4 fiber glass board sandwiched by the two copper layers which are later on etched to form the tracks. For a regular keyboard the standard is 1.6 mm. If you want to build a keyboard with more flex, you can opt for a 1.2 mm PCB. Note that in this case, it will not be possible to properly use PCB snap-in stabilizers (hopefully it won't be an issue for scree-in stabilizers or plate stabilizers). Since this PCB is to be used in a regular keyboard, the default 1.6 mm will be selected.

The _PCB color_ is a matter of preference of course. Just know that the most PCBs built by JLCPCB are green, so this color isa cheaper (and take less lead/build time) to manufacture compared to a blue one for instance. Since the beginning of this series I was showing a blue soldermask so I decided to keep using a blue soldermask. I got a warning that it would mean two extra days of lead time.

_Surface finish_ is how the pads and through-holes are plated. There are three possibilities, HASL, lead-free HASL, and ENIG. Technically the two first ones are equivalent.

[![HASL](/images/uploads/2020/10/HASL.jpg){: .align-center style="width: 70%"}](/images/uploads/2020/10/HASL.jpg)
[![ENIG](/images/uploads/2020/10/ENIG.jpg){: .align-center style="width: 70%"}](/images/uploads/2020/10/ENIG.jpg)

The pads' copper will oxidize with time at the contact with air. Those solderable parts of the PCB must be protected by a surface treatment to prevent oxidation. The [HASL](https://en.wikipedia.org/wiki/Hot_air_solder_leveling) (Hot Air Solder Leveling) and its lead-free variant consist in dropping a small amount of solder on all the visible copper parts. [ENIG](https://en.wikipedia.org/wiki/Electroless_nickel_immersion_gold) or Electroless Nickel Immersion Gold is a plating process consisting in plating the copper with a nickel alloy and then adding a very thin layer of gold on top of it (both operations are chemical operations where the board is dipped in some special solutions). I have tested both options, and I really favor ENIG over HASL, despite the price increase. I found that it is easier to solder SMD components on ENIG boards than on HASL ones (the solder seems to better wet and flow, also the surface is completely flat on ENIG boards so it's easier to place components).

The _copper weight_ is in fact a measure of the copper thickness on each layer. The default is 1 oz, which means a thickness of 35 µm. Using a thicker copper layer would change the trace thickness and thus their electrical characteristics (inductance, impedance and such). The default of 1 oz is fine for most use cases.

Next [_gold fingers_](https://www.quora.com/What-are-gold-fingers-PCB). This is not needed most of the time (especially for keyboards), gold fingers are visible traces on the edge of the PCB that are used to slot-in a daughter card in a connector.

Finally for 2-layers boards, JLCPCB doesn't offer to choose a different board material than regular FR4.

The next set of options are less important and some are straightforward:

[![JLCPCB ordering](/images/uploads/2020/10/jlcpcb-ordering-4.png){: .align-center style="width: 70%"}](/images/uploads/2020/10/jlcpcb-ordering-4.png)

I will just talk about castellation holes. Those are plated holes at the edge of the board. They will be cut in half in the process (if the option is selected). One of the use case is to join and solder two distinct pcb by the edge, using either solder joints or specialized connectors. Of course this option is not needed for this project.

And finally the last option is the possibility to have the pcb separated by a piece of paper when packed. JLCPCB quality is reasonably good, but I already had a few of my PCBs showing partly erased silkscreen or slightly scratched soldermask. It's up to you to select or not this option (it increases the price because of the extra labor).

Before ordering, it is also possible to purchase assembly. In this case, all the components will be soldered at the factory (though they only support one face and only some specific parts, USB receptacles for instance are not available). If selected, you'll need to provide the BOM and the parts position/orientation (Kicad can provide this placement file). Since this would spoil the fun of soldering SMD parts by hand, this option will not be selected.

One can also order a stencil. A stencil is a metal sheet with apertures at the pads locations (imagine the soldermask but as a metal sheet):

[![SMT Stencil](/images/uploads/2020/10/smt-stencil.jpg){: .align-center style="width: 70%"}](/images/uploads/2020/10/smt-stencil.jpg)

It it used to apply solder paste to the board before placing the components when soldering with a reflow oven or an hot air gun (or even an [electric cooking hot plate](https://www.youtube.com/watch?v=aEn3Wb_zrts)). This technique is demonstrated in this [video](https://www.youtube.com/watch?v=H04M1oOsqW8). I don't need this option either, as I intend to hand solder with a soldering iron the SMD components.

After that the next step is to finalize the order, pay and wait. Depending on the options (mostly the soldermask color), it can take from a couple of days to more than a week for the PCBs to be manufactured. Shipping to EU takes between one or two weeks depending on the chosen carrier (and the pandemic status).

But a PCB without the components would be of no use. So while I'm waiting for the boards to be manufactured and shipped to me, I can order the components.

## Selecting the parts

Kicad is able to generate a BOM list with the _File &rarr; Fabrication Output &rarr; BOM File.._. This produces a CSV file. Note that it's not a regular CSV where fields are separated by commas, instead they are using semicolon separators. This file can loaded into a spreadsheet software. After cleaning it a bit (removing the switches and logos), it gives this kind of table:

[![Components](/images/uploads/2020/10/kicad-BOM.png){: .align-center style="width: 80%"}](/images/uploads/2020/10/kicad-BOM.png)

This will be of great help to know how many components I have to order to build one PCB (or the 5 I've ordered in the previous chapter).

So in a nutshell, for this keyboard, I need to find parts for the following components:


| Designation  | Type | Footprint |Quantity |
|--------------|------|-----------|---------|
| FB1 | Ferrite Bead | 0805 | 1 |
| SW1 | Reset switch | SKQG | 1 |
| C1-C4 | 100nF Capacitor | 0805 | 4 |
| C5 | 10uF Capacitor | 0805 | 1 |
| C6 | 1uF Capacitor | 0805 | 1 |
| C7, C8 | 22pF Capacitor | 0805 | 2 |
| R1, R2 | 10kΩ Resistor | 0805 | 2 |
| R3, R4 | 22Ω Resistor | 0805 | 2 |
| R5, R6 | 5.1kΩ Resistor | 0805 | 2 |
| X1 | 16 MHz Crystal | 3225 | 1 |
| USB1 | USB Connector | HRO-TYPE-C-31-M-12 | 1 |
| U2 | PRTR5V0U2X | SOT143B | 1 |
| U1 | Atmega 32U4-AU | TQFP-44 | 1 |
| F1 | PTC Fuse | 1206 | 1 |
| D1-D67 |Diode | SOD323 | 67 |

First, let's see where electronic parts can be bought. There are lots of possibilities. I won't recommend sourcing from random stores on AliExpress, but instead I'll recommend ordering from professional vendors. You'll be sure to get genuine parts (and not counterfeited components). The professional vendors will also store and ship correctly the component in term of humidity and ESD protections.

I usually buy parts from the following vendors (and since I'm based in the EU, I tend to favor European vendors):

* [LCSC](https://lcsc.com/), this is the JLCPCB sister company. China located, they ship everywhere. Most of the time you can purchase in small quantities (ie > 10). They occasionnally run out of AtMega32U4. There's a risk of customs taxes when shipping to Europe.
* [RS Components](https://www.rs-online.com/), ships from Europe (VAT included) with free shipping in France for week-end orders.
* [TME](https://www.tme.eu), based in Poland (so VAT included), very fast shipping to European Countries
* [Mouser](https://eu.mouser.com/), they also ship from Europe for European customers.
* [Digikey](https://www.digikey.com/), ships from the US (subject to customs taxes for Europeans)

I usually order from LCSC, TME and RS. With a predilection for TME lately. Almost all those vendors carry the same kind of components, sometimes even from the same manufacturers (for the most known ones like Murata, Vishay, etc). On LCSC, you'll also find components made by smaller Chinese companies that can't be found anywhere else.

All those vendors also provide the component datasheets which is very usefull to select the right component. If you want to order directly, see the table below for the exact parts number and LCSC/TME/DigiKey specific SKUs.

### Diodes

The diodes are the simplest component to select. A keyboard needs basic signal switching diodes, the most iconic one is the `1N4148`. I selected the `SOD-123` package reference `1N4148W-TP` from `MCC`.

| Reference | LCSC | TME | Digikey |
|-----------|------|-----|---------|
| D1-D67    | [C77978](https://lcsc.com/product-detail/Switching-Diode_MCC-Micro-Commercial-Components-1N4148W-TP_C77978.html) | [1N4148W-TP](https://www.tme.eu/fr/details/1n4148w-tp/diodes-universelles-smd/micro-commercial-components/) | [1N4148WTPMSCT-ND](https://www.digikey.com/short/znv5cf) |

### PTC Resetable Fuse

To select a PTC resetable fuse, one need to know its basic characteristics. USB is able to deliver at max 500 mA (because that's what the 5.1 kΩ pull up resistors R5 and R6 says to the host), so ideally the fuse should trip at any current above 500 mA. Based on this, I can select a part that has the 1206 SMD form factor and a reasonable voltage.

I selected the _TECHFUSE nSMD025-24V_  on the LCSC site. It trips at 500mA, is resettable (ie once it triggers, it will stop conducting, but will become conducting again after the surge), and it can sustain up to 100A (which is large enough to absorb any electrical surge). This specific part is not available from the other vendors, but can be substituted by the _Bell Fuse 0ZCJ0025AF2E_ (other manufacturer's part can also match).

This component looks like this:

[![PTC Fuse](/images/uploads/2020/10/smd-component-F1.jpg){: .align-center style="width: 60%"}](/images/uploads/2020/10/smd-component-F1.jpg)

To summarize:

| Reference | LCSC | TME | Digikey |
|-----------|------|-----|---------|
| F1    | [C70069](https://lcsc.com/product-detail/PTC-Resettable-Fuses_TECHFUSE-nSMD025-24V_C70069.html) | [0ZCJ0025AF2E](https://www.tme.eu/fr/details/0zcj0025af2e/fusibles-polymeres-smd/bel-fuse/)| [507-1799-1-ND](https://www.digikey.com/short/znv5qr)|

### Crystal oscillator

The MCU I used by default is programmed to work with a crystal oscillator (or a ceramic resonator). To select such component, the main characteristics are it's oscillation frequency (16 MHz here) and part size (3225). In LCSC, those parts are called _Crystals Resonators_, but in fact they are oscillators.

The next parameter is the frequency deviation in _ppm_. The lower is the better. The lowest ESR should also be favored.

In a previous design, I had selected the _Partron CXC3X160000GHVRN00_ but LCSC now lists this part as to not be used for new designs (I have no idea why, maybe this is an EOL product). So instead it can be replaced by either the _Seiko Epson X1E000021061300_, the _IQD LFXTAL082071_ or the _Abracon LLC ABM8-16.000MHZ-B2-T_, or the _SR PASSIVEs 3225-16m-sr_.

Here's how a crystal oscillator looks like:

[![Crystal oscillator](/images/uploads/2020/10/smd-component-x1.jpg){: .align-center style="width: 80%"}](/images/uploads/2020/10/smd-component-x1.jpg)

| Reference | LCSC | TME | Digikey |
|-----------|------|-----|---------|
| 16 Mhz Crystal | [C255909](https://lcsc.com/product-detail/SMD-Crystal-Resonators_Seiko-Epson_X1E000021061300_Seiko-Epson-X1E000021061300_C255909.html) | [3225-16m-sr](https://www.tme.eu/fr/details/3225-16m-sr/resonateurs-a-quartz-smd/sr-passives/) | [1923-LFXTAL082071ReelCT-ND](https://www.digikey.com/short/znvn0z) |

### Resistors

To choose resistors, the following characteristics matter:

* resistance (in Ω)
* tolerance (in percent)
* power
* package size
* temperature coefficient (short tempco) - or how much the resistance change with temperature. This parameter doesn't really matter in our use case.

The tolerance is the amount of variation in resistance during manufacturing from one sample to another. The lower the tolerance is, the better the resistor has the indicated value, but the higher the price is.

For most of the applications, a 10% or 5% tolerance don't matter, but for some applications you might want to go down to lower tolerance values like 1% or even 0.1%. I've selected 1% tolerance parts, but I believe it is possible to use 5% ones.

The power is the amount of power the resistor is capable to handle without blowing. For this keyboard, 125 mW (or 1/8 W) is more than enough.

A SMD 0805 resistor (here it's 22Ω) looks like that:

[![SND Resistor](/images/uploads/2020/10/smd-component-r.jpg){: .align-center style="width: 80%"}](/images/uploads/2020/10/smd-component-r.jpg)


Here's a list of the selected part

| Reference | resistance | LCSC | TME | Digikey |
|-----------|------------|------|-----|---------|
| R1, R2 | 10kΩ | [C84376](https://lcsc.com/product-detail/Chip-Resistor-Surface-Mount_10KR-1002-1_C84376.html)| [RC0805FR-0710KL](https://www.tme.eu/fr/details/rc0805fr-0710k/resistances-smd-0805/yageo/rc0805fr-0710kl/)|[311-10.0KCRCT-ND](https://www.digikey.com/short/znvr47)|
| R3, R4 | 22Ω | [C150390](https://lcsc.com/product-detail/Chip-Resistor-Surface-Mount_HDK-Hokuriku-Elec-Industry-CR20-220FV_C150390.html)| [CRCW080522R0FKEA](https://www.tme.eu/fr/details/crcw080522r0fkea/resistances-smd-0805/vishay/)|[541-22.0CCT-ND](https://www.digikey.com/short/znvrpt)|
| R5, R6 | 5.1kΩ | [C84375](https://lcsc.com/product-detail/Chip-Resistor-Surface-Mount_YAGEO-RC0805FR-075K1L_C84375.html)| [RC0805FR-075K1L](https://www.tme.eu/fr/details/rc0805fr-075k1/resistances-smd-0805/yageo/rc0805fr-075k1l/)|[311-5.10KCRCT-ND](https://www.digikey.com/short/znvrmt)|

Note that some of those parts are available only in batch of more than 100 pieces. It is perfectly possible to substitute for parts that can be sold in lower quantities as long as the characteristics are equivalents.

### Capacitors

There are many type of capacitors of various technology. Those that are of interest for our decoupling/bypass SMD capacitors are MLCC (multi layered ceramical capacitors).

* capacitance (in F)
* tolerance (in percent)
* max voltage
* temperature coefficient
* package size

For decoupling and crystal load capacitors, it is not required to use a very precise capacitance, thus we can use the 10% tolerance. As far as this board is concerned, max voltage can be anywhere above 16V.

The temperature coefficient is like for resistance the variation in capacitance with temperature increase or decrease. For capacitors, it is a three character code, like `X7R`, `X5R`, where:

* the first character is the lowest temperature the capacitor can work (`X` is -55ºC for instance)
* the second character is the max temperature (`5` is 85ºC, `7` is 127ºC for instance)
* the last character is the amount of capacitance change over the temperature that the capacitor supports. `R` means +/- 15%, but `V` is about +-85%.

You might also have found the `C0G` code (or `NP0`). Those are different beast (in fact it's a different capacitor class), they are not affected by temperature at all. 

It's better to choose `R` over `V` variants (ie `X7R` is better than `Y5V` for instance). Since our keyboard temperature is not expected to increase considerably, I can choose `X7R` or even `X5R`. `C0G` parts are usually larger and harder to find in package smaller than 1206.

Among manufacturers, you can't go wrong wiht `AVX`, `Samsung`, `Vishay`, `Murata` and probably a few others. I've selected `Samsung` parts.

Here's how a SMD 0805 capacitor looks like:

[![SMD Capacitor](/images/uploads/2020/10/smd-component-c.jpg){: .align-center style="width: 80%"}](/images/uploads/2020/10/smd-component-c.jpg)


| Reference | capacitance | LCSC | TME | Digikey | Note |
|-----------|------------ |------|-----|---------|------|
| C1-C4 | 100nF | [C62912](https://lcsc.com/product-detail/Multilayer-Ceramic-Capacitors-MLCC-SMD-SMT_SAMSUNG_CL21B104JBCNNNC_100nF-104-5-50V_C62912.html) | [CL21B104KBCNNNC](https://www.tme.eu/fr/details/cl21b104kbcnnnc/condensateurs-mlcc-smd-0805/samsung/) | [1276-1003-1-ND](https://www.digikey.com/short/znvw1w)| |
| C5 | 10uF | [C95841](https://lcsc.com/product-detail/Multilayer-Ceramic-Capacitors-MLCC-SMD-SMT_SAMSUNG_CL21B106KOQNNNE_10uF-106-10-16V_C95841.html) | [CL21A106KOQNNNG](https://www.tme.eu/fr/details/cl21a106koqnnng/condensateurs-mlcc-smd-0805/samsung/) | [1276-2872-1-ND](https://www.digikey.com/short/znvn70) | TME only have the X5R version |
| C6 | 1uF | [C116352](https://lcsc.com/product-detail/Multilayer-Ceramic-Capacitors-MLCC-SMD-SMT_Samsung-Electro-Mechanics_CL21B105KAFNNNE_Samsung-Electro-Mechanics-CL21B105KAFNNNE_C116352.html)| [CL21B105KAFNNNE](https://www.tme.eu/fr/details/cl21b105kafnnne/condensateurs-mlcc-smd-0805/samsung/) | [1276-1066-1-ND](https://www.digikey.com/short/znvn30) | |
| C7, C8 | 22 pF | [C1804](https://lcsc.com/product-detail/Multilayer-Ceramic-Capacitors-MLCC-SMD-SMT_Samsung-Electro-Mechanics-CL21C220JBANNNC_C1804.html) | [CL21C220JBANNNC](https://www.tme.eu/fr/details/cl21c220jbannnc/condensateurs-mlcc-smd-0805/samsung/) | [1276-1047-1-ND](https://www.digikey.com/short/znvn8b) | lower capacitance are only available in `C0G` |

### Ferrite bead

Choosing the right ferrite bead is a bit complex. One has to dig in the various references datasheet. This design needs a ferrite bead that can filter high frequencies on a large spectrum. Ferrit beads characteristics are usually given as characteristic impedance at 100 MHz. That doesn't give any clue about the characteristic impedance at over frequencies. For that, one need to look at the frequency diagrams in the datasheet.

What I know is that, the impedance at 100 MHz should be between 50Ω and 100Ω to be effective to filter out noise and ESD pulses. For the same reason, it also needs to resist to high incoming current.

After looking at hundreds of references, I finally opted for the [_Murata BLM21PG600SN1D_ ](https://www.murata.com/en-us/products/productdetail?partno=BLM21PG600SN1%23).

Also, since I opted for a 0805, its current limit is in the lower part. I might probably change the PCB to use a 1206 sized ferrite bead to have it support higher currents.

| Reference |LCSC | TME | Digikey |
|-----------|------|-----|---------|
| FB1       | [C18305](https://lcsc.com/product-detail/Ferrite-Beads_Murata-Electronics-BLM21PG600SN1D_C18305.html) | [BLM21PG600SN1D](https://www.tme.eu/fr/details/blm21pg600sn1d/ferrites-maillons/murata/) | [490-1053-1-ND](https://www.digikey.com/short/znvdtq) |

### The remaining parts

| Reference | LCSC | TME | Digikey | Note |
|-----------|------|-----|---------|------|
| PRTR5V0U2X | [C12333](https://lcsc.com/product-detail/Diodes-ESD_Nexperia-PRTR5V0U2X-215_C12333.html) | [PRTR5V0U2X.215](https://www.tme.eu/fr/details/prtr5v0u2x.215/diodes-de-protection-en-reseau/nexperia/) | [1727-3884-1-ND](https://www.digikey.com/short/znvn4t) | |
| AtMega32U4-AU | [C44854](https://lcsc.com/product-detail/ATMEL-AVR_ATMEL_ATMEGA32U4-AU_ATMEGA32U4-AU_C44854.html) | [AtMega32U4-AU](https://www.tme.eu/fr/details/atmega32u4-au/famille-avr-8-bit/microchip-atmel/) | [ATMEGA32U4-AU-ND](https://www.digikey.com/short/znvnmm) | |
| HRO-TYPE-C-31-M-12 | [C165948](https://lcsc.com/product-detail/USB-Type-C_Korean-Hroparts-Elec-TYPE-C-31-M-12_C165948.html) | not found | not found | |
| Reset Switch | [C221929](https://lcsc.com/product-detail/Tactile-Switches_C-K-RS-187R05A2-DSMTRT_C221929.html) | [SKQGABE010](https://www.tme.eu/fr/details/skqgabe010/microcommutateurs-tact/alps/) | [CKN10361CT-ND](https://www.digikey.com/short/znvnb2) | TME doesn't carry the C&K switch, so substituted by the Alps version |

Here's a picture of the PRTR5V0U2X, notice the GND pin that is larger than the other ones:

[![PRTR5V0U2X](/images/uploads/2020/10/smd-component-prtr.jpg){: .align-center style="width: 80%"}](/images/uploads/2020/10/smd-component-prtr.jpg)

### A bit more information on components

SMD components are packaged as a tape on a reel. If you purchase less than a full reel (4000 to 5000 individual pieces), you'll get a cut piece of the tape like this one:

[![Component reel](/images/uploads/2020/10/smd-reel.jpg){: .align-center style="width: 60%"}](/images/uploads/2020/10/smd-reel.jpg)

Those tapes are made of two parts: a small shiny transparent layer on the top, the cover tape and the bottom the carrier tape. To get access to the component, one just need to peel off the top layer. Since those parts are very small, I recommend to keep them in their tape and peel off only the needed portion of the cover tape.

Components are quite sensible to electrostatic discharge, that's why they're shipped in special anti-static bags. There are dissipative antistatic bags, usually made from polyethylene with a static dissipative coating. They work by dissipating the static charge that could build up on their surface onto other objects (including air) when the bag is touching something else. Those are usually red or pink:

[![Dissipative bag](/images/uploads/2020/10/dissipative-bags.jpg){: .align-center style="width: 35%"}](/images/uploads/2020/10/dissipative-bags.jpg)

There are also conductive antistatic bags, made with a conductive metal layer and a dielectric layer. Those bags protect their contents from ESD, the metal layer forming a Faraday cage. You can recognize those bags because they are gray or silver:

[![Conductive bags](/images/uploads/2020/10/conductive-bags.jpg){: .align-center style="width: 35%"}](/images/uploads/2020/10/conductive-bags.jpg)

Note that shielded bags are inefficient if the shield is not continuous, so make sure to not use bags with a perforation or puncture.

Components should always be stored in such bags. Only remove the components from the bag when you're ready to solder them on a PCB. And do so if possible in an anti-static environment (see below).

Components should also be stored in a place that is not too humid. Some active components are shipped with desiccant bags inside the ESD protection bag, keep them when storing the components as they would absorb the excess humidity that could destroy the part.

## PCB assembly

So, it's mail day: I received the PCB:

[![AEK67 front PCB](/images/uploads/2020/10/aek67-pcb-front.jpg){: .align-center style="width: 90%"}](/images/uploads/2020/10/aek67-pcb-front.jpg)

[![AEK67 back PCB](/images/uploads/2020/10/aek67-pcb-back.jpg){: .align-center style="width: 90%"}](/images/uploads/2020/10/aek67-pcb-back.jpg)

and the components (see the AtMega32U4 in the cardboard box in the center):

[![SMD components](/images/uploads/2020/10/smd-parts.jpg){: .align-center style="width: 80%"}](/images/uploads/2020/10/smd-parts.jpg)

I'm now ready to assemble the PCB, that is solder all the components.

### The tools

To do that you will need a few needed tools:

* ESD safe tweezers
* a soldering iron & tip
* tools to clean the iron
* solder
* extra flux
* desoldering tools
* magnifying tools

That's the minimum required. Of course if you can afford a microscope or a binocular that would be helpful.

#### ESD tweezers

As I've explained earlier, electronic components can be destroyed by electro-static discharges. The human body is able to accumulate charges (for instance on walking on a carpet) and when touching another object discharge into it. Thus it's important to prevent ESD when manipulating components. 

To be able to place precisely the component on the PCB while soldering it, and also hold it while the solder solidifies, one need a pair of electronic tweezers. Since usually tweezers are made of metal, they would conduct the static charge to the component or the board. ESD tweezers are metallic tweezers that are coated with an non-conductive anti-static material, preventing charge to be transfered from the human body to the component.

You can find cheap tweezer sets in [Amazon](https://www.amazon.com/dp/B06XXXQHS8) or more expensive ones at the previous vendors I cited for sourcing components.

Here are mine:

[![ESD Tweezers](/images/uploads/2020/10/tools-tweezers.jpg){: .align-center style="width: 80%"}](/images/uploads/2020/10/tools-tweezers.jpg)

#### Soldering iron

I'll recommend using a temperature controlled soldering iron, especially for soldering very small parts. One good choice would be either the Hakko FX888D, the FX951 or any other temperature controlled Hakko stations (of course if you can afford them, check Weller or Metcalf stations). Hakko stations can be purchased in EU from [batterfly](https://www.batterfly.com/shop/en/soldering/stazioni-saldanti).

You'll also find Hakko T12 compatible stations on Aliexpress (like the KSGER T12), those are quite nice and inexpensive, unfortunately their PSU is rigged with a defective design that make them not as secure as they should (they probably wouldn't pass CE conformity). I thus won't recommend them (see [this video](https://www.youtube.com/watch?v=rwY6s4RRF7g) for more information).

Then finally you can find standalone USB powered soldering irons like the TS80P or TS100. Those are very lightweight and have custom opensource firmwares superior to the original. They have a drawback: they're not earthed by default and thus not ESD safe. The risk is a potential ESD destroying the SMD components that are being soldered. Regular soldering irons that you plug in a wall socket have the heating tip earthed and thus can't build up an electrostatic charge. Moreover, those USB soldering iron are known to leak current when used. This can be fixed by adding an earth connection from the iron to common earth which requires a specific cable from the iron to an earth point (or at least a common potential point between you, the iron and the PCB, which can be done with specific anti-static workbench or mats). Some TS80P kits contain such earch grounding cables, some other not. This makes me not recommending such iron.

Rergarding soldering iron tips, you can find many different ones and it will depends on the soldering iron you've got. There are tons of different [Hakko tips](https://www.hakko.com/english/tip_selection/series_t12.html) (here for the T12 tips). In those brand, the recommended ones for SMD parts are shapes [D](https://www.hakko.com/english/tip_selection/type_d.html), [BC/C](https://www.hakko.com/english/tip_selection/type_bc_c.html) and [B](https://www.hakko.com/english/tip_selection/type_b.html). For the size, you can't go wrong with D12 (or D16), B2 and BC2.

#### Iron tip cleaning

The tip of your soldering iron is critical for the performance of the tool. It it can't perform its function of transfering heat to the solder joint, the soldering iron will not be efficient. That's why it is important to take care of the soldering iron tip to prevent any soldering issues.

Soldering tips will wear throughout the time you use it and will probably have to be replaced at some point. Careful tip hygiene will extend their life.

A particularly recommended tool is a metallic wool, like the [Hakko 599b](https://www.hakko.com/english/products/hakko_599b.html) or a cheap clone:

[Hakko 599b](https://www.hakko.com/english/images/products/products_hakko_599b_img.jpg){: .align-center}

Those cleaners are preferred other sponges, because the sponges will reduce the temperature of the iron tip when used, which means the tip will contract and expand. Frequent use of the sponge will cause metal fatigue and ulitmately failure. Metallic wool cleaners are very effective at removing the dirt, contaminet, and flux and solder residues.

The idea is to prevent oxidation, for this, clean the tip before using the soldering iron on a new component, not after. While the tip is not used between two components, the flux and solder will protect the tip from oxydation.

When you've finished the soldering job, clean the tip with the metallic wool and tin the tip. It is possible to buy a tip tinning box. Most large solder manufacturer produce this kind of product, mine is this reference:

[![MgChemicals tip tinning](/images/uploads/2020/10/tools-tip-tinner.jpg){: .align-center style="width: 90%"}](/images/uploads/2020/10/tools-tip-tinner.jpg)

You'll see recommandation of applying solder on the iron tip after use. This works fine if the solder contains a rosin activated flux (see below). But for no-clean solder (the majority of solder nowadays), the flux is not aggressive enough to remove or prevent tip oxydation. I recommend using a special tip tinner in such cases.

#### Solder

The solder is alloy that is melt to form the joint between the pad and the component. It is important to purchase a good quality solder. There are two types of solder, lead-free and containing lead. The former is better for health and environment, but might be harder to use because it requires a higher soldering temperature. The latter is easier to deal with, but is forbidden in EU because of [RoHS](https://en.wikipedia.org/wiki/Restriction_of_Hazardous_Substances_Directive) compliance.

Solder should also contain flux (even though as you'll see later, adding flux is necessary to properly solder SMD components). The flux purpose is to "clean" the surfaces so that the solder wet correctly and adheres to the pad and components.

Solder are described by their content, like for instance `Sn60Pb40` our `Sn63Pb37` or `Sn96.5Ag3Cu0.5`. It's simply their constituant and percentage. For instance `Sn63Pb37` is an alloy made of 63% of tin and 37% of lead. Unleaded solder is mostly made of tin and silver, and sometimes a low level of copper.

For beginners, I would recommend `Sn63Pb37` as it forms an [eutectic alloy](https://en.wikipedia.org/wiki/Eutectic_system). This means that the alloy has a melting point lower than the melting point of any of its constituent (or any other variation mix of tin and lead), and that it has a very short solidifying phase. This makes this kind of solder easy to work with.

Unleaded solder have a higher melting point (around 220ºC) that might take time to be accustomized to.

Well, that doesn't give you the temperature at which you'll have to solder the components. For SMD parts, with a leaded solder, I usually set my iron between 310º and 320ºC. This is high enough to quickly heat the pads. Lower temperature would mean to keep the iron tip longer on the pad and component with the risk of heating too much the component. Unlike what common thought, the heat conductivity of metal decreases with temperature, which means that using a lower temperature would mean more heat accumulating in the component (because of the iron tip staying longer on the pad and component).

For unleaded solder, a recommended iron temperature is around 350ºC. In fact it also depends on the iron tip used. Smaller iron tips have a lower heat transfer surface and thus, you will need to use a larger temperature and longer soldering to achieve the same effect as with a larger tip.

Using a solder containing rosin flux is also recommended. The metallic surfaces in contact with air will oxidize, preventing the chemical reaction that will bond them to the solder during the soldering. Oxidization happens all of the time. However, it happens faster at higher temperatures (as when soldering). The flux cleans metal surfaces and reacts with the oxide layer, leaving a surface primed for a good solder bond.

Flux remains on the surface of the metal while you're soldering, which prevents additional oxides from forming due to the high heat of the soldering process. As with solder, there are several types of flux, each with key uses and some limitations.

The most known one is Rosin (R), which is a compound which was made from pine trees, but is now synthetic. It's liquidifaction temperature is lower than the solder, so it flows first. It becomes acid when liquidified which allows its cleaning action before the solder melts to form the joint. The PCB needs to be cleaned after use with isopropyl alcohol (IPA).

Another big flux category is the no-clean flux (NC). No-clean flux residue don't need to be removed from the PCB. This flux should even be called "can't clean" instead of no-clean, because if you want to remove it from the PCB, it's very hard to do so and requires the proper solvent. The flux residues are usually transparent and non-conductive, so it's fine to leave them on the board. Most solder is nowadays sold with NC flux.

Another well-known category is Rosin Mildly Activated flux (RMA). RMA is a compound made of rosin, solvents and a small amount of activator. RMA flux is not very aggressive and should be used with easily solderable surfaces (so it works well for SMD). The clear residue is normally non-corrosive and nonconductive. It might not be necessary to clean it after work.

And finally we find the Rosin Activated category (RA). Activity is higher than RMA, and should be used on oxidized surfaces. It is corrosive so it should be cleaned as soon as possible after work (with the appropriate solvent). The RA category also contains water soluble versions that also are highly corrosive, but can be cleaned with water (also because it's conductive). Those are used to solder on difficult surfaces like stainless steel.

And I haven't yet finished to talk about solder. One need to choose the appropriate solder diameter. A good compromise for soldering a combination of SMD parts and through-hole components is 0.7 or 0.8mm.

Finally, several important warnings:

* Make sure to **wash your hands thoroughly** after soldering.
* Solder in a **ventilated room**, do **not inhale soldering smoke**, purchase a [fume absorber](https://www.hakko.com/english/products/hakko_fa400.html)
* avoid eating, drinking, smoking in solder areas to prevent solder particulates to enter your body

Among the various brands of solder, those are known to produce good solder: MgChemicals, Kester, Weller, Stannol, Multicore, MBO etc. For a thorough comparison of several brands and models, you can watch [SDG video: What's the best solder for electronics](https://youtu.be/zZ9wxs6xuYU)

#### Flux

The flux contained in the solder will not be enough to solder SMD parts. It is recommended to add extra flux prior to solder the components, especially for soldering IC or fine pitch components (see below for the techniques).

Flux exists in several forms:

Here's a flux pen:
[![Flux pen](/images/uploads/2020/10/flux-pen.jpg){: .align-center style="width: 90%"}](/images/uploads/2020/10/flux-pen.jpg)

And a flux serynge (ready to be used):
[![Flux serynge](/images/uploads/2020/10/flux-serynge.jpg){: .align-center style="width: 90%"}](/images/uploads/2020/10/flux-serynge.jpg)

A note on flux serynge: most of them are sold without an applying nozzle and a plunger. That's because professional are using a special dispensers. Do not forget to also purchase a plunger (they are dependent on the serynge volume) and nozzles. The nozzles are secured to the serynge by what is called a luer lock, which is a kind of threading inside the serynge.

[![Serynge, plunger and nozzles](/images/uploads/2020/10/flux-serynge-nozzles.jpg){: .align-center style="width: 90%"}](/images/uploads/2020/10/flux-serynge-nozzles.jpg)

I recommend getting a flux paste serynge, as the flux from the pen is more liquid and tends to dry much quickier than the paste.

For a comparison of fluxes, you can watch the [SDG video: what's the best flux for soldering](https://www.youtube.com/watch?v=iKDAmY9Rdag)

#### Desoldering tools

Mistakes happens :) so better be ready to deal with them. It might be necessary to remove extra solder or remove a component misplaced by mistake. Without investing a lot of money in a [desoldering iron or station](https://www.weller-tools.com/professional/USA/us/Professional/Soldering+technology/Soldering+irons/Desoldering+irons), it is possible to get inexpensive tools that will help.

Let me introduce you to the desoldering pump and its friend solder wick:

[![Desoldering tools](/images/uploads/2020/10/tools-desoldering.jpg){: .align-center style="width: 90%"}](/images/uploads/2020/10/tools-desoldering.jpg)

The top object in the picture is a desoldering pump. You arm it by pressing down the plunger, when released with the button, it will suck the melt solder. It is to be used with the soldering iron heating the excess solder, then quickly apply the pump.

The solder wick is to be placed on the excess solder, then the put the iron tip on top of it, the wick will also suck the melted solder.

#### Magnifying tools

Finally the last tools needed when soldering small SMD parts is a good lamp with an integrated magnifier. As seen earlier, most of the component are less than 3 or 2mm long, so it is hard to properly see them when soldering.

Of course getting a binocular or a microscope would be perfect, but those are quite expensive (especially if you want quality). Instead I think a good magnifying glass lamp can do the job quite efficiently. The best ones are the [Waldman Tevisio](https://waldmannlighting.com/products/tevisio), unfortunately they are quite expensive. It is possible to find cheaper alternatives on Amazon or one of the parts vendors I previously cited (I got myself this [RS Online model](https://uk.rs-online.com/web/p/magnifying-lamps/1363722/)).

The magnifying lens of such lamp is expressed in diopters. You can compute the magnifying ratio with the `D/4+1` formula. A 5d lens will provide a 2.25x magnification. This is enough to solder small parts, but my experience (and bad eyes) show that when there's a small defect its quite hard to have a good view of it (like when there's a small bridge on two close pins).

That's why I also recommend getting a standalone small jewelery 10x magnifying glass. The japaneese [Engineer SL-56](https://www.engineer.jp/en/products/sl55_57e.html) does an execellent work.

## Assembling the PCB

Enough about the tools, now let's see how to assemble the components on the PCB. First let me explain how to solder SMD parts. The technique is the same for 2 pads or multiple pads, except for fine pitch IC which will cover later.

I'm very sorry for the bad schemas that are appearing in the two next sections. I unfortunately don't have a macro lens for my camera, and my drawing skills are somewhat very low :)

### Soldering techniques

#### 2 pads component soldering technique


First apply a small amount of flux paste on both pads:

[![Adding flux on pads](/images/uploads/2020/10/solder-1-flux.png){: .align-center style="width: 50%"}](/images/uploads/2020/10/solder-1-flux.png)

Next, wet a small amount of solder on one of the pad with the soldering iron:

[![Adding a small amount of solder on pad](/images/uploads/2020/10/solder-2-solder-pad1.png){: .align-center style="width: 50%"}](/images/uploads/2020/10/solder-2-solder-pad1.png)

Then place the component with the tweezers, hold it firmly in place and reflow the solder on the pad until the joint is formed:

[![Soldering first pad](/images/uploads/2020/10/solder-3-solder-joint.png){: .align-center style="width: 50%"}](/images/uploads/2020/10/solder-3-solder-joint.png)

Once the solder has solidified, solder the other pad normally:

[![Soldering second pad](/images/uploads/2020/10/solder-4-solder-joint-pad2.png){: .align-center style="width: 50%"}](/images/uploads/2020/10/solder-4-solder-joint-pad2.png)

This very same technique can also be applied to 3 or 4 legged components. 

#### Drag soldering

The previous soldering technique doesn't work for fine pitched components like IC or the USB receptacle. For this we need a different technique: drag soldering.

The drag soldering technique consists in first soldering 2 opposite pads of an IC, then to drag the soldering iron tip and solder along the pins relatively quickly. The flux and soldermask will do their job and solder will flow only on the metal parts. Bridges can happen if there's too much solder or the iron tip is not moved quickly enough. That's where the solder wick is useful to remove the excess solder.

To properly drag solder, first add solders on two opposite pads of the IC. Then carefully place the IC with the tweezers, hold it firmly and reflow those two pads. When the solder solidifies and form a joint, the IC is now secured at the right place, and we can start drag soldering.

Here's a small schema illustrating the technique:

[![Drag soldering illustrated](/images/uploads/2020/10/drag-soldering.png){: .align-center style="width: 80%"}](/images/uploads/2020/10/drag-soldering.png)

You'll find the technique shown in this [drag soldering video](https://www.youtube.com/watch?v=nyele3CIs-U). Notice the tip shape used in the video (equivalent to a T12 BC), and how the solder is put below the tip. If you don't use a slanted tip, you can still put some solder on the iron, or use what I described above, preceding the iron tip with the solder.

### Soldering the PCB

So I'm ready to solder the PCB with the aforementioned techniques. Since it's harder to solder fine pitch components, it's better to start with them. There's nothing worst soldering every components, then failing soldering the IC.

My advice then is to start by soldering the USB connector first. Place it so that the small pins enter the board and solder on the front side. The USB connector is then now in place and the small pins are exactly placed on top of the pads on the back side of the PCB:

[![Soldering USB connector](/images/uploads/2020/10/soldering-usb-front.jpg){: .align-center style="width: 70%"}](/images/uploads/2020/10/soldering-usb-front.jpg)

Then apply some flux paste on the other side accross the pins:

[![Adding flux on the connector](/images/uploads/2020/10/soldering-usb-flux.jpg){: .align-center style="width: 50%"}](/images/uploads/2020/10/soldering-usb-flux.jpg)

And drag solder the connector. This will give this (flux have been removed in the following picture):

[![Drag soldered connector](/images/uploads/2020/10/soldering-usb-after.jpg){: .align-center style="width: 50%"}](/images/uploads/2020/10/soldering-usb-after.jpg)

Now is a good time to visually inspect there's no bridge. Then it might also be a good idea to use test that there's no `Vcc` and `GND` short with a multimeter. Put the multimeter in continuity testing, and put one of the probe on one of the `GND` pin and the other on one of the `Vcc` pin. There shouldn't be any continuity. If there's one, then that means there's a bridge that needs to be found and repaired by readding flux and using the iron tip or with solder wick. You can test the other pins, there shouldn't be any continuity except for pins that are dedoubled (`D+`/`D-`, `GND`, `Vcc`).

If everything is OK, the next important step is to solder the AtMega32U4 MCU. First make sure to check how it should be placed. The silkscreen printed at the back of the board contains a small artefact indicating where pin 1 is. On the chip, the pin 1 is the pin close to the small point.

To make sure I'm soldering the component at the right place, I can use the [Interactive HTML BOM plugin for Kicad](https://github.com/openscopeproject/InteractiveHtmlBom). In the Kicad PCB editor, the plugin can be launched with _Tools &rarr; External Plugins... &rarr; Generate Interactive HTML BOM_. In the _HTML Defaults_ section, it's a good idea to select _Highlight first pin_ and _Layer View &rarr; Back only_. After pressing _Generate BOM_, a web browser opens containing:

[![Interactive HTML BOM](/images/uploads/2020/10/kicad-interactive-bom.png){: .align-center style="width: 70%"}](/images/uploads/2020/10/kicad-interactive-bom.png)

Notice that I selected the MCU. I can then see where the first pin is, and how the MCU should be oriented.

So, I first add a bit of solder on pad 1 and another opposite pad:

[![Adding solder on some pads](/images/uploads/2020/10/soldering-mcu-step1.jpg){: .align-center style="width: 50%"}](/images/uploads/2020/10/soldering-mcu-step1.jpg)

Then I carefully place the MCU and reflow those pads to secure the MCU on the PCB (in the following picture it's not that well placed, but I didn't had a better picture):

[![Securing the MCU](/images/uploads/2020/10/soldering-mcu-step2.jpg){: .align-center style="width: 50%"}](/images/uploads/2020/10/soldering-mcu-step2.jpg)

The next step is to add flux on the pins:

[![Adding flux](/images/uploads/2020/10/soldering-mcu-step3.jpg){: .align-center style="width: 50%"}](/images/uploads/2020/10/soldering-mcu-step3.jpg)

And finally drag soldering (sorry I couldn't take a picture of this step, as I only have two hands).

The next critical components that needs to be soldered are the crystal oscillator and the PRTR5V0U2X which both have 4 pins. The technique is exactly the same as for soldering two pins component: first add solder on a pad, reflow while holding the component, then add solder to the other pads.










